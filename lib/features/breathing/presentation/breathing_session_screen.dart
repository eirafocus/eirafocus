import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/features/breathing/domain/breathing_method.dart';
import 'package:eirafocus/features/meditation/domain/meditation_models.dart';
import 'package:eirafocus/core/data/database_helper.dart';

class BreathingSessionScreen extends StatefulWidget {
  final BreathingMethod method;
  const BreathingSessionScreen({super.key, required this.method});

  @override
  State<BreathingSessionScreen> createState() => _BreathingSessionScreenState();
}

class _BreathingSessionScreenState extends State<BreathingSessionScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnim;
  late AnimationController _fadeController;

  Timer? _timer;
  int _currentCycle = 0;
  BreathingStage _currentStage = BreathingStage.inhale;
  String _instructionText = 'Get Ready';
  bool _isPaused = false;
  DateTime _startTime = DateTime.now();
  int _stageSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.method.inhaleDuration),
    );
    _breathAnim = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeController.forward();
    _startSession();
  }

  void _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 40);
    }
  }

  void _startSession() => _runBreathingCycle();

  void _runBreathingCycle() {
    if (_isPaused) return;
    setState(() {
      _currentStage = BreathingStage.inhale;
      _instructionText = 'Inhale';
      _stageSecondsLeft = widget.method.inhaleDuration;
    });
    _vibrate();
    _breathController.duration = Duration(seconds: widget.method.inhaleDuration);
    _breathController.forward(from: 0);
    _startCountdown(widget.method.inhaleDuration, _runHoldStage);
  }

  void _runHoldStage() {
    if (widget.method.holdDuration > 0) {
      setState(() {
        _currentStage = BreathingStage.hold;
        _instructionText = 'Hold';
        _stageSecondsLeft = widget.method.holdDuration;
      });
      _vibrate();
      _startCountdown(widget.method.holdDuration, _runExhaleStage);
    } else {
      _runExhaleStage();
    }
  }

  void _runExhaleStage() {
    setState(() {
      _currentStage = BreathingStage.exhale;
      _instructionText = 'Exhale';
      _stageSecondsLeft = widget.method.exhaleDuration;
    });
    _vibrate();
    _breathController.duration = Duration(seconds: widget.method.exhaleDuration);
    _breathController.reverse(from: 1);
    _startCountdown(widget.method.exhaleDuration, _runHoldAfterExhaleStage);
  }

  void _runHoldAfterExhaleStage() {
    if (widget.method.holdAfterExhaleDuration > 0) {
      setState(() {
        _currentStage = BreathingStage.holdAfterExhale;
        _instructionText = 'Hold';
        _stageSecondsLeft = widget.method.holdAfterExhaleDuration;
      });
      _vibrate();
      _startCountdown(widget.method.holdAfterExhaleDuration, () {
        _currentCycle++;
        _runBreathingCycle();
      });
    } else {
      _currentCycle++;
      _runBreathingCycle();
    }
  }

  void _startCountdown(int seconds, VoidCallback onDone) {
    _timer?.cancel();
    int remaining = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isPaused) {
        t.cancel();
        return;
      }
      remaining--;
      if (mounted) setState(() => _stageSecondsLeft = remaining);
      if (remaining <= 0) {
        t.cancel();
        onDone();
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _timer?.cancel();
        _breathController.stop();
      } else {
        _resumeStage();
      }
    });
  }

  void _resumeStage() {
    switch (_currentStage) {
      case BreathingStage.inhale:
        _breathController.forward();
        _startCountdown(_stageSecondsLeft, _runHoldStage);
        break;
      case BreathingStage.hold:
        _startCountdown(_stageSecondsLeft, _runExhaleStage);
        break;
      case BreathingStage.exhale:
        _breathController.reverse();
        _startCountdown(_stageSecondsLeft, _runHoldAfterExhaleStage);
        break;
      case BreathingStage.holdAfterExhale:
        _startCountdown(_stageSecondsLeft, () {
          _currentCycle++;
          _runBreathingCycle();
        });
        break;
    }
  }

  void _stopAndSave() {
    final duration = DateTime.now().difference(_startTime).inSeconds;
    if (duration > 10) {
      DatabaseHelper.instance.insertSession(MeditationSession(
        type: 'Breathing',
        method: widget.method.name,
        durationSeconds: duration,
        timestamp: DateTime.now(),
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.method.name),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _stopAndSave,
        ),
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Cycle count
            Text(
              'CYCLE ${_currentCycle + 1}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withAlpha(90),
                letterSpacing: 1.5,
              ),
            ),

            // Breathing circle
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _breathAnim,
                  builder: (context, _) => _buildBreathCircle(cs),
                ),
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ControlButton(
                    icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: cs.primary,
                    onTap: _togglePause,
                  ),
                  const SizedBox(width: 32),
                  _ControlButton(
                    icon: Icons.stop_rounded,
                    color: const Color(0xFFEF5350),
                    onTap: _stopAndSave,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathCircle(ColorScheme cs) {
    final size = 220 * _breathAnim.value;
    final outerSize = 280 * _breathAnim.value;

    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: outerSize,
            height: outerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.primary.withAlpha(30),
                width: 1.5,
              ),
            ),
          ),
          // Main circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withAlpha(20),
              border: Border.all(color: cs.primary.withAlpha(60), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _instructionText,
                    key: ValueKey(_instructionText),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_stageSecondsLeft',
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    color: cs.primary.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          shape: BoxShape.circle,
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
