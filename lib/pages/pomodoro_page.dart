import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/pomodoro_service.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});
  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late StreamSubscription<PomodoroState> _subscription;
  final PomodoroService _pomodoroService = PomodoroService();

  int _seconds = 25 * 60;
  int _durationMinutes = 25;
  bool _isRunning = false;

  final List<int> _presetDurations = [5, 15, 25, 45, 60];

  @override
  void initState() {
    super.initState();

    // First initialize the controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Get current state
    _seconds = _pomodoroService.seconds;
    _isRunning = _pomodoroService.isRunning;
    _durationMinutes = _pomodoroService.durationMinutes;

    if (_isRunning) {
      _pulseController.repeat(reverse: true);
    }

    // Listen to stream after initialization
    _subscription = _pomodoroService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _seconds = state.seconds;
          _isRunning = state.isRunning;
          _durationMinutes = state.durationMinutes;
        });

        if (state.isRunning) {
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  double get _progress {
    final total = _durationMinutes * 60;
    if (total == 0) return 0.0;
    return 1.0 - (_seconds / total);
  }

  @override
  Widget build(BuildContext context) {
    final min = (_seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (_seconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3460),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'pomodoroTitle'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F3460), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Timer Circle with Progress
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            final scale =
                                _isRunning
                                    ? 1.0 + (_pulseController.value * 0.02)
                                    : 1.0;
                            return Transform.scale(
                              scale: scale,
                              child: SizedBox(
                                width: 280,
                                height: 280,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Progress Ring
                                    CustomPaint(
                                      size: const Size(280, 280),
                                      painter: _ProgressRingPainter(
                                        progress: _progress,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.1),
                                        progressColor: const Color(0xFFE94560),
                                      ),
                                    ),
                                    // Timer Display
                                    Container(
                                      width: 240,
                                      height: 240,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(0xFF1A1A2E),
                                            const Color(0xFF16213E),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFE94560,
                                            ).withValues(alpha: 0.3),
                                            blurRadius: 30,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "$min:$sec",
                                            style: const TextStyle(
                                              fontSize: 56,
                                              fontWeight: FontWeight.w300,
                                              color: Colors.white,
                                              letterSpacing: 4,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _isRunning
                                                ? 'pomodoroFocusing'.tr()
                                                : 'pomodoroReady'.tr(),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withValues(
                                                alpha: 0.6,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),

                        // Control Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Reset Button
                            _buildControlButton(
                              icon: Icons.refresh_rounded,
                              onPressed: _pomodoroService.reset,
                              isPrimary: false,
                            ),
                            const SizedBox(width: 24),
                            // Play/Pause Button
                            _buildControlButton(
                              icon:
                                  _isRunning
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                              onPressed:
                                  _isRunning
                                      ? _pomodoroService.pause
                                      : _pomodoroService.start,
                              isPrimary: true,
                              size: 72,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Duration Selector
                        if (!_isRunning) ...[
                          Text(
                            'pomodoroSetDuration'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Preset Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                _presetDurations.map((duration) {
                                  final isSelected =
                                      _durationMinutes == duration;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: GestureDetector(
                                      onTap:
                                          () => _pomodoroService.setDuration(
                                            duration,
                                          ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? const Color(0xFFE94560)
                                                  : Colors.white.withValues(
                                                    alpha: 0.1,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? const Color(0xFFE94560)
                                                    : Colors.white.withValues(
                                                      alpha: 0.2,
                                                    ),
                                          ),
                                        ),
                                        child: Text(
                                          '$duration',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'pomodoroMinutesLabel'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                color: Colors.amber.withValues(alpha: 0.8),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'pomodoroDescription'.tr(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              isPrimary
                  ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE94560), Color(0xFFD63447)],
                  )
                  : null,
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.1),
          border:
              isPrimary
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow:
              isPrimary
                  ? [
                    BoxShadow(
                      color: const Color(0xFFE94560).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isPrimary ? size * 0.5 : size * 0.45,
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;

    // Background circle
    final bgPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
