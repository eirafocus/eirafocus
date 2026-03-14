import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/features/breathing/domain/breathing_method.dart';
import 'package:eirafocus/features/breathing/presentation/breathing_session_screen.dart';
import 'package:eirafocus/features/breathing/presentation/breath_hold_test_screen.dart';
import 'package:eirafocus/features/breathing/presentation/custom_breathing_screen.dart';
import 'package:eirafocus/core/data/database_helper.dart';
import 'package:eirafocus/features/meditation/domain/meditation_models.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> {
  late Future<List<Map<String, dynamic>>> _customMethodsFuture;
  List<String> _favorites = [];

  @override
  void initState() {
    super.initState();
    _refreshCustomMethods();
    _loadFavorites();
  }

  void _refreshCustomMethods() {
    setState(() {
      _customMethodsFuture = DatabaseHelper.instance.getCustomMethods();
    });
  }

  Future<void> _loadFavorites() async {
    final favs = await DatabaseHelper.instance.getFavorites();
    if (mounted) setState(() => _favorites = favs);
  }

  Future<void> _toggleFavorite(String name) async {
    if (_favorites.contains(name)) {
      await DatabaseHelper.instance.removeFavorite(name);
    } else {
      await DatabaseHelper.instance.insertFavorite(name);
    }
    await _loadFavorites();
  }

  List<BreathingMethod> get _favoriteMethods {
    return BreathingMethod.predefinedMethods
        .where((m) => _favorites.contains(m.name))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Breathing')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          // Breath hold test card
          _buildBreathHoldCard(context),

          // Favorites section
          if (_favoriteMethods.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('Favorites', style: tt.headlineMedium),
            const SizedBox(height: 12),
            ..._favoriteMethods.map((m) => _buildMethodTile(context, m)),
          ],

          const SizedBox(height: 28),

          // Section: Techniques
          Text('Techniques', style: tt.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Choose a breathing pattern to begin',
            style: tt.bodySmall,
          ),
          const SizedBox(height: 16),
          ...BreathingMethod.predefinedMethods
              .map((m) => _buildMethodTile(context, m)),

          const SizedBox(height: 28),

          // Section: Custom
          Row(
            children: [
              Expanded(child: Text('Custom', style: tt.headlineMedium)),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    EiraTheme.smoothRoute(const CustomBreathingScreen()),
                  );
                  if (result == true) _refreshCustomMethods();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 18, color: cs.primary),
                      const SizedBox(width: 4),
                      Text('Create',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _customMethodsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final methods = snapshot.data ?? [];
              if (methods.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outline.withAlpha(80)),
                  ),
                  child: Center(
                    child: Text(
                      'Create your own breathing pattern',
                      style: tt.bodySmall,
                    ),
                  ),
                );
              }
              return Column(
                children: methods.map((m) => _buildCustomTile(context, m)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDurationPicker(BuildContext context, BreathingMethod method) {
    final cs = Theme.of(context).colorScheme;
    int? selectedMinutes;
    int? moodBefore;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withAlpha(40),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(method.name,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _BreathingPreview(method: method),
                  const SizedBox(height: 16),
                  Text('How are you feeling?',
                      style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withAlpha(100))),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) {
                      final selected = moodBefore == i + 1;
                      final moodColor = MoodData.moodColors[i];
                      final moodIcons = [
                        Icons.sentiment_very_dissatisfied_rounded,
                        Icons.sentiment_dissatisfied_rounded,
                        Icons.sentiment_neutral_rounded,
                        Icons.sentiment_satisfied_rounded,
                        Icons.sentiment_very_satisfied_rounded,
                      ];
                      return GestureDetector(
                        onTap: () => setSheetState(() => moodBefore = i + 1),
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: selected ? moodColor.withAlpha(25) : Colors.transparent,
                                shape: BoxShape.circle,
                                border: selected ? Border.all(color: moodColor.withAlpha(120), width: 2) : null,
                              ),
                              child: Icon(moodIcons[i], size: selected ? 26 : 22, color: selected ? moodColor : cs.onSurface.withAlpha(80)),
                            ),
                            const SizedBox(height: 2),
                            Text(MoodData.labels[i], style: GoogleFonts.inter(fontSize: 10, color: selected ? moodColor : cs.onSurface.withAlpha(80))),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Text('Set a target duration',
                      style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withAlpha(100))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [null, 3, 5, 10, 15, 20, 30].map((m) {
                      final selected = selectedMinutes == m;
                      final label = m == null ? 'Free' : '$m min';
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedMinutes = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? cs.primary.withAlpha(20) : cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? cs.primary.withAlpha(100) : cs.outline.withAlpha(80),
                            ),
                          ),
                          child: Text(
                            label,
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          EiraTheme.smoothRoute(BreathingSessionScreen(
                            method: method,
                            targetMinutes: selectedMinutes,
                            moodBefore: moodBefore,
                          )),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EiraTheme.breathingColor,
                      ),
                      child: Text(
                        selectedMinutes != null ? 'Start  ·  $selectedMinutes min' : 'Start  ·  Free',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBreathHoldCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        EiraTheme.smoothRoute(const BreathHoldTestScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EiraTheme.breathingColor,
              EiraTheme.breathingColor.withAlpha(200),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.timer_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Breath Hold Test',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 2),
                  Text('Test your breath retention',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withAlpha(200),
                      )),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withAlpha(180)),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile(BuildContext context, BreathingMethod method) {
    final cs = Theme.of(context).colorScheme;
    final isFav = _favorites.contains(method.name);

    final parts = <String>[
      '${method.inhaleDuration}s in',
    ];
    if (method.holdDuration > 0) parts.add('${method.holdDuration}s hold');
    parts.add('${method.exhaleDuration}s out');
    if (method.holdAfterExhaleDuration > 0) parts.add('${method.holdAfterExhaleDuration}s hold');
    final pattern = parts.join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _showDurationPicker(context, method),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outline.withAlpha(80)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: EiraTheme.breathingColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.air_rounded, color: EiraTheme.breathingColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      pattern,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cs.onSurface.withAlpha(100),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleFavorite(method.name),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? const Color(0xFFEF5350) : cs.onSurface.withAlpha(60),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.play_circle_filled_rounded,
                  color: EiraTheme.breathingColor, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTile(BuildContext context, Map<String, dynamic> m) {
    final cs = Theme.of(context).colorScheme;
    final method = BreathingMethod(
      name: m['name'],
      description: '',
      inhaleDuration: m['inhale'],
      holdDuration: m['hold_after_inhale'],
      exhaleDuration: m['exhale'],
      holdAfterExhaleDuration: m['hold_after_exhale'],
    );
    final pattern =
        '${m['inhale']}s · ${m['hold_after_inhale']}s · ${m['exhale']}s · ${m['hold_after_exhale']}s';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _showDurationPicker(context, method),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outline.withAlpha(80)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['name'] as String,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(pattern,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(100),
                        )),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: cs.onSurface.withAlpha(80)),
                onPressed: () async {
                  await DatabaseHelper.instance.deleteCustomMethod(m['id']);
                  _refreshCustomMethods();
                },
              ),
              Icon(Icons.play_circle_filled_rounded,
                  color: EiraTheme.breathingColor, size: 28),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Breathing Pattern Preview ─────────────────────────────────
class _BreathingPreview extends StatefulWidget {
  final BreathingMethod method;
  const _BreathingPreview({required this.method});

  @override
  State<_BreathingPreview> createState() => _BreathingPreviewState();
}

class _BreathingPreviewState extends State<_BreathingPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    final m = widget.method;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: m.totalDurationPerCycle),
    )..repeat();

    final items = <TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween(begin: 0.45, end: 1.0), weight: m.inhaleDuration.toDouble()),
      if (m.holdDuration > 0)
        TweenSequenceItem(tween: ConstantTween(1.0), weight: m.holdDuration.toDouble()),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.45), weight: m.exhaleDuration.toDouble()),
      if (m.holdAfterExhaleDuration > 0)
        TweenSequenceItem(tween: ConstantTween(0.45), weight: m.holdAfterExhaleDuration.toDouble()),
    ];
    _anim = TweenSequence(items).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _phaseLabel {
    final m = widget.method;
    final elapsed = _ctrl.value * m.totalDurationPerCycle;
    double t = 0;
    if (elapsed < (t += m.inhaleDuration)) return 'Inhale';
    if (m.holdDuration > 0 && elapsed < (t += m.holdDuration)) return 'Hold';
    if (elapsed < (t += m.exhaleDuration)) return 'Exhale';
    return 'Hold';
  }

  @override
  Widget build(BuildContext context) {
    final color = EiraTheme.breathingColor;
    final cs = Theme.of(context).colorScheme;
    final m = widget.method;
    final total = m.totalDurationPerCycle;

    // Phase segments: [label, seconds, color]
    final phases = <(String, int, Color)>[
      ('Inhale', m.inhaleDuration, color),
      if (m.holdDuration > 0) ('Hold', m.holdDuration, const Color(0xFFFFB300)),
      ('Exhale', m.exhaleDuration, const Color(0xFF42A5F5)),
      if (m.holdAfterExhaleDuration > 0) ('Hold', m.holdAfterExhaleDuration, const Color(0xFFFFB300)),
    ];

    return Column(
      children: [
        // Animated circle
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            return Column(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Center(
                    child: Container(
                      width: 72 * _anim.value,
                      height: 72 * _anim.value,
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withAlpha(120), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _phaseLabel,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        // Segmented timing bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: phases.map((p) {
              return Expanded(
                flex: p.$2,
                child: Container(
                  height: 6,
                  color: p.$3.withAlpha(160),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        // Phase labels
        Row(
          children: phases.map((p) {
            return Expanded(
              flex: p.$2,
              child: Column(
                children: [
                  Text(p.$1, style: GoogleFonts.inter(fontSize: 9, color: cs.onSurface.withAlpha(100)), textAlign: TextAlign.center),
                  Text('${p.$2}s', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: cs.onSurface.withAlpha(140)), textAlign: TextAlign.center),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
