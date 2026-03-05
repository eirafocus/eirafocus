import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/core/data/database_helper.dart';
import 'package:eirafocus/features/meditation/domain/meditation_models.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<List<MeditationSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = DatabaseHelper.instance.getSessions();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: FutureBuilder<List<MeditationSession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return _buildEmptyState(cs, tt);
          }
          return _buildContent(sessions, cs, tt);
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, TextTheme tt) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_rounded, size: 56, color: cs.onSurface.withAlpha(50)),
            const SizedBox(height: 16),
            Text('No data yet', style: tt.titleLarge?.copyWith(color: cs.onSurface.withAlpha(120))),
            const SizedBox(height: 8),
            Text(
              'Complete a session to start tracking your progress',
              textAlign: TextAlign.center,
              style: tt.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<MeditationSession> sessions, ColorScheme cs, TextTheme tt) {
    final totalSecs = sessions.fold<int>(0, (s, e) => s + e.durationSeconds);
    final avg = sessions.isEmpty ? 0.0 : totalSecs / sessions.length / 60;
    final breathCount = sessions.where((s) => s.type == 'Breathing').length;
    final medCount = sessions.where((s) => s.type == 'Meditation').length;
    final total = breathCount + medCount;

    // Method distribution
    final Map<String, int> methods = {};
    for (final s in sessions) {
      methods[s.method] = (methods[s.method] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row
          Row(
            children: [
              _StatBox(value: '${sessions.length}', label: 'Sessions', color: EiraTheme.breathingColor),
              const SizedBox(width: 10),
              _StatBox(value: '${(totalSecs / 60).round()}', label: 'Minutes', color: EiraTheme.meditationColor),
              const SizedBox(width: 10),
              _StatBox(value: avg.toStringAsFixed(1), label: 'Avg min', color: EiraTheme.statsColor),
            ],
          ),

          const SizedBox(height: 28),

          // Focus split
          Text('Focus Split', style: tt.headlineMedium),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outline.withAlpha(80)),
            ),
            child: Column(
              children: [
                // Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        if (breathCount > 0)
                          Expanded(
                            flex: breathCount,
                            child: Container(color: EiraTheme.breathingColor),
                          ),
                        if (medCount > 0)
                          Expanded(
                            flex: medCount,
                            child: Container(color: EiraTheme.meditationColor),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _LegendDot(color: EiraTheme.breathingColor, label: 'Breathing'),
                    const SizedBox(width: 6),
                    Text(
                      '${(breathCount / total * 100).round()}%',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                    const Spacer(),
                    _LegendDot(color: EiraTheme.meditationColor, label: 'Meditation'),
                    const SizedBox(width: 6),
                    Text(
                      '${(medCount / total * 100).round()}%',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Method breakdown
          Text('Methods', style: tt.headlineMedium),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outline.withAlpha(80)),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: methods.entries.toList().asMap().entries.map((e) {
                        final color = [
                          EiraTheme.breathingColor,
                          EiraTheme.meditationColor,
                          EiraTheme.statsColor,
                          EiraTheme.historyColor,
                          const Color(0xFF00695C),
                          const Color(0xFF388E3C),
                        ][e.key % 6];
                        return PieChartSectionData(
                          value: e.value.value.toDouble(),
                          color: color,
                          radius: 28,
                          showTitle: false,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...methods.entries.toList().asMap().entries.map((e) {
                  final color = [
                    EiraTheme.breathingColor,
                    EiraTheme.meditationColor,
                    EiraTheme.statsColor,
                    EiraTheme.historyColor,
                    const Color(0xFF26A69A),
                    const Color(0xFFEC407A),
                  ][e.key % 6];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(e.value.key,
                              style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface)),
                        ),
                        Text(
                          '${e.value.value}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withAlpha(80)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: cs.onSurface.withAlpha(100)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
        ),
      ],
    );
  }
}
