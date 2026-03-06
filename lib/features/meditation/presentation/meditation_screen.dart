import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/features/meditation/domain/meditation_models.dart';
import 'package:eirafocus/features/meditation/domain/meditation_journey.dart';
import 'package:eirafocus/core/data/database_helper.dart';
import 'package:eirafocus/core/services/audio_service.dart';

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
    AudioService.instance.stop();
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
    if (_selectedSound != 'None') {
      AudioService.instance.play(_selectedSound);
    }
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
    AudioService.instance.stop();
    Vibration.vibrate(duration: 400);
    setState(() => _isActive = false);
    _showJournalDialog();
  }

  void _showJournalDialog() {
    final controller = TextEditingController();
    final selectedTags = <String>{};
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final cs = Theme.of(ctx).colorScheme;
            return AlertDialog(
              title: const Text('Session Complete'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Well done! You meditated for $_selectedMinutes minutes.'),
                    const SizedBox(height: 16),
                    Text('Tags', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withAlpha(90))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: SessionTag.availableLabels.map((label) {
                        final selected = selectedTags.contains(label);
                        return GestureDetector(
                          onTap: () => setDialogState(() {
                            selected ? selectedTags.remove(label) : selectedTags.add(label);
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected ? cs.primary.withAlpha(20) : cs.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: selected ? cs.primary.withAlpha(80) : cs.outline.withAlpha(80)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(SessionTag.emojiFor(label), style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: selected ? cs.primary : cs.onSurface.withAlpha(120))),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'How do you feel? (optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    DatabaseHelper.instance.insertSession(MeditationSession(
                      type: 'Meditation',
                      method: widget.journey?.name ?? 'Silent Timer',
                      durationSeconds: _selectedMinutes * 60,
                      timestamp: DateTime.now(),
                      tags: selectedTags.toList(),
                    ));
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Text('Skip', style: TextStyle(color: cs.onSurface.withAlpha(120))),
                ),
                ElevatedButton(
                  onPressed: () {
                    final journal = controller.text.trim();
                    DatabaseHelper.instance.insertSession(MeditationSession(
                      type: 'Meditation',
                      method: widget.journey?.name ?? 'Silent Timer',
                      durationSeconds: _selectedMinutes * 60,
                      timestamp: DateTime.now(),
                      journal: journal.isEmpty ? null : journal,
                      tags: selectedTags.toList(),
                    ));
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _stopMeditation() {
    _timer?.cancel();
    AudioService.instance.stop();
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
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.music_note_rounded,
              color: _selectedSound != 'None'
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onSelected: (v) {
              setState(() => _selectedSound = v);
              if (_isActive) {
                if (v != 'None') {
                  AudioService.instance.play(v);
                } else {
                  AudioService.instance.stop();
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'None', child: Text('No Sound')),
              ...AudioService.availableSounds.map(
                (s) => PopupMenuItem(value: s, child: Text(s)),
              ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Pulsing timer circle
          Center(
            child: AnimatedBuilder(
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

          // Volume slider
          if (_selectedSound != 'None')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                children: [
                  Icon(Icons.volume_down_rounded, size: 18, color: cs.onSurface.withAlpha(80)),
                  Expanded(
                    child: Slider(
                      value: AudioService.instance.volume,
                      onChanged: (v) {
                        AudioService.instance.setVolume(v);
                        setState(() {});
                      },
                    ),
                  ),
                  Icon(Icons.volume_up_rounded, size: 18, color: cs.onSurface.withAlpha(80)),
                ],
              ),
            ),

          const Spacer(flex: 3),

          // Stop button
          Center(
            child: GestureDetector(
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
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
