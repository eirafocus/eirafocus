import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:eirafocus/features/breathing/presentation/breathing_screen.dart';
import 'package:eirafocus/features/meditation/presentation/meditation_screen.dart';
import 'package:eirafocus/features/analytics/presentation/analytics_screen.dart';
import 'package:eirafocus/features/analytics/presentation/history_screen.dart';
import 'package:eirafocus/core/data/database_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final streak = await DatabaseHelper.instance.getCurrentStreak();
    if (mounted) {
      setState(() {
        _currentStreak = streak;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EiraFocus'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Good Day!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                _buildStreakBadge(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a session to begin.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    context,
                    'Breathing',
                    'Calm your mind',
                    Icons.air,
                    Colors.green.shade700,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const BreathingScreen()),
                      ).then((_) => _loadStreak());
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    'Meditation',
                    'Find focus',
                    Icons.self_improvement,
                    Colors.blue.shade700,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const MeditationScreen()),
                      ).then((_) => _loadStreak());
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    'Statistics',
                    'Track sessions',
                    Icons.bar_chart,
                    Colors.orange.shade700,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    'History',
                    'Previous stats',
                    Icons.history,
                    Colors.purple.shade700,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FontAwesomeIcons.fire, size: 16, color: Colors.orange.shade800),
          const SizedBox(width: 6),
          Text(
            '$_currentStreak days',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
