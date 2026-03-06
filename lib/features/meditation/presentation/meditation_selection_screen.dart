import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/core/data/database_helper.dart';
import 'package:eirafocus/features/meditation/domain/meditation_journey.dart';
import 'package:eirafocus/features/meditation/presentation/meditation_screen.dart';
import 'package:eirafocus/features/meditation/presentation/custom_journey_screen.dart';

class MeditationSelectionScreen extends StatefulWidget {
  const MeditationSelectionScreen({super.key});

  @override
  State<MeditationSelectionScreen> createState() => _MeditationSelectionScreenState();
}

class _MeditationSelectionScreenState extends State<MeditationSelectionScreen> {
  List<MeditationJourney> _customJourneys = [];

  static const _journeyIcons = [
    Icons.accessibility_new_rounded,
    Icons.favorite_rounded,
    Icons.graphic_eq_rounded,
    Icons.visibility_rounded,
  ];

  static const _journeyColors = [
    Color(0xFF2E7D32),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFF1B5E20),
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomJourneys();
  }

  Future<void> _loadCustomJourneys() async {
    final journeys = await DatabaseHelper.instance.getCustomJourneys();
    if (mounted) setState(() => _customJourneys = journeys);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Meditation')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          // Silent timer
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

          // Guided Journeys
          Text('Guided Journeys', style: tt.headlineMedium),
          const SizedBox(height: 6),
          Text('Follow along with timed prompts', style: tt.bodySmall),
          const SizedBox(height: 16),

          ...MeditationJourney.journeys.asMap().entries.map((entry) {
            final i = entry.key;
            final j = entry.value;
            return _buildJourneyTile(
              context,
              title: j.name,
              description: j.description,
              icon: _journeyIcons[i % _journeyIcons.length],
              color: _journeyColors[i % _journeyColors.length],
              duration: '${j.totalDuration.inMinutes} min',
              onTap: () => Navigator.of(context).push(
                EiraTheme.smoothRoute(MeditationScreen(journey: j)),
              ),
            );
          }),

          const SizedBox(height: 28),

          // Custom Journeys
          Row(
            children: [
              Expanded(child: Text('Your Journeys', style: tt.headlineMedium)),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    EiraTheme.smoothRoute(const CustomJourneyScreen()),
                  );
                  if (result == true) _loadCustomJourneys();
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

          if (_customJourneys.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.withAlpha(80)),
              ),
              child: Center(
                child: Text(
                  'Create your own guided meditation journey',
                  style: tt.bodySmall,
                ),
              ),
            )
          else
            ..._customJourneys.map((j) => _buildCustomJourneyTile(context, j)),
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

  Widget _buildCustomJourneyTile(BuildContext context, MeditationJourney journey) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          EiraTheme.smoothRoute(MeditationScreen(journey: journey)),
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: EiraTheme.meditationColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    color: EiraTheme.meditationColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(journey.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${journey.totalDuration.inMinutes} min · ${journey.prompts.length} prompts',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cs.onSurface.withAlpha(100),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: cs.onSurface.withAlpha(80)),
                onPressed: () async {
                  if (journey.id != null) {
                    await DatabaseHelper.instance.deleteCustomJourney(journey.id!);
                    _loadCustomJourneys();
                  }
                },
              ),
              Icon(Icons.play_circle_filled_rounded,
                  color: EiraTheme.meditationColor, size: 28),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
