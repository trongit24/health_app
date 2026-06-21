import 'package:flutter/material.dart';
import '../../../../core/theme/soul_flow_theme.dart';
import '../../../../core/services/mood_manager.dart';
import '../../../../core/services/localizations.dart';
import '../../data/models/mood_model.dart';
import '../../../../core/services/tags_data.dart';
import 'add_mood_screen.dart';

class JournalView extends StatefulWidget {
  const JournalView({super.key});

  @override
  State<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends State<JournalView> {
  final MoodManager _moodManager = MoodManager();

  final List<String> _moodEmojis = ['😢', '🙁', '😐', '🙂', '😀'];

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<MoodModel>>(
        stream: _moodManager.moodStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: SoulFlowTheme.primarySage));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('no_journal_yet'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDark ? Colors.white : SoulFlowTheme.textCharcoal,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(color: SoulFlowTheme.textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('no_journal_yet'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDark ? Colors.white : SoulFlowTheme.textCharcoal,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate('start_writing_journal'),
                    style: const TextStyle(color: SoulFlowTheme.textMuted),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildJournalCard(log, moodLabels, isDark, localizations);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddMoodScreen()),
          );
        },
        backgroundColor: SoulFlowTheme.primarySage,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildJournalCard(MoodModel log, List<String> moodLabels, bool isDark, AppLocalizations localizations) {
    final emoji = _moodEmojis[log.moodScore - 1];
    final moodText = moodLabels[log.moodScore - 1];

    return Dismissible(
      key: Key(log.id ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade100,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) async {
        if (log.id != null) {
          await _moodManager.deleteMoodEntry(log.id!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.translate('delete_success')),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          // Tap to edit entry
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddMoodScreen(existingEntry: log),
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 0,
          color: isDark ? SoulFlowTheme.surfaceCardDark : SoulFlowTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : SoulFlowTheme.accentGlow, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header line with Emoji, Title, and Date
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A221F) : SoulFlowTheme.backgroundCream,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            moodText,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            _formatDate(log.timestamp),
                            style: const TextStyle(fontSize: 11, color: SoulFlowTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    // Sentiment score indicator (if available)
                    if (log.sentimentScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: log.sentimentScore! >= 0
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          '${localizations.translate('sentiment_score')}: ${(log.sentimentScore! >= 0 ? '+' : '')}${log.sentimentScore}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: log.sentimentScore! >= 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Note body
                if (log.note != null && log.note!.isNotEmpty) ...[
                  Text(
                    log.note!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey.shade300 : SoulFlowTheme.textCharcoal,
                          fontSize: 13.5,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Associated tags
                if (log.tags.isNotEmpty)
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: log.tags.map((tag) {
                      // Lookup tag localized key
                      String translatedTag = tag;
                      final match = TagsData.allTags.firstWhere(
                        (element) => element['label'] == tag,
                        orElse: () => {},
                      );
                      if (match.containsKey('key')) {
                        translatedTag = localizations.translate(match['key']!);
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2F29) : SoulFlowTheme.accentGlow,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          '#$translatedTag',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: SoulFlowTheme.primarySage,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
