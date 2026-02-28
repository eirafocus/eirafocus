import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:eirafocus/features/meditation/domain/meditation_models.dart';
import 'package:eirafocus/features/meditation/domain/meditation_journey.dart';
import 'package:eirafocus/core/data/database_helper.dart';

class MeditationScreen extends StatefulWidget {
  final MeditationJourney? journey;
  final int? initialMinutes;

  const MeditationScreen({super.key, this.journey, this.initialMinutes});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> with TickerProviderStateMixin {
  late int _selectedMinutes;
  int _secondsRemaining = 0;
  bool _isActive = false;
  Timer? _timer;
  String _currentPrompt = "Ready to begin?";
  int _elapsedSeconds = 0;
  
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();
  bool _isAmbientOn = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.initialMinutes ?? 5;
    if (widget.journey != null) {
      _selectedMinutes = widget.journey!.totalDuration.inMinutes;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initTts();
    _setupAmbient();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(0.9); // Slightly deeper, calmer
    await _flutterTts.setSpeechRate(0.35); // Even slower for mindfulness
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _setupAmbient() async {
    _ambientPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _flutterTts.stop();
    _ambientPlayer.dispose();
    _bellPlayer.dispose();
    super.dispose();
  }

  void _startMeditation() async {
    setState(() {
      _isActive = true;
      _secondsRemaining = _selectedMinutes * 60;
      _elapsedSeconds = 0;
    });

    // Audio is wrapped in try-catch so failures don't freeze the timer
    try {
      await _bellPlayer.play(AssetSource('sounds/bell.mp3'));
    } catch (e) {
      debugPrint("Bell audio error: $e");
    }
    
    try {
      if (_isAmbientOn) {
        await _ambientPlayer.play(AssetSource('sounds/rain.mp3'), volume: 0.3);
      }
    } catch (e) {
      debugPrint("Ambient audio error: $e");
    }

    _updatePrompt(); // Call once at start

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
            _elapsedSeconds++;
          });
          _updatePrompt();
        }
      } else {
        _finishMeditation();
      }
    });
  }

  void _updatePrompt() {
    if (widget.journey != null) {
      for (var prompt in widget.journey!.prompts) {
        if (_elapsedSeconds == prompt.timestamp.inSeconds) {
          _speak(prompt.text);
          setState(() {
            _currentPrompt = prompt.text;
          });
          break;
        }
      }
    } else {
      for (var prompt in MeditationPrompt.defaultPrompts.reversed) {
        if (_elapsedSeconds >= prompt.interval.inSeconds) {
          if (_currentPrompt != prompt.text) {
            setState(() {
              _currentPrompt = prompt.text;
            });
            _speak(prompt.text);
          }
          break;
        }
      }
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _finishMeditation() async {
    _timer?.cancel();
    _ambientPlayer.stop();
    await _bellPlayer.play(AssetSource('sounds/bell.mp3'));

    DatabaseHelper.instance.insertSession(
      MeditationSession(
        type: 'Meditation',
        method: widget.journey?.name ?? 'Silent Timer',
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
    _flutterTts.stop();
    _ambientPlayer.stop();
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
        title: Text(widget.journey?.name ?? "Meditation"),
        backgroundColor: Colors.transparent,
        actions: [
          if (!_isActive)
            IconButton(
              onPressed: () => setState(() => _isAmbientOn = !_isAmbientOn),
              icon: Icon(_isAmbientOn ? Icons.water_drop_rounded : Icons.water_drop_outlined),
              color: _isAmbientOn ? Colors.blue : null,
              tooltip: 'Background Rain',
            ),
        ],
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
          child: Icon(
            widget.journey != null ? Icons.auto_awesome_rounded : Icons.self_improvement_rounded,
            size: 80,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 48),
        Text(
          widget.journey != null ? widget.journey!.name : "Set Duration",
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 12),
        Text(
          widget.journey != null ? widget.journey!.description : "Choose how long you want to sit in silence.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.5)),
        ),
        const SizedBox(height: 40),
        if (widget.journey == null)
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
          height: 120, // More height for longer guided prompts
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
