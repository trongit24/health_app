import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/soul_flow_theme.dart';
import '../../../../core/services/localizations.dart';
import '../../../../core/services/room_service.dart';

const Color _emeraldColor = Color(0xFF10B981);
const Color _emerald200 = Color(0xFFA7F3D0);
const Color _emerald800 = Color(0xFF065F46);

class RoomView extends StatefulWidget {
  const RoomView({super.key});

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> {
  final RoomService _roomService = RoomService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final TextEditingController _createNameController = TextEditingController();
  final TextEditingController _joinCodeController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  String? _activeRoomCode;
  bool _isLoading = true;
  String _currentUserName = 'Thành viên';

  @override
  void initState() {
    super.initState();
    _checkActiveRoom();
    _loadCurrentUserName();
  }

  Future<void> _checkActiveRoom() async {
    setState(() => _isLoading = true);
    final code = await _roomService.getActiveRoomCode();
    setState(() {
      _activeRoomCode = code;
      _isLoading = false;
    });
  }

  Future<void> _loadCurrentUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserName = user.displayName ?? (user.isAnonymous ? 'Ẩn danh' : 'Thành viên');
      });
    }
  }

  @override
  void dispose() {
    _createNameController.dispose();
    _joinCodeController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onCreateRoom() async {
    final name = _createNameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final code = await _roomService.createRoom(name, _currentUserName);
      setState(() {
        _activeRoomCode = code;
        _isLoading = false;
      });
      _createNameController.clear();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(e.toString());
    }
  }

  Future<void> _onJoinRoom() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _roomService.joinRoom(code, _currentUserName);
      setState(() {
        _activeRoomCode = code;
        _isLoading = false;
      });
      _joinCodeController.clear();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(e.toString());
    }
  }

  Future<void> _onLeaveRoom() async {
    if (_activeRoomCode == null) return;
    
    setState(() => _isLoading = true);
    try {
      await _roomService.leaveRoom(_activeRoomCode!);
      setState(() {
        _activeRoomCode = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(e.toString());
    }
  }

  Future<void> _onSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeRoomCode == null) return;

    _messageController.clear();
    try {
      await _roomService.sendMessage(_activeRoomCode!, text);
      _scrollToBottom();
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeRoomCode == null) {
      return _buildJoinCreateScreen(localizations, isDark);
    }

    return _buildActiveRoomScreen(localizations, isDark);
  }

  Widget _buildJoinCreateScreen(AppLocalizations localizations, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                const Text(
                  '💬',
                  style: TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 12),
                Text(
                  localizations.translate('sharing_room'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SoulFlowTheme.primarySage,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tạo phòng nhóm hoặc tham gia cùng bạn bè để chia sẻ cảm xúc và thành tựu cảm xúc rực rỡ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SoulFlowTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Join Room Card
          _buildActionCard(
            title: localizations.translate('join_room'),
            child: Column(
              children: [
                TextField(
                  controller: _joinCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: localizations.translate('enter_room_code'),
                    prefixIcon: const Icon(Icons.qr_code, color: SoulFlowTheme.primarySage),
                    filled: true,
                    fillColor: isDark ? SoulFlowTheme.surfaceCardDark : const Color(0xFFF7F9F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SoulFlowTheme.primarySage,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _onJoinRoom,
                    child: Text(
                      localizations.translate('join_room'),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          // Create Room Card
          _buildActionCard(
            title: localizations.translate('create_room'),
            child: Column(
              children: [
                TextField(
                  controller: _createNameController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên phòng nhóm (Ví dụ: Nhóm Chữa Lành)...',
                    prefixIcon: const Icon(Icons.group_outlined, color: SoulFlowTheme.primarySage),
                    filled: true,
                    fillColor: isDark ? SoulFlowTheme.surfaceCardDark : const Color(0xFFF7F9F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: SoulFlowTheme.primarySage, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _onCreateRoom,
                    child: Text(
                      localizations.translate('create_room'),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: SoulFlowTheme.primarySage),
                    ),
                  ),
                ),
              ],
            ),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({required String title, required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? SoulFlowTheme.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : SoulFlowTheme.accentGlow, width: 1),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey.shade100).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SoulFlowTheme.primarySage),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildActiveRoomScreen(AppLocalizations localizations, bool isDark) {
    final currentUid = _auth.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _roomService.getRoomStream(_activeRoomCode!),
      builder: (context, roomSnap) {
        if (!roomSnap.hasData || !roomSnap.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final roomData = roomSnap.data!.data()!;
        final roomName = roomData['name'] ?? 'Phòng trò chuyện';
        final members = List<String>.from(roomData['members'] ?? []);

        return Column(
          children: [
            // Active Room Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? SoulFlowTheme.surfaceCardDark : Colors.white,
                border: Border(bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : SoulFlowTheme.accentGlow)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: SoulFlowTheme.accentGlow,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('💬', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roomName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: _activeRoomCode!));
                                _showSnackBar('Đã sao chép mã phòng: $_activeRoomCode');
                              },
                              child: Text(
                                'Mã: $_activeRoomCode 📋',
                                style: const TextStyle(fontSize: 12, color: SoulFlowTheme.primarySage, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${members.length} ${localizations.translate('members_count')}',
                              style: const TextStyle(fontSize: 12, color: SoulFlowTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: SoulFlowTheme.accentCoral),
                    tooltip: localizations.translate('leave_room'),
                    onPressed: _onLeaveRoom,
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _roomService.getMessagesStream(_activeRoomCode!),
                builder: (context, messageSnap) {
                  if (!messageSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = messageSnap.data!.docs;
                  
                  // Scroll to bottom whenever new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('🌸', style: TextStyle(fontSize: 32)),
                          SizedBox(height: 8),
                          Text(
                            'Chưa có tin nhắn nào. Hãy gửi lời chào nhé!',
                            style: TextStyle(color: SoulFlowTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final senderId = data['senderId'] as String;
                      final senderName = data['senderName'] as String? ?? 'Thành viên';
                      final text = data['text'] as String;
                      final type = data['type'] as String? ?? 'text';
                      final isMe = senderId == currentUid;

                      if (type == 'achievement') {
                        final ach = data['achievementData'] as Map<String, dynamic>? ?? {};
                        return _buildAchievementMessage(senderName, ach, isMe, isDark);
                      }

                      return _buildTextMessage(senderName, text, isMe, isDark);
                    },
                  );
                },
              ),
            ),

            // Message Input Area
            Container(
              padding: const EdgeInsets.all(12).copyWith(
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: isDark ? SoulFlowTheme.surfaceCardDark : Colors.white,
                border: Border(top: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : SoulFlowTheme.accentGlow)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _onSendMessage(),
                      decoration: InputDecoration(
                        hintText: localizations.translate('chat_hint'),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF161C19) : const Color(0xFFF7F9F8),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: SoulFlowTheme.primarySage,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _onSendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextMessage(String senderName, String text, bool isMe, bool isDark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                senderName,
                style: const TextStyle(fontSize: 10, color: SoulFlowTheme.textMuted, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? SoulFlowTheme.primarySage
                    : (isDark ? const Color(0xFF26322C) : SoulFlowTheme.accentGlow),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isMe ? const Radius.circular(0) : null,
                  bottomLeft: !isMe ? const Radius.circular(0) : null,
                ),
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : (isDark ? Colors.white : SoulFlowTheme.textCharcoal),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementMessage(String senderName, Map<String, dynamic> ach, bool isMe, bool isDark) {
    final title = ach['title'] as String? ?? 'Chuỗi Ngày Tươi Sáng';
    final reason = ach['reason'] as String? ?? '';
    final dateStr = ach['date'] as String? ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: MediaQuery.of(context).size.width * 0.75,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2F29) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _emeraldColor.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: _emeraldColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 24)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _emeraldColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Text('✨', style: TextStyle(fontSize: 16)),
                ],
              ),
              const Divider(color: _emeraldColor, height: 16, thickness: 0.5),
              
              // Certificate Body
              Center(
                child: Column(
                  children: [
                    const Text(
                      'PHIẾU THÀNH TỰU CẢM XÚC',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: SoulFlowTheme.primarySage),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : SoulFlowTheme.textCharcoal,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'đã xuất sắc duy trì tinh thần vui tươi rực rỡ!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: SoulFlowTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Reason
              if (reason.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF162520) : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lý do: $reason',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? _emerald200 : _emerald800,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              
              // Date tag
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  dateStr,
                  style: const TextStyle(fontSize: 9, color: SoulFlowTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
