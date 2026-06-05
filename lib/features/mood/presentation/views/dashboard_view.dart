import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/soul_flow_theme.dart';
import '../../../../core/services/mood_manager.dart';
import '../../../../core/services/localizations.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../data/models/mood_model.dart';
import 'add_mood_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    // Get display name or a fallback
    final String displayName = authProvider.user?.displayName ?? 
        (authProvider.isAnonymous ? localizations.translate('peaceful_soul') : localizations.translate('peaceful_soul'));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Profile Avatar Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('good_morning'),
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey.shade400 : SoulFlowTheme.textMuted,
                    ),
                  ),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 26,
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
                  radius: 26,
                  backgroundColor: SoulFlowTheme.accentGlow,
                  child: Text(
                    '🧘',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Mood Selector Card
          _buildMoodSelectorCard(localizations, isDark),
          const SizedBox(height: 28),

          // Mood Trends Weekly Chart Card
          _buildWeeklyChartSection(localizations, isDark),
          const SizedBox(height: 28),

          // Quick Action Cards Section
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
                    // Open logging screen directly with prefilled details
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddMoodScreen(),
                      ),
                    );
                    // Reset selected local state
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

  Widget _buildWeeklyChartSection(AppLocalizations localizations, bool isDark) {
    return StreamBuilder<List<MoodModel>>(
      stream: _moodManager.moodStream,
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
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
                      Text(
                        localizations.translate('zen_space_sub'), // or a subtitle key
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
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
      },
    );
  }

  List<_ChartPointHelper> _get7DaysPoints(List<MoodModel> logs, AppLocalizations localizations) {
    final now = DateTime.now();
    final List<_ChartPointHelper> points = [];

    // Weekday abbreviations
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
          score: 3.0, // default neutral value
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
              title: localizations.translate('inhale'),
              subtitle: '4s Inhale - 4s Exhale',
              emoji: '🧘',
              color: isDark ? const Color(0xFF1E2F29) : SoulFlowTheme.accentGlow,
              width: width,
              onTap: () => widget.onTabChange(2),
            ),
            _buildActionCard(
              title: localizations.translate('add_mood_title'),
              subtitle: localizations.translate('spend_time_to_understand'),
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
              title: localizations.translate('ambient_sound'),
              subtitle: localizations.translate('playing'),
              emoji: '🍃',
              color: isDark ? const Color(0xFF22362C) : const Color(0xFFEFF5F2),
              width: width,
              onTap: () => widget.onTabChange(2),
            ),
            _buildActionCard(
              title: localizations.translate('healing_achievements'),
              subtitle: localizations.translate('total_checkins'),
              emoji: '📈',
              color: isDark ? const Color(0xFF1B263B) : const Color(0xFFECEFF7),
              width: width,
              onTap: () => widget.onTabChange(3),
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
