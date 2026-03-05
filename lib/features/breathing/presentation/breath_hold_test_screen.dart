import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eirafocus/core/data/database_helper.dart';
import 'package:eirafocus/features/meditation/domain/meditation_models.dart';

class BreathHoldTestScreen extends StatefulWidget {
  const BreathHoldTestScreen({super.key});

  @override
  State<BreathHoldTestScreen> createState() => _BreathHoldTestScreenState();
}

class _BreathHoldTestScreenState extends State<BreathHoldTestScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  bool _isHolding = false;
  bool _testStarted = false;
  int _resultSeconds = 0;

  void _toggleTest() {
    setState(() {
      if (!_testStarted) {
        _testStarted = true;
        _isHolding = true;
        _stopwatch.reset();
        _stopwatch.start();
        _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
          if (mounted) setState(() {});
        });
      } else if (_isHolding) {
        _stopwatch.stop();
        _isHolding = false;
        _resultSeconds = _stopwatch.elapsed.inSeconds;
        _timer?.cancel();
        _saveResult();
      } else {
        _stopwatch.reset();
        _testStarted = false;
        _resultSeconds = 0;
      }
    });
  }

  Future<void> _saveResult() async {
    if (_resultSeconds > 0) {
      await DatabaseHelper.instance.insertSession(MeditationSession(
        type: 'Breathing',
        method: 'Breath Hold Test',
        durationSeconds: _resultSeconds,
        timestamp: DateTime.now(),
      ));
    }
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Breath Hold Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_testStarted) ...[
                Icon(Icons.info_outline_rounded,
                    size: 28, color: cs.onSurface.withAlpha(80)),
                const SizedBox(height: 12),
                Text(
                  'Stop if you feel dizzy or lightheaded.\nNever practice in water.',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 48),
              ],

              // Timer display
              Text(
                _formatTime(_stopwatch.elapsed),
                style: GoogleFonts.inter(
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  color: _isHolding ? cs.primary : cs.onSurface,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _isHolding ? 'Holding...' : (_testStarted ? 'Done' : 'Tap to start'),
                  key: ValueKey('$_isHolding-$_testStarted'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: cs.onSurface.withAlpha(100),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Big button
              GestureDetector(
                onTap: _toggleTest,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: _isHolding ? 140 : 130,
                  height: _isHolding ? 140 : 130,
                  decoration: BoxDecoration(
                    color: _isHolding ? const Color(0xFFEF5350) : cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _isHolding ? 'Stop' : (_testStarted ? 'Retry' : 'Start'),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              if (_testStarted && !_isHolding) ...[
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withAlpha(40)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: cs.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '$_resultSeconds seconds  ·  Saved',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
