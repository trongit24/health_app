import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/services/database_service.dart';
import '../../data/models/mood_model.dart';

/// A premium, highly interactive dashboard widget that displays:
/// 1. A smooth line chart of the user's mood trends over the last 7 days (using fl_chart).
/// 2. A beautiful feed of their past journal logs (with a dismissible swipe-to-delete interaction).
class MoodStatistics extends StatefulWidget {
  const MoodStatistics({super.key});

  @override
  State<MoodStatistics> createState() => _MoodStatisticsState();
}

class _MoodStatisticsState extends State<MoodStatistics> {
  final DatabaseService _databaseService = DatabaseService();

  // Color configurations for the chart line and fills
  final List<Color> _gradientColors = [
    Colors.deepPurple.shade400,
    Colors.indigo.shade300,
  ];

  // Map mood scores to their corresponding emojis for display
  final List<String> _moodEmojis = ['😢', '🙁', '😐', '🙂', '😀'];

  // Manual zero-dependency Date Formatters to ensure 100% compilation safety
  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _getWeekdayVN(DateTime dt) {
    switch (dt.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Calculates the HSL/Material color for the mood circle based on its score
  Color _getMoodColor(int score) {
    switch (score) {
      case 1:
        return Colors.blue.shade300;
      case 2:
        return Colors.cyan.shade300;
      case 3:
        return Colors.teal.shade300;
      case 4:
        return Colors.orange.shade300;
      case 5:
        return Colors.amber.shade400;
      default:
        return Colors.grey.shade300;
    }
  }

  /// Triggers deletion of a mood entry with safety UX alerts
  Future<void> _deleteEntry(String? id, BuildContext context) async {
    if (id == null) return;
    try {
      await _databaseService.deleteMood(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã xóa ghi chép tâm trạng.'),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa bản ghi: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MoodModel>>(
      stream: _databaseService.getMoodStream(),
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. Error State
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Đã có lỗi xảy ra khi tải dữ liệu',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snapshot.error.toString().replaceAll('DatabaseException: ', ''),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final logs = snapshot.data ?? [];

        // 3. Empty State (Therapeutic UX)
        if (logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.spa_outlined, size: 64, color: Colors.deepPurple.shade300),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Chưa có dữ liệu tâm trạng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy ghi lại cảm xúc đầu tiên của bạn hôm nay ở màn hình Thêm để bắt đầu biểu đồ phân tích!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Aggregate last 7 days chart data
        final chartPoints = _aggregateChartData(logs);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line Chart Container
            if (chartPoints.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Text(
                  'Diễn biến 7 ngày gần đây',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildChartCard(chartPoints),
              const SizedBox(height: 24),
            ],

            // Past Logs List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lịch sử nhật ký',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${logs.length} ghi chép',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. ListView of past logs
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildDismissibleLogCard(log, context);
              },
            ),
          ],
        );
      },
    );
  }

  /// Aggregates database logs into chronological points for the line chart (Max past 7 days)
  List<_ChartPoint> _aggregateChartData(List<MoodModel> logs) {
    final now = DateTime.now();
    final List<_ChartPoint> points = [];

    // Create representations for the past 7 days (including today)
    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      
      // Filter logs mapped to this specific calendar date
      final dailyLogs = logs.where((log) {
        return log.timestamp.year == targetDate.year &&
            log.timestamp.month == targetDate.month &&
            log.timestamp.day == targetDate.day;
      }).toList();

      if (dailyLogs.isNotEmpty) {
        // Calculate average score for the day
        final double avgScore = dailyLogs.map((e) => e.moodScore).reduce((a, b) => a + b) / dailyLogs.length;
        points.add(_ChartPoint(
          dateLabel: _formatDate(targetDate),
          weekdayLabel: _getWeekdayVN(targetDate),
          score: avgScore,
        ));
      }
    }

    return points;
  }

  /// Builds the Line Chart Card with rich visual gradients and emoji-labeled Y-axis
  Widget _buildChartCard(List<_ChartPoint> points) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(right: 22, left: 12, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade50.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade100,
                strokeWidth: 1,
              );
            },
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
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 32,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index >= 0 && index < points.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        points[index].weekdayLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
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
          maxX: points.length > 1 ? (points.length - 1).toDouble() : 1.0,
          minY: 1.0,
          maxY: 5.0,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.deepPurple.shade900.withValues(alpha: 0.9),
              tooltipRoundedRadius: 12,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final index = touchedSpot.x.toInt();
                  if (index < 0 || index >= points.length) return null;
                  
                  final pt = points[index];
                  final formattedScore = pt.score.toStringAsFixed(1);
                  return LineTooltipItem(
                    '${pt.dateLabel} (${pt.weekdayLabel})\nĐiểm: $formattedScore',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(points.length, (i) {
                return FlSpot(i.toDouble(), points[i].score);
              }),
              isCurved: true,
              gradient: LinearGradient(colors: _gradientColors),
              barWidth: 4.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final double score = spot.y;
                  final Color spotColor = _getMoodColor(score.round());
                  return FlDotCirclePainter(
                    radius: 5,
                    color: spotColor,
                    strokeColor: Colors.white,
                    strokeWidth: 2,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: _gradientColors.map((color) => color.withValues(alpha: 0.15)).toList(),
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a beautifully dismissible Card representing a single logged entry
  Widget _buildDismissibleLogCard(MoodModel log, BuildContext context) {
    return Dismissible(
      key: Key(log.id ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog before deleting
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xóa nhật ký?'),
            content: const Text('Hành động này sẽ xóa vĩnh viễn ghi chép cảm xúc này của bạn trên hệ thống Cloud.'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Hủy bỏ', style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Xóa ngay', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteEntry(log.id, context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Circular Emoji Badge with HSL mood color
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getMoodColor(log.moodScore).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _moodEmojis[log.moodScore - 1],
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: 16),

              // Middle & Right: Content fields
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time and Date header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatTime(log.timestamp)} - ${_getWeekdayVN(log.timestamp)} (${_formatDate(log.timestamp)})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        // Small Delete trigger icon
                        GestureDetector(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Xóa nhật ký?'),
                                content: const Text('Hành động này sẽ xóa vĩnh viễn ghi chép cảm xúc này trên hệ thống Cloud.'),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text('Hủy bỏ', style: TextStyle(color: Colors.grey.shade600)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Xóa', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              _deleteEntry(log.id, context);
                            }
                          },
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Note text (if available)
                    if (log.note != null && log.note!.isNotEmpty) ...[
                      Text(
                        log.note!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      Text(
                        'Không có ghi chú thêm.',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Tags flow inside Card
                    if (log.tags.isNotEmpty)
                      Wrap(
                        spacing: 6.0,
                        runSpacing: 4.0,
                        children: log.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.deepPurple.shade400,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper model for grouping and sorting chart coordinates
class _ChartPoint {
  final String dateLabel;
  final String weekdayLabel;
  final double score;

  _ChartPoint({
    required this.dateLabel,
    required this.weekdayLabel,
    required this.score,
  });
}
