import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eirafocus/features/meditation/domain/meditation_models.dart';
import 'package:eirafocus/core/data/database_helper.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  int _selectedMinutes = 5;
  int _secondsRemaining = 0;
  bool _isActive = false;
  Timer? _timer;
  String _currentPrompt = "Ready to begin?";
  int _elapsedSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMeditation() {
    setState(() {
      _isActive = true;
      _secondsRemaining = _selectedMinutes * 60;
      _elapsedSeconds = 0;
      _updatePrompt();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
          _elapsedSeconds++;
          _updatePrompt();
        });
      } else {
        _finishMeditation();
      }
    });
  }

  void _updatePrompt() {
    for (var prompt in MeditationPrompt.defaultPrompts.reversed) {
      if (_elapsedSeconds >= prompt.interval.inSeconds) {
        if (_currentPrompt != prompt.text) {
          setState(() {
            _currentPrompt = prompt.text;
          });
        }
        break;
      }
    }
  }

  void _finishMeditation() {
    _timer?.cancel();
    DatabaseHelper.instance.insertSession(
      MeditationSession(
        type: 'Meditation',
        method: 'Silent Timer',
        durationSeconds: _selectedMinutes * 60,
        timestamp: DateTime.now(),
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Session Complete"),
        content: const Text("Well done. You've completed your meditation session."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to dashboard
            },
            child: const Text("FINISH"),
          ),
        ],
      ),
    );

    setState(() {
      _isActive = false;
    });
  }

  void _stopMeditation() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _currentPrompt = "Session stopped.";
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meditation")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isActive ? _buildActiveUI() : _buildSetupUI(),
        ),
      ),
    );
  }

  Widget _buildSetupUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.self_improvement, size: 80, color: Colors.blue),
        const SizedBox(height: 32),
        const Text(
          "Set Duration",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8.0,
          runSpacing: 8.0,
          children: [5, 10, 15, 20, 30, 45, 60].map((mins) {
            bool isSelected = _selectedMinutes == mins;
            return ChoiceChip(
              label: Text("$mins min"),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedMinutes = mins);
              },
            );
          }).toList(),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startMeditation,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("START SESSION", style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveUI() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatTime(_secondsRemaining),
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w200,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 48),
        AnimatedSwitcher(
          duration: const Duration(seconds: 1),
          child: Text(
            _currentPrompt,
            key: ValueKey(_currentPrompt),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _stopMeditation,
          icon: const Icon(Icons.stop_circle, size: 80, color: Colors.redAccent),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
