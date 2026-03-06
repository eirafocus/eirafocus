import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/features/breathing/domain/breathing_method.dart';
import 'package:eirafocus/features/breathing/presentation/breathing_session_screen.dart';
import 'package:eirafocus/features/breathing/presentation/breath_hold_test_screen.dart';
import 'package:eirafocus/features/breathing/presentation/custom_breathing_screen.dart';
import 'package:eirafocus/core/data/database_helper.dart';

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
        onTap: () => Navigator.of(context).push(
          EiraTheme.smoothRoute(BreathingSessionScreen(method: method)),
        ),
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
        onTap: () => Navigator.of(context).push(
          EiraTheme.smoothRoute(BreathingSessionScreen(method: method)),
        ),
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
