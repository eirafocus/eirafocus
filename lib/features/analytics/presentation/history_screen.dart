import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/core/data/database_helper.dart';
import 'package:eirafocus/features/meditation/domain/meditation_models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<MeditationSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = DatabaseHelper.instance.getSessions();
  }

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: FutureBuilder<List<MeditationSession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, size: 56, color: cs.onSurface.withAlpha(50)),
                    const SizedBox(height: 16),
                    Text('No sessions yet',
                        style: tt.titleLarge?.copyWith(color: cs.onSurface.withAlpha(120))),
                    const SizedBox(height: 8),
                    Text(
                      'Your completed sessions will show up here',
                      textAlign: TextAlign.center,
                      style: tt.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }

          // Group by date
          final Map<String, List<MeditationSession>> grouped = {};
          for (final s in sessions) {
            final key = DateFormat('MMM dd, yyyy').format(s.timestamp);
            grouped.putIfAbsent(key, () => []).add(s);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            itemCount: grouped.length,
            itemBuilder: (context, i) {
              final date = grouped.keys.elementAt(i);
              final items = grouped[date]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i > 0) const SizedBox(height: 20),
                  Text(
                    date,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withAlpha(90),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((s) => _buildSessionTile(s, cs)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSessionTile(MeditationSession session, ColorScheme cs) {
    final isBreathing = session.type == 'Breathing';
    final color = isBreathing ? EiraTheme.breathingColor : EiraTheme.meditationColor;
    final time = DateFormat('h:mm a').format(session.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withAlpha(80)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isBreathing ? Icons.air_rounded : Icons.self_improvement_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.method,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface.withAlpha(90)),
                  ),
                ],
              ),
            ),
            Text(
              _formatDuration(session.durationSeconds),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
