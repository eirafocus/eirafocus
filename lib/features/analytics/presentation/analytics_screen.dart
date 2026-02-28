import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

  Map<String, double> _calculateMethodDistribution(List<MeditationSession> sessions) {
    final Map<String, int> counts = {};
    for (var session in sessions) {
      counts[session.method] = (counts[session.method] ?? 0) + 1;
    }
    return counts.map((key, value) => MapEntry(key, value.toDouble()));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: FutureBuilder<List<MeditationSession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return const Center(child: Text('Start a session to see analytics!'));
          }

          final totalSeconds = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
          final avgSeconds = totalSeconds / sessions.length;
          final methodCounts = _calculateMethodDistribution(sessions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(
                  'Quick Stats',
                  [
                    _buildStatItem('Total Sessions', '${sessions.length}'),
                    _buildStatItem('Total Time', '${(totalSeconds / 60).toStringAsFixed(1)} min'),
                    _buildStatItem('Avg. Session', '${(avgSeconds / 60).toStringAsFixed(1)} min'),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Method Distribution',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: methodCounts.entries.map((entry) {
                        return PieChartSectionData(
                          value: entry.value,
                          title: entry.key,
                          radius: 50,
                          color: Colors.accents[methodCounts.keys.toList().indexOf(entry.key) % Colors.accents.length],
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildMeditationVsBreathing(sessions),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: stats,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMeditationVsBreathing(List<MeditationSession> sessions) {
    final breathingCount = sessions.where((s) => s.type == 'Breathing').length;
    final meditationCount = sessions.where((s) => s.type == 'Meditation').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('Focus Area', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: breathingCount,
                  child: Container(
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
                    ),
                  ),
                ),
                Expanded(
                  flex: meditationCount,
                  child: Container(
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Breathing ($breathingCount)', style: const TextStyle(color: Colors.green)),
                Text('Meditation ($meditationCount)', style: const TextStyle(color: Colors.blue)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
