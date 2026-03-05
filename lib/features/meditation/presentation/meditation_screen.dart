import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:eirafocus/core/theme/theme.dart';
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

class _MeditationScreenState extends State<MeditationScreen>
    with TickerProviderStateMixin {
  late int _selectedMinutes;
  int _secondsRemaining = 0;
  bool _isActive = false;
  Timer? _timer;
  String _currentPrompt = '';
  int _elapsedSeconds = 0;

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();
  String _selectedSound = 'None';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _fadeController;

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
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(0.9);
    await _flutterTts.setSpeechRate(0.35);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
    _flutterTts.stop();
    _ambientPlayer.dispose();
    _bellPlayer.dispose();
    super.dispose();
  }

  void _startMeditation() {
    setState(() {
      _isActive = true;
      _secondsRemaining = _selectedMinutes * 60;
      _elapsedSeconds = 0;
      _currentPrompt = widget.journey != null
          ? widget.journey!.prompts.first.text
          : 'Focus on your breath.';
    });
    _fadeController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
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
    Vibration.vibrate(duration: 80);
  }

  void _updatePrompt() {
    if (widget.journey != null) {
      for (var p in widget.journey!.prompts) {
        if (_elapsedSeconds == p.timestamp.inSeconds) {
          setState(() => _currentPrompt = p.text);
          break;
        }
      }
    } else {
      for (var p in MeditationPrompt.defaultPrompts.reversed) {
        if (_elapsedSeconds >= p.interval.inSeconds && _currentPrompt != p.text) {
          setState(() => _currentPrompt = p.text);
          break;
        }
      }
    }
  }

  void _finishMeditation() {
    _timer?.cancel();
    _ambientPlayer.stop();
    Vibration.vibrate(duration: 400);
    DatabaseHelper.instance.insertSession(MeditationSession(
      type: 'Meditation',
      method: widget.journey?.name ?? 'Silent Timer',
      durationSeconds: _selectedMinutes * 60,
      timestamp: DateTime.now(),
    ));
    _showCompletionDialog();
    setState(() => _isActive = false);
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Complete'),
        content: Text('Well done! You meditated for $_selectedMinutes minutes.'),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  void _stopMeditation() {
    _timer?.cancel();
    _flutterTts.stop();
    _ambientPlayer.stop();
    setState(() {
      _isActive = false;
      _currentPrompt = '';
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.journey?.name ?? 'Meditation'),
        actions: [
          if (!_isActive)
            PopupMenuButton<String>(
              icon: const Icon(Icons.music_note_rounded),
              onSelected: (v) => setState(() => _selectedSound = v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'None', child: Text('No Sound')),
                PopupMenuItem(value: 'Rain', child: Text('Soft Rain')),
                PopupMenuItem(value: 'Forest', child: Text('Forest')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: _isActive ? _buildActiveUI() : _buildSetupUI(),
        ),
      ),
    );
  }

  Widget _buildSetupUI() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        const Spacer(flex: 2),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: EiraTheme.meditationColor.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.journey != null ? Icons.auto_awesome_rounded : Icons.self_improvement_rounded,
            size: 40,
            color: EiraTheme.meditationColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          widget.journey?.name ?? 'Silent Timer',
          style: tt.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.journey?.description ?? 'Set a duration and meditate with gentle prompts',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(110)),
          ),
        ),

        if (_selectedSound != 'None') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_note_rounded, size: 15, color: cs.primary),
                const SizedBox(width: 6),
                Text(_selectedSound,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: cs.primary)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _selectedSound = 'None'),
                  child: Icon(Icons.close_rounded, size: 15, color: cs.primary),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),

        if (widget.journey == null) ...[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [5, 10, 15, 20, 30, 45, 60].map((m) {
              final selected = _selectedMinutes == m;
              return GestureDetector(
                onTap: () => setState(() => _selectedMinutes = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary.withAlpha(20) : cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? cs.primary.withAlpha(100) : cs.outline.withAlpha(80),
                    ),
                  ),
                  child: Text(
                    '$m min',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? cs.primary : cs.onSurface.withAlpha(150),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ] else
          const Spacer(),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _startMeditation,
            style: ElevatedButton.styleFrom(
              backgroundColor: EiraTheme.meditationColor,
            ),
            child: Text('Start  ·  $_selectedMinutes min'),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveUI() {
    final cs = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Pulsing timer circle
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) {
              final scale = _pulseAnim.value;
              return Container(
                width: 220 * scale,
                height: 220 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surface,
                  border: Border.all(color: cs.outline.withAlpha(80)),
                ),
                child: Center(
                  child: Text(
                    _formatTime(_secondsRemaining),
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: cs.onSurface,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // Prompt
          SizedBox(
            height: 80,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: Text(
                _currentPrompt,
                key: ValueKey(_currentPrompt),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: cs.onSurface.withAlpha(140),
                  height: 1.5,
                ),
              ),
            ),
          ),

          const Spacer(flex: 3),

          // Stop button
          GestureDetector(
            onTap: _stopMeditation,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withAlpha(18),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEF5350).withAlpha(50)),
              ),
              child: const Icon(Icons.stop_rounded, color: Color(0xFFEF5350), size: 28),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
