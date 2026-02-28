import 'package:flutter/material.dart';
import 'package:eirafocus/features/meditation/domain/meditation_journey.dart';
import 'package:eirafocus/features/meditation/presentation/meditation_screen.dart';

class MeditationSelectionScreen extends StatelessWidget {
  const MeditationSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Meditation')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildJourneyCard(
            context,
            'Silent Timer',
            'Meditate in silence with periodic prompts.',
            Icons.timer_outlined,
            Colors.blue,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MeditationScreen()),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Guided Journeys',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          ...MeditationJourney.journeys.map((journey) => _buildJourneyCard(
                context,
                journey.name,
                journey.description,
                Icons.auto_awesome_rounded,
                colorScheme.primary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MeditationScreen(journey: journey),
                    ),
                  );
                },
              )),
        ],
      ),
    );
  }

  Widget _buildJourneyCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            description,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
