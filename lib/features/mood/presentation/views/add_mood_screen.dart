import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/services/mood_manager.dart';
import '../../../../core/services/localizations.dart';
import '../../../../core/theme/soul_flow_theme.dart';
import '../../../../core/services/tags_data.dart';
import '../../data/models/mood_model.dart';
import 'camera_scanner_overlay.dart';

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

  stt.SpeechToText? _speech;
  bool _speechInitialized = false;
  bool _isSpeechListening = false;
  String _speechResultText = '';
  bool _isSpeechLoading = false;

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
    _speech?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  void _onMoodScoreChanged(int newScore) {
    setState(() {
      _selectedMoodScore = newScore;
      final newPresetLabels = TagsData.getTagsForScore(newScore).map((t) => t['label']!).toList();
      _selectedTags.retainWhere((tag) => newPresetLabels.contains(tag));
    });
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
    if (!mounted) return;
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

  void _showVoiceDiaryDialog() async {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    setState(() {
      _speechResultText = '';
    });

    _speech ??= stt.SpeechToText();

    if (!_speechInitialized) {
      setState(() => _isSpeechLoading = true);
      try {
        bool available = await _speech!.initialize(
          debugLogging: true,
          onStatus: (status) {
            if (mounted) {
              setState(() {
                _isSpeechListening = status == 'listening';
              });
            }
          },
          onError: (errorNotification) {
            debugPrint('Speech recognition error: $errorNotification');
            if (mounted) {
              setState(() {
                _isSpeechListening = false;
              });
            }
          },
        );
        if (available) {
          _speechInitialized = true;
        } else {
          _showErrorSnackBar('Thiết bị không hỗ trợ nhận diện giọng nói hoặc quyền đã bị từ chối.');
        }
      } catch (e) {
        debugPrint('Speech recognition initialization failed: $e');
        _showErrorSnackBar('Không thể khởi tạo bộ nhận diện giọng nói.');
      } finally {
        if (mounted) {
          setState(() => _isSpeechLoading = false);
        }
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? SoulFlowTheme.surfaceCardDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setBottomSheetState) {
            
            void startListening() async {
              if (_speechInitialized && !_isSpeechListening) {
                final localeCode = AppLocalizations.of(context).locale.languageCode;
                final targetLocaleId = localeCode == 'vi' ? 'vi_VN' : 'en_US';

                await _speech!.listen(
                  onResult: (result) {
                    if (sheetCtx.mounted) {
                      setBottomSheetState(() {
                        _speechResultText = result.recognizedWords;
                      });
                    }
                    if (mounted) {
                      setState(() {
                        _speechResultText = result.recognizedWords;
                      });
                    }
                  },
                  localeId: targetLocaleId,
                );
                if (sheetCtx.mounted) {
                  setBottomSheetState(() {});
                }
              }
            }

            void stopListening() async {
              if (_isSpeechListening) {
                await _speech!.stop();
                if (sheetCtx.mounted) {
                  setBottomSheetState(() {});
                }
              }
            }

            final showWaveforms = _isSpeechListening;

            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 30.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    localizations.translate('voice_diary_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: SoulFlowTheme.primarySage),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2623) : SoulFlowTheme.backgroundCream,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: _isSpeechLoading 
                          ? const CircularProgressIndicator(color: SoulFlowTheme.primarySage)
                          : showWaveforms
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(8, (index) {
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: 4,
                                      height: 15.0 + Random().nextDouble() * 35.0,
                                      decoration: BoxDecoration(
                                        color: SoulFlowTheme.accentCoral,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  }),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.mic, size: 36, color: SoulFlowTheme.primarySage),
                                      onPressed: startListening,
                                    ),
                                    const Text('Nhấn biểu tượng mic để bắt đầu nói', style: TextStyle(fontSize: 10, color: SoulFlowTheme.textMuted)),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _isSpeechListening 
                        ? localizations.translate('voice_diary_hint') 
                        : (_speechResultText.isNotEmpty ? 'Đã ghi âm hoàn tất!' : 'Đang chờ bạn ghi âm...'),
                    style: TextStyle(
                      fontSize: 12, 
                      fontStyle: FontStyle.italic, 
                      color: _isSpeechListening ? SoulFlowTheme.accentCoral : (_speechResultText.isNotEmpty ? Colors.green : SoulFlowTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    constraints: const BoxConstraints(minHeight: 80, maxHeight: 150),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _speechResultText.isEmpty 
                            ? (_isSpeechListening ? 'Đang lắng nghe...' : 'Bản dịch giọng nói của bạn sẽ xuất hiện ở đây...') 
                            : _speechResultText,
                        style: TextStyle(
                          fontSize: 14,
                          color: _speechResultText.isEmpty ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: () {
                            stopListening();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SoulFlowTheme.primarySage,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: _isSpeechListening || _speechResultText.isEmpty
                              ? (_isSpeechListening ? stopListening : null)
                              : () {
                                  if (mounted) {
                                    setState(() {
                                      _noteController.text = _speechResultText;
                                    });
                                  }
                                  Navigator.pop(ctx);
                                },
                          child: Text(
                            _isSpeechListening ? 'Hoàn tất nói' : 'Chèn vào Nhật ký', 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      _speech?.cancel(); // Cleanly and immediately cancel speech to release resource & mic locks
    });
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
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : SoulFlowTheme.accentGlow,
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, size: 18, color: isDark ? Colors.white : SoulFlowTheme.textCharcoal),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
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
                    const Color(0xFFFFFBF1),
                    const Color(0xFFF5EFE4),
                    const Color(0xFFFFFBF1),
                  ],
            stops: isDark ? [0.0, 1.0] : [0.0, 0.4, 0.8],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.translate('how_is_today'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : SoulFlowTheme.textCharcoal,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  localizations.translate('spend_time_to_understand'),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? SoulFlowTheme.textMutedDark : SoulFlowTheme.textMuted,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? SoulFlowTheme.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : SoulFlowTheme.accentGlow,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : SoulFlowTheme.primarySage.withValues(alpha: 0.06),
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
                onTap: () => _onMoodScoreChanged(score),
                child: SizedBox(
                  width: 55,
                  height: 55,
                  child: Center(
                    child: AnimatedScale(
                      scale: isSelected ? 1.25 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? color : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 10,
                            )
                          ] : [],
                        ),
                        child: Text(
                          _moodEmojis[index],
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Text(
            labels[_selectedMoodScore - 1],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.lerp(_moodColors[_selectedMoodScore - 1], isDark ? Colors.white : Colors.black87, 0.45),
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Colors.grey, thickness: 0.15),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF25332E), const Color(0xFF1E2623)]
                    : [SoulFlowTheme.accentGlow.withValues(alpha: 0.4), Colors.white],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : SoulFlowTheme.accentGlow.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final detectedScore = await Navigator.of(context).push<int>(
                  MaterialPageRoute(builder: (context) => const CameraScannerOverlay()),
                );
                if (detectedScore != null) {
                  _onMoodScoreChanged(detectedScore);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.face_retouching_natural, color: SoulFlowTheme.primarySage, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Quét cảm xúc khuôn mặt bằng Camera 📷',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : SoulFlowTheme.primarySage,
                      ),
                    ),
                  ],
                ),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    color: isDark ? Colors.white : SoulFlowTheme.textCharcoal,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: _showVoiceDiaryDialog,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A3631) : SoulFlowTheme.accentGlow.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : SoulFlowTheme.primarySage.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic, size: 16, color: SoulFlowTheme.primarySage),
                    const SizedBox(width: 4),
                    Text(
                      'AI Voice Diary 🎙️',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white70 : SoulFlowTheme.primarySage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? SoulFlowTheme.surfaceCardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : SoulFlowTheme.accentGlow,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.transparent : Colors.grey.shade100,
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            style: TextStyle(color: isDark ? Colors.white : SoulFlowTheme.textCharcoal, fontSize: 14.5),
            decoration: InputDecoration(
              hintText: localizations.translate('journal_placeholder'),
              hintStyle: TextStyle(color: isDark ? SoulFlowTheme.textMutedDark.withValues(alpha: 0.6) : SoulFlowTheme.textMuted.withValues(alpha: 0.7), fontSize: 13.5),
              contentPadding: const EdgeInsets.all(20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
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
                color: isDark ? Colors.white : SoulFlowTheme.textCharcoal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? SoulFlowTheme.surfaceCardDark.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : SoulFlowTheme.accentGlow.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 10.0,
            children: TagsData.getTagsForScore(_selectedMoodScore).map((tag) {
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
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => _toggleTag(rawLabel),
                selectedColor: SoulFlowTheme.primarySage,
                backgroundColor: isDark ? const Color(0xFF27322E) : Colors.white,
                elevation: 0,
                pressElevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : (isDark ? const Color.fromRGBO(255, 255, 255, 0.08) : Colors.grey.shade200),
                    width: 1,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButtonSection(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: _isLoading
            ? null
            : LinearGradient(
                colors: [
                  SoulFlowTheme.primarySage,
                  SoulFlowTheme.primarySage.withBlue(100),
                ],
              ),
        color: _isLoading ? Colors.grey.shade300 : null,
        boxShadow: _isLoading
            ? null
            : [
                BoxShadow(
                  color: SoulFlowTheme.primarySage.withValues(alpha: 0.3),
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
                  const Icon(Icons.bookmark_added_outlined, color: Colors.white, size: 22),
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
    );
  }
}
