import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eirafocus/core/data/database_helper.dart';
import 'package:eirafocus/features/meditation/domain/meditation_models.dart';

class BreathHoldTestScreen extends StatefulWidget {
  const BreathHoldTestScreen({super.key});

  @override
  State<BreathHoldTestScreen> createState() => _BreathHoldTestScreenState();
}

class _BreathHoldTestScreenState extends State<BreathHoldTestScreen> {
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  bool _isHolding = false;
  bool _testStarted = false;
  int _resultSeconds = 0;

  void _toggleTest() {
    setState(() {
      if (!_testStarted) {
        _testStarted = true;
        _isHolding = true;
        _stopwatch.start();
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          setState(() {});
        });
      } else if (_isHolding) {
        _stopwatch.stop();
        _isHolding = false;
        _resultSeconds = _stopwatch.elapsed.inSeconds;
        _timer?.cancel();
        _saveResult();
      } else {
        // Reset
        _stopwatch.reset();
        _testStarted = false;
        _resultSeconds = 0;
      }
    });
  }

  Future<void> _saveResult() async {
    if (_resultSeconds > 0) {
      await DatabaseHelper.instance.insertSession(
        MeditationSession(
          type: 'Breathing',
          method: 'Breath Hold Test',
          durationSeconds: _resultSeconds,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Breath Hold Test')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!_testStarted) ...[
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Safety First',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Never practice breath holding in water or while driving. Stop immediately if you feel dizzy or lightheaded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 48),
              ],
              Text(
                _formatTime(_stopwatch.elapsed),
                style: TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.w200,
                  color: _isHolding ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isHolding ? 'HOLDING...' : (_testStarted ? 'TEST COMPLETE' : 'READY?'),
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: _isHolding ? colorScheme.primary : Colors.grey,
                ),
              ),
              const SizedBox(height: 64),
              SizedBox(
                width: 200,
                height: 200,
                child: ElevatedButton(
                  onPressed: _toggleTest,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: _isHolding 
                        ? Colors.redAccent.withOpacity(0.8) 
                        : colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _isHolding ? 'STOP' : (_testStarted ? 'RETRY' : 'START'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (_testStarted && !_isHolding) ...[
                const SizedBox(height: 32),
                Text(
                  'Result: $_resultSeconds seconds',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text('Saved to your history', style: TextStyle(color: Colors.green)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
