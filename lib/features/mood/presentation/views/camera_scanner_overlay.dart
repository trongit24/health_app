import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../../core/theme/soul_flow_theme.dart';
import '../../../../core/services/localizations.dart';

class CameraScannerOverlay extends StatefulWidget {
  const CameraScannerOverlay({super.key});

  @override
  State<CameraScannerOverlay> createState() => _CameraScannerOverlayState();
}

class _CameraScannerOverlayState extends State<CameraScannerOverlay> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitializing = true;
  final bool _hasError = false;
  final String _errorMessage = '';

  // Scanning simulation state
  double _scanProgress = 0.0;
  String _scanningText = 'Khởi động máy ảnh...';
  bool _scanComplete = false;
  int _detectedScore = 3;
  double _smileProb = 0.5;
  double _calmProb = 0.5;

  late AnimationController _animationController;
  late Animation<double> _laserAnimation;
  Timer? _scanTimer;
  bool _useSimulationFallback = false;

  @override
  void initState() {
    super.initState();
    _initCamera();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      setState(() {
        _isInitializing = false;
        _scanningText = 'Định vị khuôn mặt...';
      });
      _startScanningSimulation();
      return;
    }

    bool cameraLoaded = false;
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && !cameraLoaded && !_hasError) {
        debugPrint('Camera initialization timeout. Falling back to simulation.');
        setState(() {
          _useSimulationFallback = true;
          _isInitializing = false;
          _scanningText = 'Định vị khuôn mặt (Mô phỏng)...';
        });
        _startScanningSimulation();
      }
    });

    CameraController? controller;
    try {
      _cameras = await availableCameras().timeout(const Duration(milliseconds: 2000));
      if (!mounted) return;

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('Không tìm thấy thiết bị camera.');
      }

      // Try to find the front camera
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      final targetCamera = frontCamera ?? _cameras!.first;
      controller = CameraController(
        targetCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize().timeout(const Duration(milliseconds: 2000));
      
      if (!mounted) {
        try {
          await controller.dispose();
        } catch (ex) {
          debugPrint('Error disposing camera controller after unmount: $ex');
        }
        return;
      }

      _controller = controller;
      cameraLoaded = true;

      if (!_useSimulationFallback) {
        setState(() {
          _isInitializing = false;
          _scanningText = 'Định vị khuôn mặt...';
        });
        _startScanningSimulation();
      } else {
        _controller = null;
        try {
          await controller.dispose();
        } catch (ex) {
          debugPrint('Error disposing unused camera controller: $ex');
        }
      }
    } catch (e) {
      debugPrint('Camera load failed, falling back to simulation: $e');
      if (controller != null) {
        try {
          await controller.dispose();
        } catch (ex) {
          debugPrint('Error disposing failed camera controller: $ex');
        }
      }
      if (mounted) {
        if (!_useSimulationFallback) {
          setState(() {
            _useSimulationFallback = true;
            _isInitializing = false;
            _scanningText = 'Định vị khuôn mặt (Mô phỏng)...';
          });
          _startScanningSimulation();
        }
      }
    }
  }

  void _startScanningSimulation() {
    _scanTimer?.cancel();
    
    // Generate simulated results
    final random = Random();
    _smileProb = random.nextDouble();
    _calmProb = random.nextDouble();

    // Map probabilities to mood score (1 to 5)
    if (_smileProb > 0.75) {
      _detectedScore = 5; // Very Happy
    } else if (_smileProb > 0.5) {
      _detectedScore = 4; // Happy
    } else if (_calmProb > 0.6) {
      _detectedScore = 3; // Neutral
    } else if (_smileProb > 0.25) {
      _detectedScore = 2; // Sad
    } else {
      _detectedScore = 1; // Very Sad
    }

    _scanTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _scanProgress += 0.02;

        if (_scanProgress < 0.25) {
          _scanningText = 'Định vị khuôn mặt...';
        } else if (_scanProgress < 0.50) {
          _scanningText = 'Đo đạc chỉ số cơ mặt...';
        } else if (_scanProgress < 0.75) {
          _scanningText = 'Đo tỷ lệ nụ cười (Smile: ${(_smileProb * 100).toInt()}%)...';
        } else if (_scanProgress < 0.95) {
          _scanningText = 'Phân tích chấn động học tâm lý...';
        } else {
          _scanningText = 'Đang khóa cảm xúc...';
        }

        if (_scanProgress >= 1.0) {
          _scanProgress = 1.0;
          _scanComplete = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _animationController.dispose();
    final tempController = _controller;
    _controller = null;
    if (tempController != null) {
      try {
        tempController.dispose();
      } catch (e) {
        debugPrint('Error disposing camera controller: $e');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera preview or loader
          if (_isInitializing)
            const Center(
              child: CircularProgressIndicator(color: SoulFlowTheme.primarySage),
            )
          else if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('❌', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi Camera',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: SoulFlowTheme.primarySage),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            )
          else if (_controller != null && _controller!.value.isInitialized && !_useSimulationFallback)
            SizedBox.expand(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),

          // 2. Custom circular mask and laser line
          if (!_isInitializing && (!_hasError || _useSimulationFallback))
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _laserAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ScannerMaskPainter(
                      progress: _scanProgress,
                      laserOffset: _laserAnimation.value,
                      isComplete: _scanComplete,
                      drawDigitalSimulation: kIsWeb || _useSimulationFallback,
                    ),
                  );
                },
              ),
            ),

          // 3. UI Overlay Controls & Logs
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Positioned(
            top: 45,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                localizations.translate('camera_scan_title'),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),

          // Log card at bottom
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _scanComplete ? SoulFlowTheme.primarySage.withValues(alpha: 0.5) : Colors.cyan.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_scanComplete) ...[
                    Text(
                      _scanningText,
                      style: const TextStyle(color: Colors.cyan, fontSize: 14, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: _scanProgress,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ] else ...[
                    const Text(
                      '🎉 Phân Tích Cảm Xúc Hoàn Tất!',
                      style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Cảm xúc nhận diện: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(
                          _getMoodLabel(_detectedScore, localizations),
                          style: TextStyle(
                            color: _getMoodColor(_detectedScore),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              // Re-scan
                              setState(() {
                                _scanProgress = 0.0;
                                _scanComplete = false;
                              });
                              _startScanningSimulation();
                            },
                            child: const Text('Thử lại', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SoulFlowTheme.primarySage,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(context, _detectedScore);
                            },
                            child: const Text('Áp dụng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodLabel(int score, AppLocalizations localizations) {
    switch (score) {
      case 1:
        return '😢 ${localizations.translate('mood_very_sad')}';
      case 2:
        return '🙁 ${localizations.translate('mood_sad')}';
      case 3:
        return '😐 ${localizations.translate('mood_neutral')}';
      case 4:
        return '🙂 ${localizations.translate('mood_happy')}';
      case 5:
        return '😀 ${localizations.translate('mood_very_happy')}';
      default:
        return '';
    }
  }

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
        return Colors.white;
    }
  }
}

class ScannerMaskPainter extends CustomPainter {
  final double progress;
  final double laserOffset;
  final bool isComplete;
  final bool drawDigitalSimulation;

  ScannerMaskPainter({
    required this.progress,
    required this.laserOffset,
    required this.isComplete,
    required this.drawDigitalSimulation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 40);
    final radius = min(size.width * 0.38, 160.0);

    // 1. Draw dark background mask outside the circle
    final maskPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, maskPaint);

    // 2. Draw border circle
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = isComplete ? Colors.green.shade400 : Colors.cyan.shade400;
    canvas.drawCircle(center, radius, borderPaint);

    // Draw digital simulation head outline if drawDigitalSimulation is true
    if (drawDigitalSimulation) {
      final headPaint = Paint()
        ..color = (isComplete ? Colors.green : Colors.cyan).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Draw head oval
      canvas.drawOval(
        Rect.fromCenter(center: center, width: radius * 1.1, height: radius * 1.4),
        headPaint,
      );

      // Draw ears
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx - radius * 0.55, center.dy), width: radius * 0.2, height: radius * 0.4),
        0.5 * pi,
        pi,
        false,
        headPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx + radius * 0.55, center.dy), width: radius * 0.2, height: radius * 0.4),
        -0.5 * pi,
        pi,
        false,
        headPaint,
      );

      // Draw eyes
      final eyePaint = Paint()
        ..color = (isComplete ? Colors.green : Colors.cyan).withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.dx - radius * 0.22, center.dy - radius * 0.2), 6.0, eyePaint);
      canvas.drawCircle(Offset(center.dx + radius * 0.22, center.dy - radius * 0.2), 6.0, eyePaint);

      // Draw nose
      final nosePath = Path()
        ..moveTo(center.dx, center.dy - radius * 0.05)
        ..lineTo(center.dx - radius * 0.08, center.dy + radius * 0.15)
        ..lineTo(center.dx + radius * 0.08, center.dy + radius * 0.15)
        ..close();
      canvas.drawPath(nosePath, headPaint);

      // Draw mouth
      final mouthPath = Path();
      if (isComplete) {
        mouthPath.moveTo(center.dx - radius * 0.2, center.dy + radius * 0.35);
        mouthPath.quadraticBezierTo(
          center.dx,
          center.dy + radius * 0.45,
          center.dx + radius * 0.2,
          center.dy + radius * 0.35,
        );
      } else {
        mouthPath.moveTo(center.dx - radius * 0.18, center.dy + radius * 0.38);
        mouthPath.lineTo(center.dx + radius * 0.18, center.dy + radius * 0.38);
      }
      canvas.drawPath(mouthPath, headPaint);

      // Draw biometric target dots
      final dotPaint = Paint()..color = Colors.cyan.withValues(alpha: 0.6);
      canvas.drawCircle(Offset(center.dx - radius * 0.55, center.dy - radius * 0.6), 3.0, dotPaint);
      canvas.drawCircle(Offset(center.dx + radius * 0.55, center.dy - radius * 0.6), 3.0, dotPaint);
      canvas.drawCircle(Offset(center.dx - radius * 0.55, center.dy + radius * 0.6), 3.0, dotPaint);
      canvas.drawCircle(Offset(center.dx + radius * 0.55, center.dy + radius * 0.6), 3.0, dotPaint);

      // Draw target corners
      final cornerPaint = Paint()
        ..color = Colors.cyan.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final double l = 15.0;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx - radius * 0.7, center.dy - radius * 0.7 + l)
          ..lineTo(center.dx - radius * 0.7, center.dy - radius * 0.7)
          ..lineTo(center.dx - radius * 0.7 + l, center.dy - radius * 0.7),
        cornerPaint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(center.dx + radius * 0.7 - l, center.dy - radius * 0.7)
          ..lineTo(center.dx + radius * 0.7, center.dy - radius * 0.7)
          ..lineTo(center.dx + radius * 0.7, center.dy - radius * 0.7 + l),
        cornerPaint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(center.dx - radius * 0.7, center.dy + radius * 0.7 - l)
          ..lineTo(center.dx - radius * 0.7, center.dy + radius * 0.7)
          ..lineTo(center.dx - radius * 0.7 + l, center.dy + radius * 0.7),
        cornerPaint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(center.dx + radius * 0.7 - l, center.dy + radius * 0.7)
          ..lineTo(center.dx + radius * 0.7, center.dy + radius * 0.7)
          ..lineTo(center.dx + radius * 0.7, center.dy + radius * 0.7 - l),
        cornerPaint,
      );

      // Draw concentric radar lines
      final radarPaint = Paint()
        ..color = Colors.cyan.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, radius * 0.5, radarPaint);
      canvas.drawCircle(center, radius * 0.75, radarPaint);
    }

    // 3. Draw scanning laser line
    if (!isComplete) {
      final double laserY = center.dy - radius + (2 * radius * laserOffset);
      final double halfWidth = sqrt(pow(radius, 2) - pow(laserY - center.dy, 2));

      final laserPaint = Paint()
        ..color = Colors.cyan.shade300
        ..strokeWidth = 3.0
        ..shader = LinearGradient(
          colors: [
            Colors.cyan.shade300.withValues(alpha: 0.0),
            Colors.cyan.shade300,
            Colors.cyan.shade300.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTRB(center.dx - halfWidth, laserY, center.dx + halfWidth, laserY));

      canvas.drawLine(
        Offset(center.dx - halfWidth, laserY),
        Offset(center.dx + halfWidth, laserY),
        laserPaint,
      );

      // Draw light scan glow
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.cyan.withValues(alpha: 0.15),
            Colors.cyan.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTRB(center.dx - halfWidth, center.dy - radius, center.dx + halfWidth, laserY));

      final glowPath = Path()
        ..moveTo(center.dx - halfWidth, laserY)
        ..lineTo(center.dx + halfWidth, laserY)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          acos((laserY - center.dy) / radius),
          -acos((laserY - center.dy) / radius) * 2,
          false,
        )
        ..close();

      canvas.drawPath(glowPath, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ScannerMaskPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.laserOffset != laserOffset ||
        oldDelegate.isComplete != isComplete;
  }
}
