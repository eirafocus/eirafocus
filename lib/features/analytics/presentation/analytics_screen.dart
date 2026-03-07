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

          // Personal records
          Text('Personal Records', style: tt.headlineMedium),
          const SizedBox(height: 6),
          Text('Your all-time bests', style: tt.bodySmall),
          const SizedBox(height: 14),
          _PersonalRecords(sessions: sessions),

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

          // Heatmap calendar
          Text('Practice Calendar', style: tt.headlineMedium),
          const SizedBox(height: 6),
          Text('Your practice activity', style: tt.bodySmall),
          const SizedBox(height: 14),
          _HeatmapCalendar(sessions: sessions),

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

// ─── Personal Records ───────────────────────────────────────────
class _PersonalRecords extends StatelessWidget {
  final List<MeditationSession> sessions;

  const _PersonalRecords({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Longest session
    int longestSecs = 0;
    String longestMethod = '';
    for (final s in sessions) {
      if (s.durationSeconds > longestSecs) {
        longestSecs = s.durationSeconds;
        longestMethod = s.method;
      }
    }

    // Best streak
    final dates = sessions.map((s) => DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day)).toSet().toList()..sort();
    int bestStreak = 0;
    int currentStreak = 0;
    for (int i = 0; i < dates.length; i++) {
      if (i == 0) {
        currentStreak = 1;
      } else {
        final diff = dates[i].difference(dates[i - 1]).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }
      }
      if (currentStreak > bestStreak) bestStreak = currentStreak;
    }

    // Best week (most minutes in any Mon-Sun week)
    int bestWeekMins = 0;
    if (sessions.isNotEmpty) {
      final Map<String, double> weeklyMins = {};
      for (final s in sessions) {
        // Get Monday of that week
        final d = s.timestamp;
        final monday = d.subtract(Duration(days: d.weekday - 1));
        final key = DateFormat('yyyy-MM-dd').format(monday);
        weeklyMins[key] = (weeklyMins[key] ?? 0) + s.durationSeconds / 60;
      }
      for (final v in weeklyMins.values) {
        if (v.round() > bestWeekMins) bestWeekMins = v.round();
      }
    }

    // Total days practiced
    final totalDays = dates.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withAlpha(80)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _RecordTile(
                  icon: Icons.timer_rounded,
                  label: 'Longest Session',
                  value: _formatDuration(longestSecs),
                  detail: longestMethod,
                  color: EiraTheme.meditationColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RecordTile(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Best Streak',
                  value: '$bestStreak day${bestStreak == 1 ? '' : 's'}',
                  detail: '',
                  color: const Color(0xFFFF7043),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RecordTile(
                  icon: Icons.emoji_events_rounded,
                  label: 'Best Week',
                  value: '$bestWeekMins min',
                  detail: '',
                  color: EiraTheme.statsColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RecordTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'Days Practiced',
                  value: '$totalDays',
                  detail: '',
                  color: EiraTheme.breathingColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int secs) {
    if (secs == 0) return '0s';
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class _RecordTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _RecordTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: cs.onSurface.withAlpha(100),
            ),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              detail,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: color.withAlpha(180),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Heatmap Calendar ───────────────────────────────────────────
class _HeatmapCalendar extends StatefulWidget {
  final List<MeditationSession> sessions;

  const _HeatmapCalendar({required this.sessions});

  @override
  State<_HeatmapCalendar> createState() => _HeatmapCalendarState();
}

class _HeatmapCalendarState extends State<_HeatmapCalendar> {
  String? _selectedKey; // yyyy-MM-dd of tapped cell

  @override
  Widget build(BuildContext context) {
    final sessions = widget.sessions;
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build daily minutes map for last 16 weeks (112 days)
    const totalDays = 112;
    final startDate = today.subtract(const Duration(days: totalDays - 1));
    final Map<String, double> dailyMinutes = {};
    for (final s in sessions) {
      final key = DateFormat('yyyy-MM-dd').format(s.timestamp);
      dailyMinutes[key] = (dailyMinutes[key] ?? 0) + s.durationSeconds / 60;
    }

    // Find max for color scaling
    double maxMin = 0;
    for (int i = 0; i < totalDays; i++) {
      final d = startDate.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      final v = dailyMinutes[key] ?? 0;
      if (v > maxMin) maxMin = v;
    }
    if (maxMin == 0) maxMin = 1;

    // Build grid: 7 rows (Mon-Sun) x 16 columns (weeks)
    // Adjust start to beginning of week (Monday)
    final startWeekday = startDate.weekday; // 1=Mon, 7=Sun
    final gridStart = startDate.subtract(Duration(days: startWeekday - 1));
    final endDate = today;

    // Calculate number of weeks
    final totalWeeks = ((endDate.difference(gridStart).inDays) ~/ 7) + 1;

    // Month labels
    final monthLabels = <int, String>{};
    for (int w = 0; w < totalWeeks; w++) {
      final weekStart = gridStart.add(Duration(days: w * 7));
      if (w == 0 || weekStart.month != gridStart.add(Duration(days: (w - 1) * 7)).month) {
        monthLabels[w] = DateFormat('MMM').format(weekStart);
      }
    }

    const cellSize = 14.0;
    const cellGap = 3.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month labels row
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: SizedBox(
              height: 16,
              child: Row(
                children: List.generate(totalWeeks, (w) {
                  return SizedBox(
                    width: cellSize + cellGap,
                    child: monthLabels.containsKey(w)
                        ? Text(
                            monthLabels[w]!,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: cs.onSurface.withAlpha(80),
                            ),
                          )
                        : const SizedBox(),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels
              Column(
                children: ['M', '', 'W', '', 'F', '', 'S'].map((label) {
                  return SizedBox(
                    height: cellSize + cellGap,
                    width: 24,
                    child: label.isNotEmpty
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                label,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: cs.onSurface.withAlpha(80),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(),
                  );
                }).toList(),
              ),
              // Heatmap grid
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    children: List.generate(totalWeeks, (w) {
                      return Column(
                        children: List.generate(7, (d) {
                          final date = gridStart.add(Duration(days: w * 7 + d));
                          if (date.isAfter(today) || date.isBefore(startDate.subtract(const Duration(days: 7)))) {
                            return SizedBox(
                              width: cellSize + cellGap,
                              height: cellSize + cellGap,
                            );
                          }
                          final key = DateFormat('yyyy-MM-dd').format(date);
                          final mins = dailyMinutes[key] ?? 0;
                          final intensity = mins > 0 ? (mins / maxMin).clamp(0.15, 1.0) : 0.0;

                          final isSelected = _selectedKey == key;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedKey = isSelected ? null : key),
                            child: Padding(
                              padding: const EdgeInsets.all(cellGap / 2),
                              child: Container(
                                width: cellSize,
                                height: cellSize,
                                decoration: BoxDecoration(
                                  color: mins > 0
                                      ? cs.primary.withAlpha((intensity * 220 + 35).toInt())
                                      : cs.onSurface.withAlpha(15),
                                  borderRadius: BorderRadius.circular(3),
                                  border: isSelected
                                      ? Border.all(color: cs.onSurface, width: 1.5)
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
          // Selected cell info
          if (_selectedKey != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 13, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('MMM d, yyyy').format(DateTime.parse(_selectedKey!))}  ·  ${(dailyMinutes[_selectedKey!] ?? 0).round()} min',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: GoogleFonts.inter(fontSize: 9, color: cs.onSurface.withAlpha(80))),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                final alpha = i == 0 ? 15 : (55 + i * 45).clamp(0, 255);
                return Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? cs.onSurface.withAlpha(15)
                          : cs.primary.withAlpha(alpha),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text('More', style: GoogleFonts.inter(fontSize: 9, color: cs.onSurface.withAlpha(80))),
            ],
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
