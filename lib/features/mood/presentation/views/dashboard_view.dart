import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/soul_flow_theme.dart';
import '../../../../core/services/mood_manager.dart';
import '../../../../core/services/localizations.dart';
import '../../../../core/services/room_service.dart';
import '../../../../core/services/tags_data.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../data/models/mood_model.dart';
import 'add_mood_screen.dart';
import 'coping_space_view.dart';

const Color _emeraldColor = Color(0xFF10B981);

class DashboardView extends StatefulWidget {
  final Function(int) onTabChange;
  final VoidCallback onOpenJournalForm;

  const DashboardView({
    super.key,
    required this.onTabChange,
    required this.onOpenJournalForm,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final MoodManager _moodManager = MoodManager();
  int _selectedEmojiIndex = -1;

  final List<String> _moodEmojis = ['😢', '🙁', '😐', '🙂', '😀'];

  int _calculateStreakDays(List<MoodModel> logs, bool isHappy) {
    if (logs.isEmpty) return 0;

    final Map<String, List<int>> dailyScores = {};
    for (var log in logs) {
      final dateStr = "${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}";
      dailyScores.putIfAbsent(dateStr, () => []).add(log.moodScore);
    }

    final sortedDates = dailyScores.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) return 0;

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    if (sortedDates.first != todayStr && sortedDates.first != yesterdayStr) {
      return 0;
    }

    int streak = 0;
    DateTime currentCheckDate = DateTime.parse(sortedDates.first);

    for (int i = 0; i < 30; i++) {
      final checkStr = "${currentCheckDate.year}-${currentCheckDate.month.toString().padLeft(2, '0')}-${currentCheckDate.day.toString().padLeft(2, '0')}";
      if (dailyScores.containsKey(checkStr)) {
        final scores = dailyScores[checkStr]!;
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        final isMatch = isHappy ? (avg >= 4.0) : (avg <= 2.0);
        if (isMatch) {
          streak++;
        } else {
          break;
        }
      } else {
        break;
      }
      currentCheckDate = currentCheckDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  List<MoodModel> _getStreakLogs(List<MoodModel> logs, int streakDays) {
    if (logs.isEmpty || streakDays <= 0) return [];
    
    final sortedLogs = List<MoodModel>.from(logs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
    final Map<String, List<MoodModel>> dailyLogs = {};
    for (var log in sortedLogs) {
      final dateStr = "${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}";
      dailyLogs.putIfAbsent(dateStr, () => []).add(log);
    }
    
    final sortedDates = dailyLogs.keys.toList()
      ..sort((a, b) => b.compareTo(a));
      
    final List<MoodModel> streakLogsList = [];
    final limit = (streakDays < sortedDates.length) ? streakDays : sortedDates.length;
    for (int i = 0; i < limit; i++) {
      final dateStr = sortedDates[i];
      if (dailyLogs.containsKey(dateStr)) {
        streakLogsList.addAll(dailyLogs[dateStr]!);
      }
    }
    return streakLogsList;
  }

  void _showCertificateDialog(BuildContext context, int streakDays, String displayName, AppLocalizations localizations, bool isDark) {
    final reasonController = TextEditingController();
    final isWeek = streakDays >= 7;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? SoulFlowTheme.surfaceCardDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isWeek ? 'Phiếu Vàng Thành Tựu 1 Tuần' : localizations.translate('achievement_title'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Certificate UI
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2F29) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _emeraldColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(isWeek ? '🏆 🌟 🏆' : '🏆 ✨ 🏆', style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 8),
                      Text(
                        isWeek ? 'Tuần Lễ Vui Tươi Rực Rỡ' : localizations.translate('achievement_subtitle'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _emeraldColor),
                      ),
                      const Divider(color: _emeraldColor, height: 16, thickness: 0.5),
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isWeek
                            ? 'đã xuất sắc duy trì tinh thần vui tươi kỳ diệu suốt 1 tuần!'
                            : 'đã xuất sắc duy trì tinh thần vui tươi rực rỡ!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: SoulFlowTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: localizations.translate('achievement_reason_hint'),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(localizations.translate('close'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SoulFlowTheme.primarySage,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final reason = reasonController.text.trim();
                final roomCode = await RoomService().getActiveRoomCode();
                
                if (roomCode == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bạn chưa tham gia phòng nhóm nào. Hãy qua tab Chia sẻ để tham gia nhé!')),
                    );
                  }
                  return;
                }
                
                final formattedDate = '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
                await RoomService().sendMessage(
                  roomCode,
                  isWeek
                      ? 'Đã chia sẻ Phiếu Vàng Thành Tựu 1 Tuần: ${reason.isNotEmpty ? reason : "Tuần lễ vui tươi"}'
                      : 'Đã chia sẻ Phiếu Thành Tựu Cảm Xúc: ${reason.isNotEmpty ? reason : "Tâm hồn rực rỡ"}',
                  achievementData: {
                    'title': isWeek ? 'Tuần Lễ Vui Tươi Rực Rỡ 🌟' : 'Chuỗi Ngày Tươi Sáng',
                    'reason': reason.isNotEmpty ? reason : (isWeek ? 'Tinh thần lạc quan vui vẻ kỳ diệu suốt 1 tuần' : 'Tinh thần lạc quan vui vẻ'),
                    'date': formattedDate,
                  },
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã chia sẻ phiếu thành tựu vào phòng nhóm của bạn! 🏆')),
                  );
                }
              },
              child: Text(
                localizations.translate('achievement_share_btn'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    // Get display name
    final String displayName = authProvider.user?.displayName ?? 
        (authProvider.isAnonymous ? localizations.translate('peaceful_soul') : localizations.translate('peaceful_soul'));

    return StreamBuilder<List<MoodModel>>(
      stream: _moodManager.moodStream,
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        
        // Analyze streaks based on consecutive days (3 days or 7 days/1 week)
        Widget? streakInsightCard;
        final happyStreak = _calculateStreakDays(logs, true);
        final sadStreak = _calculateStreakDays(logs, false);

        if (sadStreak >= 3) {
          final streakLogs = _getStreakLogs(logs, sadStreak);
          streakInsightCard = _buildSadStreakCard(sadStreak, streakLogs, localizations, isDark);
        } else if (happyStreak >= 3) {
          streakInsightCard = _buildHappyStreakCard(happyStreak, displayName, localizations, isDark);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('good_morning'),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : SoulFlowTheme.textMuted,
                        ),
                      ),
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: SoulFlowTheme.primarySage,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: SoulFlowTheme.primarySage, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: SoulFlowTheme.accentGlow,
                      child: Text(
                        '🧘',
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Conditionally display dynamic streak card
              if (streakInsightCard != null) ...[
                streakInsightCard,
                const SizedBox(height: 24),
              ],

              // Mood Selector Card
              _buildMoodSelectorCard(localizations, isDark),
              const SizedBox(height: 24),

              // Weekly trends chart
              _buildWeeklyChartSection(logs, localizations, isDark),
              const SizedBox(height: 24),

              // Quick Access links
              Text(
                localizations.translate('quick_therapy'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : SoulFlowTheme.textCharcoal,
                    ),
              ),
              const SizedBox(height: 12),
              _buildQuickActionCards(context, localizations, isDark),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSadStreakCard(int streakDays, List<MoodModel> streakLogs, AppLocalizations localizations, bool isDark) {
    final Set<String> sadTags = {};
    for (var log in streakLogs) {
      sadTags.addAll(log.tags);
    }
    
    final List<String> translatedTags = [];
    for (var tag in sadTags) {
      final match = TagsData.allTags.firstWhere(
        (element) => element['label'] == tag,
        orElse: () => {},
      );
      if (match.containsKey('key')) {
        final emoji = match['emoji'] ?? '';
        final name = localizations.translate(match['key']!);
        translatedTags.add('$emoji $name');
      } else {
        translatedTags.add(tag);
      }
    }

    final tagsString = translatedTags.isNotEmpty ? translatedTags.join(', ') : 'Chưa chọn cảm xúc con';
    final isWeek = streakDays >= 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF38231C) : const Color(0xFFFFF5F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SoulFlowTheme.accentCoral.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌧️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                isWeek ? 'Chuỗi 1 Tuần Trầm Lắng 🌧️' : 'Chuỗi 3 Ngày Trầm Lắng 🌧️',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: SoulFlowTheme.accentCoral),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isWeek
                ? 'Hệ thống nhận diện bạn đã có 7 ngày liên tiếp (1 tuần) với tâm trạng trầm lắng. Hãy dành thời gian nghỉ ngơi sâu sắc và chia sẻ tâm sự nhé.'
                : 'Bạn đã trải qua 3 ngày liên tiếp với tâm trạng hơi trầm lắng. Dưới đây là phân tích các tác nhân gây ra tình trạng này.',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : SoulFlowTheme.textCharcoal, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF231410) : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${localizations.translate('trigger_analysis_title')}:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: SoulFlowTheme.accentCoral),
                ),
                const SizedBox(height: 6),
                Text(
                  tagsString,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  isWeek
                      ? '💡 Lời khuyên thiết thực 1 Tuần: Tình trạng trầm lắng kéo dài 1 tuần có thể ảnh hưởng lớn đến bạn. Hãy tạm ngắt kết nối công việc, đi dạo nhẹ nhàng dưới ánh nắng và nhắn tin chia sẻ với bạn bè/người thân trong phòng chat nhé.'
                      : '💡 Lời khuyên thiết thực: Phân tích chỉ ra tâm trạng trầm lặng đi kèm với các trạng thái trên. Hãy cho phép bản thân nghỉ ngơi, đi ngủ sớm và uống nhiều nước ấm ngày hôm nay nhé.',
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: SoulFlowTheme.textMuted, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHappyStreakCard(int streakDays, String displayName, AppLocalizations localizations, bool isDark) {
    final isWeek = streakDays >= 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2F29) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _emeraldColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('☀️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                isWeek ? 'Tuần Lễ Vui Vẻ Kỳ Diệu 🌟' : 'Chuỗi 3 Ngày Vui Vẻ ☀️',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _emeraldColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isWeek
                ? 'Thật tuyệt vời! Bạn đã duy trì được năng lượng tích cực trong suốt 7 ngày qua (1 tuần). Hãy nhận Phiếu Thành Tựu Vàng 1 Tuần để chia sẻ niềm vui này nhé!'
                : 'Bạn đã duy trì được năng lượng tích cực trong 3 ngày qua! Hãy nhận phiếu thành tựu nhé.',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : SoulFlowTheme.textCharcoal, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _emeraldColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () => _showCertificateDialog(context, streakDays, displayName, localizations, isDark),
              icon: const Icon(Icons.workspace_premium, size: 20),
              label: Text(
                isWeek ? 'Nhận Phiếu Vàng 1 Tuần' : 'Nhận Phiếu Thành Tựu',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelectorCard(AppLocalizations localizations, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? SoulFlowTheme.surfaceCardDark : SoulFlowTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : SoulFlowTheme.accentGlow, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('how_feel_today'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (index) {
                final isSelected = _selectedEmojiIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmojiIndex = index;
                    });
                    // Open logging screen directly
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddMoodScreen(),
                      ),
                    );
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        setState(() {
                          _selectedEmojiIndex = -1;
                        });
                      }
                    });
                  },
                  child: AnimatedScale(
                    scale: isSelected ? 1.3 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? SoulFlowTheme.primarySage.withValues(alpha: 0.1)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? SoulFlowTheme.primarySage
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _moodEmojis[index],
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(localizations.translate('mood_very_sad'), style: const TextStyle(fontSize: 11, color: SoulFlowTheme.textMuted)),
                Text(localizations.translate('mood_very_happy'), style: const TextStyle(fontSize: 11, color: SoulFlowTheme.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChartSection(List<MoodModel> logs, AppLocalizations localizations, bool isDark) {
    final chartPoints = _get7DaysPoints(logs, localizations);

    return Card(
      elevation: 0,
      color: isDark ? SoulFlowTheme.surfaceCardDark : SoulFlowTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : SoulFlowTheme.accentGlow, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 22, left: 12, top: 24, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10.0, bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('streak'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Biểu đồ biến động tâm trạng của bạn trong tuần qua.',
                    style: TextStyle(fontSize: 12, color: SoulFlowTheme.textMuted),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: chartPoints.isEmpty
                  ? Center(
                      child: Text(
                        localizations.translate('no_journal_yet'),
                        style: const TextStyle(color: SoulFlowTheme.textMuted),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final int index = value.toInt() - 1;
                                if (index >= 0 && index < 5) {
                                  return Text(
                                    _moodEmojis[index],
                                    style: const TextStyle(fontSize: 16),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              reservedSize: 28,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final int index = value.toInt();
                                if (index >= 0 && index < chartPoints.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      chartPoints[index].label,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: SoulFlowTheme.textMuted,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: chartPoints.length > 1 ? (chartPoints.length - 1).toDouble() : 1.0,
                        minY: 1.0,
                        maxY: 5.0,
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(chartPoints.length, (i) {
                              return FlSpot(i.toDouble(), chartPoints[i].score);
                            }),
                            isCurved: true,
                            barWidth: 4,
                            color: SoulFlowTheme.primarySage,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: SoulFlowTheme.accentCoral,
                                  strokeColor: Colors.white,
                                  strokeWidth: 2,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: SoulFlowTheme.primarySage.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ChartPointHelper> _get7DaysPoints(List<MoodModel> logs, AppLocalizations localizations) {
    final now = DateTime.now();
    final List<_ChartPointHelper> points = [];

    final isEn = localizations.locale.languageCode == 'en';
    final weekdays = isEn 
        ? ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        : ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final dailyLogs = logs.where((log) {
        return log.timestamp.year == targetDate.year &&
            log.timestamp.month == targetDate.month &&
            log.timestamp.day == targetDate.day;
      }).toList();

      if (dailyLogs.isNotEmpty) {
        final double avg = dailyLogs.map((e) => e.moodScore).reduce((a, b) => a + b) / dailyLogs.length;
        points.add(_ChartPointHelper(
          label: weekdays[targetDate.weekday % 7],
          score: avg,
        ));
      } else {
        points.add(_ChartPointHelper(
          label: weekdays[targetDate.weekday % 7],
          score: 3.0,
        ));
      }
    }
    return points;
  }

  Widget _buildQuickActionCards(BuildContext context, AppLocalizations localizations, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionCard(
              title: localizations.translate('add_mood_title'),
              subtitle: 'Ghi chép cảm xúc ngay',
              emoji: '✍️',
              color: isDark ? const Color(0xFF38231C) : const Color(0xFFF7ECE8),
              width: width,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddMoodScreen()),
                );
              },
            ),
            _buildActionCard(
              title: localizations.translate('journal'),
              subtitle: 'Xem lại lịch sử ghi chép',
              emoji: '📖',
              color: isDark ? const Color(0xFF1E2F29) : SoulFlowTheme.accentGlow,
              width: width,
              onTap: () => widget.onTabChange(1),
            ),
            _buildActionCard(
              title: localizations.translate('sharing_room'),
              subtitle: 'Trò chuyện cùng bạn bè',
              emoji: '💬',
              color: isDark ? const Color(0xFF22362C) : const Color(0xFFEFF5F2),
              width: width,
              onTap: () => widget.onTabChange(2),
            ),
            _buildActionCard(
              title: localizations.translate('profile'),
              subtitle: 'Xem biểu đồ & cá nhân',
              emoji: '📈',
              color: isDark ? const Color(0xFF1B263B) : const Color(0xFFECEFF7),
              width: width,
              onTap: () => widget.onTabChange(3),
            ),
            _buildActionCard(
              title: localizations.translate('coping_space'),
              subtitle: localizations.translate('coping_space_sub'),
              emoji: '🧘',
              color: isDark ? const Color(0xFF2C3E35) : const Color(0xFFE8F5E9),
              width: constraints.maxWidth,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CopingSpaceView()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required String emoji,
    required Color color,
    required double width,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: SoulFlowTheme.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartPointHelper {
  final String label;
  final double score;

  _ChartPointHelper({required this.label, required this.score});
}
