import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eirafocus/features/breathing/domain/breathing_method.dart';
import 'package:eirafocus/features/meditation/domain/meditation_models.dart';
import 'package:eirafocus/core/data/database_helper.dart';

class BreathingSessionScreen extends StatefulWidget {
  final BreathingMethod method;

  const BreathingSessionScreen({super.key, required this.method});

  @override
  State<BreathingSessionScreen> createState() => _BreathingSessionScreenState();
}

class _BreathingSessionScreenState extends State<BreathingSessionScreen> with TickerProviderStateMixin {
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;
  late AnimationController _opacityController;
  late Animation<double> _opacityAnimation;

  Timer? _timer;
  int _secondsRemaining = 0;
  int _currentCycle = 0;
  BreathingStage _currentStage = BreathingStage.inhale;
  String _instructionText = 'Get Ready...';
  bool _isPaused = false;
  DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _circleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.method.inhaleDuration),
    );

    _circleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );

    _opacityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _opacityController, curve: Curves.easeInOut),
    );

    _startSession();
  }

  void _startSession() {
    _opacityController.forward();
    _runBreathingCycle();
  }

  void _runBreathingCycle() {
    if (_isPaused) return;

    setState(() {
      _currentStage = BreathingStage.inhale;
      _instructionText = 'Inhale';
    });

    _circleController.duration = Duration(seconds: widget.method.inhaleDuration);
    _circleController.forward();

    _timer = Timer(Duration(seconds: widget.method.inhaleDuration), () {
      if (_isPaused) return;
      _runHoldStage();
    });
  }

  void _runHoldStage() {
    if (widget.method.holdDuration > 0) {
      setState(() {
        _currentStage = BreathingStage.hold;
        _instructionText = 'Hold';
      });

      _timer = Timer(Duration(seconds: widget.method.holdDuration), () {
        if (_isPaused) return;
        _runExhaleStage();
      });
    } else {
      _runExhaleStage();
    }
  }

  void _runExhaleStage() {
    setState(() {
      _currentStage = BreathingStage.exhale;
      _instructionText = 'Exhale';
    });

    _circleController.duration = Duration(seconds: widget.method.exhaleDuration);
    _circleController.reverse();

    _timer = Timer(Duration(seconds: widget.method.exhaleDuration), () {
      if (_isPaused) return;
      _runHoldAfterExhaleStage();
    });
  }

  void _runHoldAfterExhaleStage() {
    if (widget.method.holdAfterExhaleDuration > 0) {
      setState(() {
        _currentStage = BreathingStage.holdAfterExhale;
        _instructionText = 'Hold';
      });

      _timer = Timer(Duration(seconds: widget.method.holdAfterExhaleDuration), () {
        if (_isPaused) return;
        _currentCycle++;
        _runBreathingCycle();
      });
    } else {
      _currentCycle++;
      _runBreathingCycle();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _circleController.dispose();
    _opacityController.dispose();
    super.dispose();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _timer?.cancel();
        _circleController.stop();
      } else {
        _resumeStage();
      }
    });
  }

  void _resumeStage() {
    switch (_currentStage) {
      case BreathingStage.inhale:
        _circleController.forward();
        _timer = Timer(Duration(seconds: widget.method.inhaleDuration), _runHoldStage);
        break;
      case BreathingStage.hold:
        _timer = Timer(Duration(seconds: widget.method.holdDuration), _runExhaleStage);
        break;
      case BreathingStage.exhale:
        _circleController.reverse();
        _timer = Timer(Duration(seconds: widget.method.exhaleDuration), _runHoldAfterExhaleStage);
        break;
      case BreathingStage.holdAfterExhale:
        _timer = Timer(Duration(seconds: widget.method.holdAfterExhaleDuration), () {
          _currentCycle++;
          _runBreathingCycle();
        });
        break;
    }
  }

  void _stopAndSave() {
    final durationSeconds = DateTime.now().difference(_startTime).inSeconds;
    if (durationSeconds > 10) {
      DatabaseHelper.instance.insertSession(
        MeditationSession(
          type: 'Breathing',
          method: widget.method.name,
          durationSeconds: durationSeconds,
          timestamp: DateTime.now(),
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.method.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _stopAndSave,
        ),
      ),
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Cycle $_currentCycle',
                style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 48),
              AnimatedBuilder(
                animation: _circleAnimation,
                builder: (context, child) {
                  return Container(
                    width: 250 * _circleAnimation.value,
                    height: 250 * _circleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withOpacity(0.3),
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _instructionText,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 64),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _togglePause,
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    iconSize: 48,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    onPressed: _stopAndSave,
                    icon: const Icon(Icons.stop),
                    iconSize: 48,
                    color: Colors.red.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
