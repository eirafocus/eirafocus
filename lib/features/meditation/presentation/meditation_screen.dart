import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eirafocus/features/meditation/domain/meditation_models.dart';
import 'package:eirafocus/core/data/database_helper.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> with TickerProviderStateMixin {
  int _selectedMinutes = 5;
  int _secondsRemaining = 0;
  bool _isActive = false;
  Timer? _timer;
  String _currentPrompt = "Ready to begin?";
  int _elapsedSeconds = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Session Complete"),
        content: const Text("Well done. You've completed your mindfulness session."),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meditation"),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.blue.withOpacity(0.1),
              colorScheme.surface,
              colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isActive ? _buildActiveUI() : _buildSetupUI(),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupUI() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.self_improvement_rounded, size: 80, color: Colors.blue),
        ),
        const SizedBox(height: 48),
        const Text(
          "Set Duration",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 12),
        Text(
          "Choose how long you want to sit in silence.",
          style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.5)),
        ),
        const SizedBox(height: 40),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12.0,
          runSpacing: 12.0,
          children: [5, 10, 15, 20, 30, 45, 60].map((mins) {
            bool isSelected = _selectedMinutes == mins;
            return ChoiceChip(
              label: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text("$mins min", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              selected: isSelected,
              selectedColor: Colors.blue.withOpacity(0.2),
              onSelected: (selected) {
                if (selected) setState(() => _selectedMinutes = mins);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _startMeditation,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: Colors.blue.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("START SESSION", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveUI() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 280 * _pulseAnimation.value,
              height: 280 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.withOpacity(0.2), width: 2),
              ),
              child: Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _formatTime(_secondsRemaining),
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 64),
        SizedBox(
          height: 80,
          child: AnimatedSwitcher(
            duration: const Duration(seconds: 1),
            child: Text(
              _currentPrompt,
              key: ValueKey(_currentPrompt),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.redAccent.withOpacity(0.1),
            border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
          ),
          child: IconButton(
            onPressed: _stopMeditation,
            icon: const Icon(Icons.stop_rounded),
            iconSize: 48,
            color: Colors.redAccent,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
