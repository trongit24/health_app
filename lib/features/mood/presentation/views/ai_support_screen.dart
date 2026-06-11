import 'package:flutter/material.dart';
import '../../../../core/theme/soul_flow_theme.dart';
import '../../../../core/services/ai_service.dart';

class AiSupportScreen extends StatefulWidget {
  const AiSupportScreen({super.key});

  @override
  State<AiSupportScreen> createState() => _AiSupportScreenState();
}

class _Message {
  final String text;
  final bool isUser;
  _Message(this.text, this.isUser);
}

class _AiSupportScreenState extends State<AiSupportScreen> {
  final AiService _aiService = AiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = [
    _Message(
      'Chào bạn! Mình là trợ lý AI của SoulFlow 🌿\n\nBạn có thể chia sẻ nhật ký, cảm xúc hôm nay hoặc bất cứ điều gì bạn đang nghĩ. Mình ở đây để lắng nghe và chia sẻ cùng bạn.\n\n💡 Nếu đây là lần đầu, hãy nhấn ⚙️ ở góc trên phải để nhập API Key nhé!',
      false,
    ),
  ];
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAi();
  }

  Future<void> _initializeAi() async {
    await _aiService.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Ẩn bàn phím để xem rõ tin nhắn
    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add(_Message(text, true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.getAdvice(text);

      if (!mounted) return;
      setState(() {
        _messages.add(_Message(response, false));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_Message(
          '❌ Lỗi không mong muốn: ${e.toString()}\nVui lòng thử lại.',
          false,
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _showApiKeyDialog() {
    final keyController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isTesting = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Cài đặt API Key'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhập Google Gemini API Key của bạn.\nKey chỉ được lưu cục bộ trên máy, hoàn toàn an toàn.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: keyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'AIzaSy...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (isTesting) ...[
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Đang kiểm tra kết nối...', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isTesting
                      ? null
                      : () async {
                          final key = keyController.text.trim();
                          if (key.isEmpty) return;

                          setDialogState(() => isTesting = true);

                          // Lưu key
                          await _aiService.updateApiKey(key);

                          // Test kết nối
                          final error = await _aiService.testConnection();

                          if (!mounted) return;

                          if (error == null) {
                            // Thành công!
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Kết nối AI thành công! Bạn có thể trò chuyện ngay.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            setState(() {
                              _messages.add(_Message(
                                '✅ API Key đã được lưu và kết nối thành công! Bạn hãy chia sẻ cảm xúc hôm nay nhé 😊',
                                false,
                              ));
                            });
                            _scrollToBottom();
                          } else {
                            // Thất bại
                            setDialogState(() => isTesting = false);
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('❌ $error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: const Text('Lưu & Kiểm tra'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 20),
            const SizedBox(width: 8),
            const Text('SoulFlow AI'),
            const SizedBox(width: 8),
            // Hiển thị trạng thái kết nối
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _aiService.isReady ? Colors.green : Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showApiKeyDialog,
            tooltip: 'Cài đặt API Key',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('AI đang suy nghĩ...'),
                ],
              ),
            ),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_Message msg, bool isDark) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isUser
              ? SoulFlowTheme.primarySage
              : (isDark ? SoulFlowTheme.surfaceCardDark : Colors.white),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: msg.isUser ? const Radius.circular(0) : null,
            bottomLeft: !msg.isUser ? const Radius.circular(0) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser
                ? Colors.white
                : (isDark
                    ? SoulFlowTheme.textLight
                    : SoulFlowTheme.textCharcoal),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark
            ? SoulFlowTheme.backgroundDark
            : SoulFlowTheme.backgroundCream,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Nhập chia sẻ của bạn...',
                filled: true,
                fillColor: isDark
                    ? SoulFlowTheme.surfaceCardDark
                    : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: SoulFlowTheme.primarySage,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
