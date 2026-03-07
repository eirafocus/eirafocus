import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
  bool _showWeekly = true; // true = week, false = month

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

          // Trends section
          Row(
            children: [
              Expanded(child: Text('Trends', style: tt.headlineMedium)),
              _ToggleChips(
                showWeekly: _showWeekly,
                onChanged: (v) => setState(() => _showWeekly = v),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _TrendChart(sessions: sessions, isWeekly: _showWeekly),

          const SizedBox(height: 28),

          // Best times
          Text('Best Times', style: tt.headlineMedium),
          const SizedBox(height: 6),
          Text('When you practice most', style: tt.bodySmall),
          const SizedBox(height: 14),
          _BestTimesChart(sessions: sessions),

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

// ─── Best Times Chart ───────────────────────────────────────────
class _BestTimesChart extends StatelessWidget {
  final List<MeditationSession> sessions;

  const _BestTimesChart({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Group sessions by hour
    final hourCounts = List.filled(24, 0);
    for (final s in sessions) {
      hourCounts[s.timestamp.hour]++;
    }

    final maxCount = hourCounts.fold<int>(0, (m, c) => c > m ? c : m);
    final peakHour = hourCounts.indexOf(maxCount);

    // Group into time blocks for display
    final blocks = [
      ('Early\nMorning', 5, 8),
      ('Morning', 8, 12),
      ('Afternoon', 12, 17),
      ('Evening', 17, 21),
      ('Night', 21, 24),
    ];

    // Find which block has most sessions
    int bestBlockIdx = 0;
    int bestBlockCount = 0;
    for (int b = 0; b < blocks.length; b++) {
      int count = 0;
      for (int h = blocks[b].$2; h < blocks[b].$3; h++) {
        count += hourCounts[h];
      }
      if (count > bestBlockCount) {
        bestBlockCount = count;
        bestBlockIdx = b;
      }
    }

    String peakLabel;
    if (peakHour < 5) {
      peakLabel = 'Late night';
    } else if (peakHour < 8) {
      peakLabel = 'Early morning';
    } else if (peakHour < 12) {
      peakLabel = 'Morning';
    } else if (peakHour < 17) {
      peakLabel = 'Afternoon';
    } else if (peakHour < 21) {
      peakLabel = 'Evening';
    } else {
      peakLabel = 'Night';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (maxCount > 0) ...[
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Peak: $peakLabel (${_formatHour(peakHour)})',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= blocks.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            blocks[idx].$1,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: idx == bestBlockIdx ? cs.primary : cs.onSurface.withAlpha(80),
                              fontWeight: idx == bestBlockIdx ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                maxY: bestBlockCount > 0 ? bestBlockCount * 1.3 : 3,
                barGroups: List.generate(blocks.length, (b) {
                  int count = 0;
                  for (int h = blocks[b].$2; h < blocks[b].$3; h++) {
                    count += hourCounts[h];
                  }
                  return BarChartGroupData(
                    x: b,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: b == bestBlockIdx
                            ? cs.primary
                            : cs.primary.withAlpha(60),
                        width: 32,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

// ─── Trend Chart ────────────────────────────────────────────────
class _TrendChart extends StatelessWidget {
  final List<MeditationSession> sessions;
  final bool isWeekly;

  const _TrendChart({required this.sessions, required this.isWeekly});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final days = isWeekly ? 7 : 30;
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));

    // Build daily data
    final Map<String, double> dailyMinutes = {};
    final Map<String, int> dailyCount = {};
    for (int i = 0; i < days; i++) {
      final d = startDate.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      dailyMinutes[key] = 0;
      dailyCount[key] = 0;
    }
    for (final s in sessions) {
      final key = DateFormat('yyyy-MM-dd').format(s.timestamp);
      if (dailyMinutes.containsKey(key)) {
        dailyMinutes[key] = dailyMinutes[key]! + s.durationSeconds / 60;
        dailyCount[key] = dailyCount[key]! + 1;
      }
    }

    final minuteSpots = <FlSpot>[];
    final countSpots = <FlSpot>[];
    final labels = <String>[];
    int i = 0;
    for (final key in dailyMinutes.keys) {
      minuteSpots.add(FlSpot(i.toDouble(), dailyMinutes[key]!));
      countSpots.add(FlSpot(i.toDouble(), dailyCount[key]!.toDouble()));
      final d = DateTime.parse(key);
      labels.add(isWeekly
          ? DateFormat('E').format(d)
          : (i % 5 == 0 ? DateFormat('d').format(d) : ''));
      i++;
    }

    final maxMinutes = minuteSpots.fold<double>(0, (m, s) => s.y > m ? s.y : m);
    final maxCount = countSpots.fold<double>(0, (m, s) => s.y > m ? s.y : m);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minutes chart
          Text('Minutes per day',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withAlpha(120))),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxMinutes > 0 ? maxMinutes / 3 : 1).ceilToDouble(),
                  getDrawingHorizontalLine: (v) => FlLine(color: cs.outline.withAlpha(40), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.inter(fontSize: 10, color: cs.onSurface.withAlpha(80)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(labels[idx],
                              style: GoogleFonts.inter(fontSize: 10, color: cs.onSurface.withAlpha(80))),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxMinutes > 0 ? maxMinutes * 1.2 : 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: minuteSpots,
                    isCurved: true,
                    color: EiraTheme.meditationColor,
                    barWidth: 2.5,
                    dotData: FlDotData(show: isWeekly),
                    belowBarData: BarAreaData(
                      show: true,
                      color: EiraTheme.meditationColor.withAlpha(25),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Session count chart
          Text('Sessions per day',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withAlpha(120))),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        if (v != v.roundToDouble()) return const SizedBox();
                        return Text(
                          v.toInt().toString(),
                          style: GoogleFonts.inter(fontSize: 10, color: cs.onSurface.withAlpha(80)),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(labels[idx],
                              style: GoogleFonts.inter(fontSize: 10, color: cs.onSurface.withAlpha(80))),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                maxY: maxCount > 0 ? maxCount + 1 : 3,
                barGroups: countSpots.map((s) {
                  return BarChartGroupData(
                    x: s.x.toInt(),
                    barRods: [
                      BarChartRodData(
                        toY: s.y,
                        color: EiraTheme.breathingColor,
                        width: isWeekly ? 16 : 5,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Toggle Chips ─────────────────────────────────────────────
class _ToggleChips extends StatelessWidget {
  final bool showWeekly;
  final ValueChanged<bool> onChanged;

  const _ToggleChips({required this.showWeekly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(context, 'Week', showWeekly, () => onChanged(true), cs),
        const SizedBox(width: 6),
        _chip(context, 'Month', !showWeekly, () => onChanged(false), cs),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, bool selected, VoidCallback onTap, ColorScheme cs) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? cs.primary.withAlpha(80) : cs.outline.withAlpha(60),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? cs.primary : cs.onSurface.withAlpha(100),
          ),
        ),
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
