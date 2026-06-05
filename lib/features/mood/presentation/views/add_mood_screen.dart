import 'package:flutter/material.dart';
import '../../../../core/services/mood_manager.dart';
import '../../../../core/services/localizations.dart';
import '../../../../core/theme/soul_flow_theme.dart';
import '../../data/models/mood_model.dart';

class AddMoodScreen extends StatefulWidget {
  final MoodModel? existingEntry;
  const AddMoodScreen({super.key, this.existingEntry});

  @override
  State<AddMoodScreen> createState() => _AddMoodScreenState();
}

class _AddMoodScreenState extends State<AddMoodScreen> {
  final MoodManager _moodManager = MoodManager();
  final TextEditingController _noteController = TextEditingController();
  
  int _selectedMoodScore = 3;
  final List<String> _selectedTags = [];
  bool _isLoading = false;
  bool _isEditing = false;

  final List<Map<String, String>> _presetTags = [
    {'emoji': '🧘', 'label': 'Tĩnh lặng', 'key': 'tag_calm'},
    {'emoji': '⚡', 'label': 'Căng thẳng', 'key': 'tag_stressed'},
    {'emoji': '🎉', 'label': 'Hào hứng', 'key': 'tag_excited'},
    {'emoji': '😴', 'label': 'Mệt mỏi', 'key': 'tag_tired'},
    {'emoji': '🧠', 'label': 'Tập trung', 'key': 'tag_focused'},
    {'emoji': '😟', 'label': 'Lo âu', 'key': 'tag_anxious'},
    {'emoji': '💖', 'label': 'Biết ơn', 'key': 'tag_grateful'},
    {'emoji': '🍀', 'label': 'Bình yên', 'key': 'tag_peaceful'},
  ];

  final List<Color> _moodColors = [
    Colors.blue.shade300,
    Colors.cyan.shade300,
    Colors.teal.shade300,
    Colors.orange.shade300,
    Colors.amber.shade400,
  ];

  final List<String> _moodEmojis = ['😢', '🙁', '😐', '🙂', '😀'];

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _isEditing = true;
      _selectedMoodScore = widget.existingEntry!.moodScore;
      _selectedTags.addAll(widget.existingEntry!.tags);
      _noteController.text = widget.existingEntry!.note ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _saveMoodEntry() async {
    setState(() => _isLoading = true);
    final localizations = AppLocalizations.of(context);

    try {
      final noteText = _noteController.text.trim();
      final finalNote = noteText.isEmpty ? null : noteText;

      if (_isEditing) {
        final updated = widget.existingEntry!.copyWith(
          moodScore: _selectedMoodScore,
          note: finalNote,
          tags: _selectedTags,
        );
        await _moodManager.updateMoodEntry(updated);
      } else {
        await _moodManager.addMoodEntry(
          moodScore: _selectedMoodScore,
          note: finalNote,
          tags: _selectedTags,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.favorite, color: Colors.pink.shade100, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations.translate('save_success'),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: SoulFlowTheme.primarySage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar('${localizations.translate('save_error_general')} ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? localizations.translate('edit_mood_title') : localizations.translate('add_mood_title'),
          style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1E2623),
                    const Color(0xFF121816),
                  ]
                : [
                    const Color(0xFFF5EFFF),
                    const Color(0xFFEBF4FA),
                    Colors.white,
                  ],
            stops: isDark ? [0.0, 1.0] : [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.translate('how_is_today'),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  localizations.translate('spend_time_to_understand'),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                _buildMoodScoreSection(moodLabels, isDark),
                const SizedBox(height: 28),

                _buildJournalNotesSection(localizations, isDark),
                const SizedBox(height: 24),

                _buildTagsSelectorSection(localizations, isDark),
                const SizedBox(height: 36),

                _buildSaveButtonSection(localizations),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodScoreSection(List<String> labels, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? SoulFlowTheme.surfaceCardDark : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.purple.shade100).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final score = index + 1;
              final isSelected = _selectedMoodScore == score;
              final color = _moodColors[index];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMoodScore = score;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.25) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  transform: Matrix4.diagonal3Values(isSelected ? 1.25 : 1.0, isSelected ? 1.25 : 1.0, 1.0),
                  child: Text(
                    _moodEmojis[index],
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              labels[_selectedMoodScore - 1],
              key: ValueKey<int>(_selectedMoodScore),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _moodColors[_selectedMoodScore - 1].withRed(80).withBlue(100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalNotesSection(AppLocalizations localizations, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note, color: SoulFlowTheme.primarySage),
            const SizedBox(width: 8),
            Text(
              localizations.translate('write_note_lbl'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? SoulFlowTheme.surfaceCardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.transparent : Colors.grey.shade200,
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            style: TextStyle(color: isDark ? Colors.white : Colors.grey.shade800, fontSize: 15),
            decoration: InputDecoration(
              hintText: localizations.translate('journal_placeholder'),
              hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontSize: 13.5),
              contentPadding: const EdgeInsets.all(18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: SoulFlowTheme.primarySage, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSelectorSection(AppLocalizations localizations, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_offer_outlined, color: SoulFlowTheme.primarySage),
            const SizedBox(width: 8),
            Text(
              localizations.translate('related_emotions'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 10.0,
          children: _presetTags.map((tag) {
            final rawLabel = tag['label']!;
            final emoji = tag['emoji']!;
            final translationKey = tag['key']!;
            final translatedLabel = localizations.translate(translationKey);
            final fullLabel = '$emoji $translatedLabel';
            final isSelected = _selectedTags.contains(rawLabel);

            return ChoiceChip(
              label: Text(
                fullLabel,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _toggleTag(rawLabel),
              selectedColor: SoulFlowTheme.primarySage,
              backgroundColor: isDark ? SoulFlowTheme.surfaceCardDark : Colors.white,
              elevation: isSelected ? 3 : 0,
              pressElevation: 4,
              shadowColor: SoulFlowTheme.primarySage.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
                  width: 1,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButtonSection(AppLocalizations localizations) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _isLoading ? Colors.grey.shade300 : SoulFlowTheme.primarySage,
          boxShadow: _isLoading
              ? null
              : [
                  BoxShadow(
                    color: SoulFlowTheme.primarySage.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveMoodEntry,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bookmark_added_outlined, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      localizations.translate('save_journal'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
