import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/features/meditation/domain/meditation_journey.dart';
import 'package:eirafocus/features/meditation/presentation/meditation_screen.dart';

class MeditationSelectionScreen extends StatelessWidget {
  const MeditationSelectionScreen({super.key});

  static const _journeyIcons = [
    Icons.accessibility_new_rounded, // Body Scan
    Icons.favorite_rounded, // Loving-Kindness
    Icons.graphic_eq_rounded, // Mantra
    Icons.visibility_rounded, // Vipassana
  ];

  static const _journeyColors = [
    Color(0xFF2E7D32), // Body Scan - deep emerald
    Color(0xFF00897B), // Loving-Kindness - teal
    Color(0xFF43A047), // Mantra - leaf green
    Color(0xFF1B5E20), // Vipassana - forest
  ];

  static const _journeyDurations = ['10 min', '5 min', '5 min', '10 min'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Meditation')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          // Silent timer - featured card
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              EiraTheme.smoothRoute(const MeditationScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    EiraTheme.meditationColor,
                    EiraTheme.meditationColor.withAlpha(200),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.timer_outlined, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Silent Timer',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )),
                        const SizedBox(height: 3),
                        Text('Set your own duration with gentle prompts',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withAlpha(190),
                            )),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withAlpha(160)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Section header
          Text('Guided Journeys', style: tt.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Follow along with timed prompts',
            style: tt.bodySmall,
          ),
          const SizedBox(height: 16),

          // Journey cards
          ...MeditationJourney.journeys.asMap().entries.map((entry) {
            final i = entry.key;
            final j = entry.value;
            return _buildJourneyTile(
              context,
              title: j.name,
              description: j.description,
              icon: _journeyIcons[i % _journeyIcons.length],
              color: _journeyColors[i % _journeyColors.length],
              duration: _journeyDurations[i % _journeyDurations.length],
              onTap: () => Navigator.of(context).push(
                EiraTheme.smoothRoute(MeditationScreen(journey: j)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildJourneyTile(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String duration,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withAlpha(22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cs.onSurface.withAlpha(100),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  duration,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
