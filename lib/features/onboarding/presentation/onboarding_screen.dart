import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/features/dashboard/presentation/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      EiraTheme.smoothRoute(const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Logo + title
              Hero(
                tag: 'app-logo',
                child: Image.asset('assets/eirafocus.png', height: 88),
              ),
              const SizedBox(height: 16),
              Hero(
                tag: 'app-title',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    'EiraFocus',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your mindfulness companion',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: colorScheme.onSurface.withAlpha(120),
                ),
              ),

              const SizedBox(height: 48),

              // Feature cards
              FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Column(
                    children: [
                      _FeatureRow(
                        icon: Icons.air_rounded,
                        color: EiraTheme.breathingColor,
                        title: 'Breathing',
                        desc: 'Guided breathing exercises to calm your nervous system',
                      ),
                      const SizedBox(height: 14),
                      _FeatureRow(
                        icon: Icons.self_improvement_rounded,
                        color: EiraTheme.meditationColor,
                        title: 'Meditation',
                        desc: 'Timed sessions with mindfulness prompts',
                      ),
                      const SizedBox(height: 14),
                      _FeatureRow(
                        icon: Icons.insights_rounded,
                        color: EiraTheme.statsColor,
                        title: 'Insights',
                        desc: 'Track your progress and build consistency',
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // CTA
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _navigateToDashboard,
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'All data stays on your device',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurface.withAlpha(90),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
