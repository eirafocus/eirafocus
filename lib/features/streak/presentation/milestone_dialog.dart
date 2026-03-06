import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MilestoneDialog {
  static const List<int> milestones = [3, 7, 14, 30, 60, 100];

  static int? checkMilestone(int streak) {
    if (milestones.contains(streak)) return streak;
    return null;
  }

  static IconData _iconForMilestone(int days) {
    if (days >= 100) return Icons.diamond_rounded;
    if (days >= 60) return Icons.workspace_premium_rounded;
    if (days >= 30) return Icons.emoji_events_rounded;
    if (days >= 14) return Icons.star_rounded;
    if (days >= 7) return Icons.local_fire_department_rounded;
    return Icons.bolt_rounded;
  }

  static String _messageForMilestone(int days) {
    if (days >= 100) return 'Legendary! 100 days of consistent practice!';
    if (days >= 60) return 'Incredible! 60 days of dedication!';
    if (days >= 30) return 'Amazing! A full month of mindfulness!';
    if (days >= 14) return 'Two weeks strong! Keep it going!';
    if (days >= 7) return 'One week streak! You\'re building a habit!';
    return '$days days in a row! Great start!';
  }

  static void show(BuildContext context, int days) {
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForMilestone(days),
                  size: 40,
                  color: const Color(0xFFFF7043),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '$days Day Streak!',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _messageForMilestone(days),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: cs.onSurface.withAlpha(140),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Awesome!'),
              ),
            ),
          ],
        );
      },
    );
  }

  static List<int> getAchievedMilestones(int currentStreak) {
    return milestones.where((m) => currentStreak >= m).toList();
  }
}
