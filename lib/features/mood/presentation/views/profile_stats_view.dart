import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/soul_flow_theme.dart';
import '../../../../core/services/mood_manager.dart';
import '../../../../core/services/localizations.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../features/auth/presentation/views/login_screen.dart';
import '../../data/models/mood_model.dart';

class ProfileStatsView extends StatefulWidget {
  const ProfileStatsView({super.key});

  @override
  State<ProfileStatsView> createState() => _ProfileStatsViewState();
}

class _ProfileStatsViewState extends State<ProfileStatsView> {
  final MoodManager _moodManager = MoodManager();
  bool _notificationsEnabled = true;

  final List<String> _moodEmojis = ['😢', '🙁', '😐', '🙂', '😀'];

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('daily_notification_enabled') ?? true;
    });
  }

  Future<void> _toggleNotificationSetting(bool val) async {
    setState(() {
      _notificationsEnabled = val;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_notification_enabled', val);

    if (val) {
      final granted = await NotificationService().requestPermissions();
      if (granted) {
        await NotificationService().scheduleDailyReminder();
      } else {
        setState(() {
          _notificationsEnabled = false;
        });
        await prefs.setBool('daily_notification_enabled', false);
      }
    } else {
      await NotificationService().cancelDailyReminder();
    }
  }

  void _exportLogs(List<MoodModel> logs) async {
    final localizations = AppLocalizations.of(context);
    try {
      final jsonList = logs.map((log) {
        final map = log.toFirestore();
        map['id'] = log.id;
        map['timestamp'] = log.timestamp.millisecondsSinceEpoch;
        return map;
      }).toList();

      final jsonString = jsonEncode(jsonList);
      await Clipboard.setData(ClipboardData(text: jsonString));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('export_success')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Export failed: $e');
    }
  }

  void _showImportDialog() {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.translate('import_data')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                maxLines: 6,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Paste backup JSON string here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.translate('close'), style: const TextStyle(color: SoulFlowTheme.textMuted)),
            ),
            TextButton(
              onPressed: () async {
                final pastedText = textController.text.trim();
                if (pastedText.isEmpty) return;

                try {
                  final List<dynamic> jsonList = jsonDecode(pastedText);
                  final List<MoodModel> imported = jsonList.map((item) {
                    final map = item as Map<String, dynamic>;
                    return MoodModel.fromMap(map, docId: map['id'] as String?);
                  }).toList();

                  await _moodManager.importLogs(imported);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.translate('import_success')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.translate('import_failed')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Text(localizations.translate('import_data'), style: const TextStyle(color: SoulFlowTheme.primarySage, fontWeight: FontWeight.bold)),
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

    final List<String> moodLabels = [
      localizations.translate('mood_very_sad'),
      localizations.translate('mood_sad'),
      localizations.translate('mood_neutral'),
      localizations.translate('mood_happy'),
      localizations.translate('mood_very_happy'),
    ];

    return StreamBuilder<List<MoodModel>>(
      stream: _moodManager.moodStream,
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final totalCheckIns = logs.length;
        final streak = _calculateStreak(logs);
        final topEmotion = _calculateTopEmotion(logs, moodLabels);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Info Header Card
              _buildProfileHeaderCard(localizations, isDark),
              const SizedBox(height: 24),

              // Statistics Metrics
              Text(
                localizations.translate('healing_achievements'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: SoulFlowTheme.primarySage,
                    ),
              ),
              const SizedBox(height: 12),
              _buildStatsGrid(totalCheckIns, streak, topEmotion, localizations, isDark),
              const SizedBox(height: 28),

              // Settings List
              Text(
                localizations.translate('app_settings'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: SoulFlowTheme.primarySage,
                    ),
              ),
              const SizedBox(height: 12),
              _buildSettingsCard(localizations, isDark, logs),
              const SizedBox(height: 28),

              // Logout Button
              _buildLogoutButton(context, localizations),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeaderCard(AppLocalizations localizations, bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isLinked = _moodManager.isCloudSyncEnabled && !authProvider.isAnonymous;
    
    final userText = isLinked
        ? (authProvider.user?.displayName ?? 'Thành viên SoulFlow')
        : 'Người dùng SoulFlow';
    final subtitleText = isLinked
        ? localizations.translate('cloud_connected')
        : localizations.translate('cloud_disconnected');

    return Card(
      elevation: 0,
      color: isDark ? SoulFlowTheme.surfaceCardDark : SoulFlowTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : SoulFlowTheme.accentGlow, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: SoulFlowTheme.accentGlow,
              child: Text('🧘', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : SoulFlowTheme.textCharcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SoulFlowTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(int totalCheckIns, int streak, String topEmotion, AppLocalizations localizations, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatMetricCard(
              title: localizations.translate('total_checkins'),
              value: '$totalCheckIns ${localizations.translate('checkins_unit')}',
              icon: '🌸',
              width: cardWidth,
              isDark: isDark,
            ),
            _buildStatMetricCard(
              title: localizations.translate('streak'),
              value: '$streak ${localizations.translate('streak_unit')}',
              icon: '🔥',
              width: cardWidth,
              isDark: isDark,
            ),
            _buildStatMetricCard(
              title: localizations.translate('popular_emotion'),
              value: topEmotion,
              icon: '💭',
              width: constraints.maxWidth,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatMetricCard({
    required String title,
    required String value,
    required String icon,
    required double width,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? SoulFlowTheme.surfaceCardDark : SoulFlowTheme.surfaceCard,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : SoulFlowTheme.accentGlow, width: 1),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: SoulFlowTheme.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : SoulFlowTheme.textCharcoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(AppLocalizations localizations, bool isDark, List<MoodModel> logs) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Card(
      elevation: 0,
      color: isDark ? SoulFlowTheme.surfaceCardDark : SoulFlowTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : SoulFlowTheme.accentGlow, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        child: Column(
          children: [
            // Daily reminder
            ListTile(
              title: Text(localizations.translate('daily_reminder'), style: const TextStyle(fontSize: 14)),
              trailing: Switch.adaptive(
                value: _notificationsEnabled,
                onChanged: (val) {
                  _toggleNotificationSetting(val);
                },
                activeTrackColor: SoulFlowTheme.primarySage,
              ),
            ),
            const Divider(color: SoulFlowTheme.accentGlow, height: 1),

            // Theme toggle
            ListTile(
              title: Text(localizations.translate('dark_mode'), style: const TextStyle(fontSize: 14)),
              trailing: Switch.adaptive(
                value: themeProvider.isDarkMode,
                onChanged: (val) {
                  themeProvider.toggleTheme(val);
                },
                activeTrackColor: SoulFlowTheme.primarySage,
              ),
            ),
            const Divider(color: SoulFlowTheme.accentGlow, height: 1),

            // Language switcher
            ListTile(
              title: Text(localizations.translate('change_language'), style: const TextStyle(fontSize: 14)),
              trailing: DropdownButton<String>(
                value: localeProvider.locale.languageCode,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(
                    value: 'vi',
                    child: Text(localizations.translate('vietnamese')),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(localizations.translate('english')),
                  ),
                ],
                onChanged: (String? code) {
                  if (code != null) {
                    localeProvider.setLocale(Locale(code));
                  }
                },
              ),
            ),
            const Divider(color: SoulFlowTheme.accentGlow, height: 1),

            // Export logs
            ListTile(
              title: Text(localizations.translate('export_data'), style: const TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.copy_all, color: SoulFlowTheme.primarySage),
              onTap: () => _exportLogs(logs),
            ),
            const Divider(color: SoulFlowTheme.accentGlow, height: 1),

            // Import logs
            ListTile(
              title: Text(localizations.translate('import_data'), style: const TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.drive_file_move_outlined, color: SoulFlowTheme.primarySage),
              onTap: _showImportDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppLocalizations localizations) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          await authProvider.signOut();
          await _moodManager.disableCloudSync();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: SoulFlowTheme.accentCoral, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        icon: const Icon(Icons.logout, color: SoulFlowTheme.accentCoral),
        label: Text(
          localizations.translate('logout_btn'),
          style: const TextStyle(
            color: SoulFlowTheme.accentCoral,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  int _calculateStreak(List<MoodModel> logs) {
    if (logs.isEmpty) return 0;
    
    final sortedLogs = List<MoodModel>.from(logs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final Set<DateTime> uniqueDates = {};
    for (var log in sortedLogs) {
      uniqueDates.add(DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day));
    }

    final dates = uniqueDates.toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    if (dates.isNotEmpty && dates.first.isBefore(checkDate)) {
      if (dates.first.difference(checkDate).inDays.abs() > 1) {
        return 0;
      }
      checkDate = dates.first;
    }

    for (var date in dates) {
      if (date.difference(checkDate).inDays.abs() <= 1) {
        streak++;
        checkDate = date;
      } else {
        break;
      }
    }

    return streak;
  }

  String _calculateTopEmotion(List<MoodModel> logs, List<String> moodLabels) {
    if (logs.isEmpty) return 'Chưa xác định';
    
    final counts = <int, int>{};
    for (var log in logs) {
      counts[log.moodScore] = (counts[log.moodScore] ?? 0) + 1;
    }

    int topMood = 3;
    int maxCount = 0;
    counts.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        topMood = mood;
      }
    });

    return '${_moodEmojis[topMood - 1]} ${moodLabels[topMood - 1]}';
  }
}
