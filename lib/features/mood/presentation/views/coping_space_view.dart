import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/soul_flow_theme.dart';
import '../../../../core/services/localizations.dart';

class CopingSpaceView extends StatefulWidget {
  const CopingSpaceView({super.key});

  @override
  State<CopingSpaceView> createState() => _CopingSpaceViewState();
}

class _CopingSpaceViewState extends State<CopingSpaceView> with TickerProviderStateMixin {
  int _activeTab = 0; // 0: Breathing, 1: Grounding, 2: Sound Mixer

  // 1. Audio Players for Sound Mixer (initialized lazily)
  AudioPlayer? _rainPlayer;
  AudioPlayer? _windPlayer;
  AudioPlayer? _oceanPlayer;
  AudioPlayer? _bellPlayer;

  bool _isMixerPlaying = false;
  bool _rainOn = false;
  bool _windOn = false;
  bool _oceanOn = false;
  bool _bellOn = false;

  bool _rainLoading = false;
  bool _windLoading = false;
  bool _oceanLoading = false;
  bool _bellLoading = false;

  double _rainVolume = 0.5;
  double _windVolume = 0.5;
  double _oceanVolume = 0.5;
  double _bellVolume = 0.5;

  final List<String> _soundUrls = [
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', // Rain
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', // Wind
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', // Ocean
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', // Bell
  ];

  // 2. Box Breathing variables
  late AnimationController _breathController;
  late Animation<double> _breathScale;
  int _breathPhase = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Hold
  int _breathTimerCount = 4;
  Timer? _breathTimer;
  bool _isBreathingActive = false;

  // 3. Grounding 5-4-3-2-1 variables
  int _groundingStep = 5; // 5 -> 4 -> 3 -> 2 -> 1 -> 0 (complete)
  final List<TextEditingController> _groundingControllers = List.generate(5, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    // Skip synchronous initialization of audio players to prevent UI lag on mobile

    // Box breathing animation controller
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breathScale = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  Future<AudioPlayer?> _getOrInitPlayer(int index) async {
    if (index == 0) {
      if (_rainPlayer == null) {
        setState(() => _rainLoading = true);
        try {
          final player = AudioPlayer();
          await player.setUrl(_soundUrls[0]);
          await player.setLoopMode(LoopMode.one);
          _rainPlayer = player;
        } catch (e) {
          debugPrint('Error loading rain player: $e');
        } finally {
          setState(() => _rainLoading = false);
        }
      }
      return _rainPlayer;
    } else if (index == 1) {
      if (_windPlayer == null) {
        setState(() => _windLoading = true);
        try {
          final player = AudioPlayer();
          await player.setUrl(_soundUrls[1]);
          await player.setLoopMode(LoopMode.one);
          _windPlayer = player;
        } catch (e) {
          debugPrint('Error loading wind player: $e');
        } finally {
          setState(() => _windLoading = false);
        }
      }
      return _windPlayer;
    } else if (index == 2) {
      if (_oceanPlayer == null) {
        setState(() => _oceanLoading = true);
        try {
          final player = AudioPlayer();
          await player.setUrl(_soundUrls[2]);
          await player.setLoopMode(LoopMode.one);
          _oceanPlayer = player;
        } catch (e) {
          debugPrint('Error loading ocean player: $e');
        } finally {
          setState(() => _oceanLoading = false);
        }
      }
      return _oceanPlayer;
    } else if (index == 3) {
      if (_bellPlayer == null) {
        setState(() => _bellLoading = true);
        try {
          final player = AudioPlayer();
          await player.setUrl(_soundUrls[3]);
          await player.setLoopMode(LoopMode.one);
          _bellPlayer = player;
        } catch (e) {
          debugPrint('Error loading bell player: $e');
        } finally {
          setState(() => _bellLoading = false);
        }
      }
      return _bellPlayer;
    }
    return null;
  }

  void _updateMixerVolumes() {
    _rainPlayer?.setVolume(_rainOn && _isMixerPlaying ? _rainVolume : 0.0);
    _windPlayer?.setVolume(_windOn && _isMixerPlaying ? _windVolume : 0.0);
    _oceanPlayer?.setVolume(_oceanOn && _isMixerPlaying ? _oceanVolume : 0.0);
    _bellPlayer?.setVolume(_bellOn && _isMixerPlaying ? _bellVolume : 0.0);
  }

  Future<void> _toggleSound(int index, bool on) async {
    if (on) {
      final player = await _getOrInitPlayer(index);
      if (player != null) {
        setState(() {
          if (index == 0) _rainOn = true;
          if (index == 1) _windOn = true;
          if (index == 2) _oceanOn = true;
          if (index == 3) _bellOn = true;
        });
        _updateMixerVolumes();
        if (_isMixerPlaying) {
          player.play();
        }
      }
    } else {
      setState(() {
        if (index == 0) _rainOn = false;
        if (index == 1) _windOn = false;
        if (index == 2) _oceanOn = false;
        if (index == 3) _bellOn = false;
      });
      _updateMixerVolumes();
      if (index == 0) _rainPlayer?.pause();
      if (index == 1) _windPlayer?.pause();
      if (index == 2) _oceanPlayer?.pause();
      if (index == 3) _bellPlayer?.pause();
    }
  }

  void _onVolumeChange(int index, double vol) {
    setState(() {
      if (index == 0) _rainVolume = vol;
      if (index == 1) _windVolume = vol;
      if (index == 2) _oceanVolume = vol;
      if (index == 3) _bellVolume = vol;
    });
    _updateMixerVolumes();
  }

  void _toggleMixerPlay() async {
    setState(() {
      _isMixerPlaying = !_isMixerPlaying;
    });

    _updateMixerVolumes();

    if (_isMixerPlaying) {
      if (_rainOn) {
        final p = await _getOrInitPlayer(0);
        p?.play();
      }
      if (_windOn) {
        final p = await _getOrInitPlayer(1);
        p?.play();
      }
      if (_oceanOn) {
        final p = await _getOrInitPlayer(2);
        p?.play();
      }
      if (_bellOn) {
        final p = await _getOrInitPlayer(3);
        p?.play();
      }
    } else {
      _rainPlayer?.pause();
      _windPlayer?.pause();
      _oceanPlayer?.pause();
      _bellPlayer?.pause();
    }
  }

  // Box Breathing cycle runner
  void _startBreathing() {
    setState(() {
      _isBreathingActive = true;
      _breathPhase = 0;
      _breathTimerCount = 4;
    });

    _breathController.forward();
    _runBreathingTimer();
  }

  void _stopBreathing() {
    _breathTimer?.cancel();
    _breathController.stop();
    _breathController.reset();
    setState(() {
      _isBreathingActive = false;
      _breathPhase = 0;
    });
  }

  void _runBreathingTimer() {
    _breathTimer?.cancel();
    _breathTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _breathTimerCount--;

        if (_breathTimerCount <= 0) {
          _breathTimerCount = 4;
          _breathPhase = (_breathPhase + 1) % 4;

          // Animate scale based on phase
          if (_breathPhase == 0) {
            _breathController.forward(); // Inhale: expand
          } else if (_breathPhase == 1) {
            // Hold: stay expanded
          } else if (_breathPhase == 2) {
            _breathController.reverse(); // Exhale: contract
          } else if (_breathPhase == 3) {
            // Hold: stay contracted
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _rainPlayer?.dispose();
    _windPlayer?.dispose();
    _oceanPlayer?.dispose();
    _bellPlayer?.dispose();

    _breathTimer?.cancel();
    _breathController.dispose();

    for (var controller in _groundingControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121816) : const Color(0xFFFBFBF9),
      appBar: AppBar(
        title: Text(
          localizations.translate('coping_space'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Subheader description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Text(
              localizations.translate('coping_space_sub'),
              style: const TextStyle(fontSize: 13, color: SoulFlowTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),

          // Custom TabBar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isDark ? SoulFlowTheme.surfaceCardDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : SoulFlowTheme.accentGlow),
            ),
            child: Row(
              children: [
                _buildTabItem(0, '🌬️', localizations.translate('breathing_exercise')),
                _buildTabItem(1, '🧩', '5-4-3-2-1'),
                _buildTabItem(2, '🎛️', localizations.translate('sound_mixer')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildActiveView(isDark, localizations),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String emoji, String label) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = index;
          });
          // Clean breathing if switching tab
          if (index != 0) _stopBreathing();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? SoulFlowTheme.primarySage : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : SoulFlowTheme.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveView(bool isDark, AppLocalizations localizations) {
    switch (_activeTab) {
      case 0:
        return _buildBreathingView(isDark, localizations);
      case 1:
        return _buildGroundingView(isDark, localizations);
      case 2:
        return _buildSoundMixerView(isDark, localizations);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- 🌬️ BREATHING VIEW ---
  Widget _buildBreathingView(bool isDark, AppLocalizations localizations) {
    String instructionText = 'Sẵn sàng để bắt đầu hít thở sâu';
    Color circleColor = SoulFlowTheme.primarySage;
    if (_isBreathingActive) {
      switch (_breathPhase) {
        case 0:
          instructionText = 'Hít vào chậm rãi... 🌬️';
          circleColor = Colors.cyan.shade300;
          break;
        case 1:
          instructionText = 'Giữ hơi thở lại... 🧘';
          circleColor = Colors.amber.shade400;
          break;
        case 2:
          instructionText = 'Thở ra nhẹ nhàng... 🍃';
          circleColor = Colors.teal.shade300;
          break;
        case 3:
          instructionText = 'Giữ phổi trống rỗng... ✨';
          circleColor = Colors.orange.shade300;
          break;
      }
    }

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Interactive Pulsing Circle
          AnimatedBuilder(
            animation: _breathScale,
            builder: (context, child) {
              return Transform.scale(
                scale: _isBreathingActive ? _breathScale.value : 1.0,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: circleColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: circleColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: circleColor.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: _isBreathingActive ? (_breathScale.value * 5) : 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isBreathingActive ? '$_breathTimerCount' : '4-4-4-4',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : SoulFlowTheme.textCharcoal,
                          ),
                        ),
                        if (_isBreathingActive)
                          const Text(
                            'giây',
                            style: TextStyle(fontSize: 10, color: SoulFlowTheme.textMuted, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 50),
          Text(
            instructionText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : SoulFlowTheme.textCharcoal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Hộp thở chánh niệm (Box Breathing) giúp nhịp tim ổn định và xoa dịu thần kinh tức thì.',
            style: TextStyle(fontSize: 12, color: SoulFlowTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Play/Stop control button
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isBreathingActive ? SoulFlowTheme.accentCoral : SoulFlowTheme.primarySage,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _isBreathingActive ? _stopBreathing : _startBreathing,
              icon: Icon(_isBreathingActive ? Icons.stop : Icons.play_arrow, color: Colors.white),
              label: Text(
                _isBreathingActive ? 'Dừng luyện tập' : 'Bắt đầu luyện thở',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 🧩 GROUNDING WIZARD ---
  Widget _buildGroundingView(bool isDark, AppLocalizations localizations) {
    if (_groundingStep == 0) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text('🌟', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              localizations.translate('grounding_complete'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: SoulFlowTheme.primarySage),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Cảm ơn bạn đã kết nối lại với thế giới giác quan xung quanh. Hãy hít một hơi thật sâu trước khi trở lại nhé.',
              style: TextStyle(fontSize: 13, color: SoulFlowTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 180,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SoulFlowTheme.primarySage,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  setState(() {
                    _groundingStep = 5;
                    for (var ctrl in _groundingControllers) {
                      ctrl.clear();
                    }
                  });
                },
                child: const Text('Thực hành lại', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    final stepLabels = {
      5: {'icon': '👁️', 'label': localizations.translate('grounding_step_5'), 'count': 5},
      4: {'icon': '🤝', 'label': localizations.translate('grounding_step_4'), 'count': 4},
      3: {'icon': '👂', 'label': localizations.translate('grounding_step_3'), 'count': 3},
      2: {'icon': '👃', 'label': localizations.translate('grounding_step_2'), 'count': 2},
      1: {'icon': '👅', 'label': localizations.translate('grounding_step_1'), 'count': 1},
    };

    final currentInfo = stepLabels[_groundingStep]!;
    final icon = currentInfo['icon'] as String;
    final label = currentInfo['label'] as String;
    final int count = currentInfo['count'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bước $icon $_groundingStep',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SoulFlowTheme.primarySage),
            ),
            Text(
              '${6 - _groundingStep}/5',
              style: const TextStyle(fontSize: 13, color: SoulFlowTheme.textMuted, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (6 - _groundingStep) / 5,
          backgroundColor: isDark ? Colors.white10 : SoulFlowTheme.accentGlow,
          valueColor: const AlwaysStoppedAnimation<Color>(SoulFlowTheme.primarySage),
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 24),

        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : SoulFlowTheme.textCharcoal,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        // Textfields
        Column(
          children: List.generate(count, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? SoulFlowTheme.surfaceCardDark : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: _groundingControllers[index],
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ý thứ ${index + 1}...',
                    hintStyle: const TextStyle(color: SoulFlowTheme.textMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: SoulFlowTheme.primarySage, width: 1.5),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),

        // Action button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SoulFlowTheme.primarySage,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () {
              // Hide keyboard
              FocusScope.of(context).unfocus();
              setState(() {
                _groundingStep--;
                for (var ctrl in _groundingControllers) {
                  ctrl.clear();
                }
              });
            },
            child: const Text('Tiếp tục', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // --- 🎛️ SOUND MIXER VIEW ---
  Widget _buildSoundMixerView(bool isDark, AppLocalizations localizations) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Mixer state panel
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? SoulFlowTheme.surfaceCardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white10 : SoulFlowTheme.accentGlow),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mixer Bàn Tròn 🎚️',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isMixerPlaying ? 'Đang phát âm thanh phối hợp' : 'Âm thanh đang tạm dừng',
                        style: const TextStyle(color: SoulFlowTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: _isMixerPlaying ? SoulFlowTheme.accentCoral : SoulFlowTheme.primarySage,
                    radius: 26,
                    child: IconButton(
                      icon: Icon(_isMixerPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28),
                      onPressed: _toggleMixerPlay,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Sliders card
        _buildMixerSliderRow('Rain 🌧️', _rainOn, _rainLoading, _rainVolume, (on) {
          _toggleSound(0, on);
        }, (vol) {
          _onVolumeChange(0, vol);
        }, isDark),

        _buildMixerSliderRow('Wind 🍃', _windOn, _windLoading, _windVolume, (on) {
          _toggleSound(1, on);
        }, (vol) {
          _onVolumeChange(1, vol);
        }, isDark),

        _buildMixerSliderRow('Ocean 🌊', _oceanOn, _oceanLoading, _oceanVolume, (on) {
          _toggleSound(2, on);
        }, (vol) {
          _onVolumeChange(2, vol);
        }, isDark),

        _buildMixerSliderRow('Bell 🔔', _bellOn, _bellLoading, _bellVolume, (on) {
          _toggleSound(3, on);
        }, (vol) {
          _onVolumeChange(3, vol);
        }, isDark),
      ],
    );
  }

  Widget _buildMixerSliderRow(
    String label,
    bool isOn,
    bool isLoading,
    double volume,
    Function(bool) onToggle,
    Function(double) onVolumeChange,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? SoulFlowTheme.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : SoulFlowTheme.accentGlow),
      ),
      child: Row(
        children: [
          // Switch/Toggle button
          GestureDetector(
            onTap: isLoading ? null : () => onToggle(!isOn),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOn ? SoulFlowTheme.primarySage.withValues(alpha: 0.15) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: isOn ? SoulFlowTheme.primarySage : Colors.grey.shade300, width: 1.5),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(SoulFlowTheme.primarySage),
                      ),
                    )
                  : Icon(
                      isOn ? Icons.volume_up : Icons.volume_off,
                      size: 20,
                      color: isOn ? SoulFlowTheme.primarySage : Colors.grey,
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Label
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isOn ? (isDark ? Colors.white : SoulFlowTheme.textCharcoal) : Colors.grey,
              ),
            ),
          ),

          // Volume Slider
          Expanded(
            flex: 5,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: SoulFlowTheme.primarySage,
                inactiveTrackColor: isDark ? Colors.white10 : Colors.grey.shade200,
                thumbColor: SoulFlowTheme.primarySage,
                overlayColor: SoulFlowTheme.primarySage.withValues(alpha: 0.15),
                trackHeight: 3.5,
              ),
              child: Slider(
                value: volume,
                onChanged: isOn && !isLoading ? onVolumeChange : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
