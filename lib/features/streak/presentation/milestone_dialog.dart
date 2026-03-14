import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
    final badgeKey = GlobalKey();

    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: badgeKey,
                child: Container(
                  color: cs.surface,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      const SizedBox(height: 12),
                      Text(
                        'EiraFocus',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withAlpha(60),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('Awesome!'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => _shareBadge(ctx, badgeKey, days),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.share_rounded, size: 15),
                label: const Text('Share Badge'),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _shareBadge(BuildContext context, GlobalKey key, int days) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Badge not ready');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to encode badge');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/eirafocus_streak_$days.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'I just hit a $days day streak on EiraFocus!',
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sharing is not available on this device')),
        );
      }
    }
  }

  static List<int> getAchievedMilestones(int currentStreak) {
    return milestones.where((m) => currentStreak >= m).toList();
  }
}
