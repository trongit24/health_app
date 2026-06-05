import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/soul_flow_theme.dart';
import '../../../../core/services/localizations.dart';

class ZenSpaceView extends StatefulWidget {
  const ZenSpaceView({super.key});

  @override
  State<ZenSpaceView> createState() => _ZenSpaceViewState();
}

class _ZenSpaceViewState extends State<ZenSpaceView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingMusic = false;
  int _selectedSoundIndex = 0;

  final List<String> _soundUrls = [
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', // Rain
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', // Wind
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', // Ocean
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', // Bell
  ];

  @override
  void initState() {
    super.initState();

    // 8-second total breathing cycle: 4s inhale, 4s exhale
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutSine,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Run breathing cycle in reverse-repeat indefinitely
    _animationController.repeat(reverse: true);
    
    // Loop audio indefinitely
    _audioPlayer.setLoopMode(LoopMode.one);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayMusic(bool play) async {
    setState(() {
      _isPlayingMusic = play;
    });

    try {
      if (play) {
        await _audioPlayer.setUrl(_soundUrls[_selectedSoundIndex]);
        _audioPlayer.play();
      } else {
        await _audioPlayer.pause();
      }
    } catch (e) {
      debugPrint('Error toggling play music: $e');
    }
  }

  Future<void> _changeSound(int index) async {
    setState(() {
      _selectedSoundIndex = index;
    });

    if (_isPlayingMusic) {
      try {
        await _audioPlayer.setUrl(_soundUrls[index]);
        _audioPlayer.play();
      } catch (e) {
        debugPrint('Error changing sound: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<String> soundsList = [
      localizations.translate('sound_rain'),
      localizations.translate('sound_wind'),
      localizations.translate('sound_ocean'),
      localizations.translate('sound_bell')
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Screen Header
          Text(
            localizations.translate('zen_space_header'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SoulFlowTheme.primarySage,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            localizations.translate('zen_space_sub'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: SoulFlowTheme.textMuted, fontSize: 13),
          ),
          const Spacer(),

          // Central Breathing pulsing circle
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final isGrowing = _animationController.status == AnimationStatus.forward;
              final breathText = isGrowing 
                  ? localizations.translate('inhale') 
                  : localizations.translate('exhale');
              
              return Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glowing ring
                      Transform.scale(
                        scale: _scaleAnimation.value * 1.15,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            color: SoulFlowTheme.primarySage.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Middle glowing ring
                      Transform.scale(
                        scale: _scaleAnimation.value * 1.08,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: SoulFlowTheme.accentCoral.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Core interactive orb
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                SoulFlowTheme.primarySage,
                                Color(0xFF6B8A7E),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: SoulFlowTheme.primarySage.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: const Text(
                              '🧘',
                              style: TextStyle(fontSize: 48),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Text(
                    breathText,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: SoulFlowTheme.primarySage,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                  ),
                ],
              );
            },
          ),
          const Spacer(),

          // Audio player controller card
          _buildMusicCard(localizations, soundsList, isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMusicCard(AppLocalizations localizations, List<String> soundsList, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? SoulFlowTheme.surfaceCardDark : SoulFlowTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : SoulFlowTheme.accentGlow, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2623) : SoulFlowTheme.backgroundCream,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _isPlayingMusic ? '🎵' : '🔇',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('ambient_sound'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        _isPlayingMusic 
                            ? '${localizations.translate('playing')}: ${soundsList[_selectedSoundIndex]}' 
                            : localizations.translate('not_playing'),
                        style: const TextStyle(fontSize: 11, color: SoulFlowTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isPlayingMusic,
                  onChanged: (val) {
                    _togglePlayMusic(val);
                  },
                  activeTrackColor: SoulFlowTheme.primarySage,
                ),
              ],
            ),
            if (_isPlayingMusic) ...[
              const Divider(color: SoulFlowTheme.accentGlow, height: 20),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: soundsList.length,
                  itemBuilder: (context, index) {
                    final soundName = soundsList[index];
                    final isSelected = _selectedSoundIndex == index;
                    return GestureDetector(
                      onTap: () {
                        _changeSound(index);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8.0),
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SoulFlowTheme.primarySage
                              : (isDark ? const Color(0xFF1E2623) : SoulFlowTheme.backgroundCream),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            soundName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : SoulFlowTheme.textCharcoal),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
