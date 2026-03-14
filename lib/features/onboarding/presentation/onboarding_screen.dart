import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/core/data/database_helper.dart';
import 'package:eirafocus/core/services/notification_service.dart';
import 'package:eirafocus/features/dashboard/presentation/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _page = 0;

  // Selections
  String? _selectedGoal;
  String? _selectedExperience;
  int _weeklyGoalMinutes = 30;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  static const _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboarding_goal', _selectedGoal ?? '');
    await prefs.setString('onboarding_experience', _selectedExperience ?? '');
    await prefs.setBool('onboarding_done', true);

    if (_weeklyGoalMinutes > 0) {
      await DatabaseHelper.instance.setWeeklyGoal(_weeklyGoalMinutes);
    }

    if (_reminderEnabled) {
      await prefs.setBool('reminders_enabled', true);
      await prefs.setInt('reminder_hour', _reminderTime.hour);
      await prefs.setInt('reminder_minute', _reminderTime.minute);
      await NotificationService.instance.scheduleDailyReminder(
        _reminderTime.hour,
        _reminderTime.minute,
      );
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        EiraTheme.smoothRoute(const DashboardScreen()),
      );
    }
  }

  bool get _canContinue {
    if (_page == 0) return _selectedGoal != null;
    if (_page == 1) return _selectedExperience != null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(_totalPages, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      margin: EdgeInsets.only(right: i < _totalPages - 1 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i <= _page
                            ? cs.primary
                            : cs.outline.withAlpha(60),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _GoalPage(
                    selected: _selectedGoal,
                    onSelected: (v) => setState(() => _selectedGoal = v),
                  ),
                  _ExperiencePage(
                    selected: _selectedExperience,
                    onSelected: (v) => setState(() => _selectedExperience = v),
                  ),
                  _WeeklyGoalPage(
                    selected: _weeklyGoalMinutes,
                    onSelected: (v) => setState(() => _weeklyGoalMinutes = v),
                  ),
                  _ReminderPage(
                    enabled: _reminderEnabled,
                    time: _reminderTime,
                    onToggle: (v) => setState(() => _reminderEnabled = v),
                    onTimeTap: _pickTime,
                  ),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _canContinue ? _next : null,
                      child: Text(
                        _page == _totalPages - 1 ? 'Get Started' : 'Continue',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (_page > 0) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        onPressed: _back,
                        child: Text(
                          'Back',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: cs.onSurface.withAlpha(120),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Text(
                      'All data stays on your device',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cs.onSurface.withAlpha(80),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }
}

// ─── Page 1: Goal ──────────────────────────────────────────────
class _GoalPage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const _GoalPage({required this.selected, required this.onSelected});

  static const _options = [
    (icon: Icons.spa_rounded, label: 'Reduce stress', color: Color(0xFF66BB6A)),
    (icon: Icons.self_improvement_rounded, label: 'Build a habit', color: Color(0xFF42A5F5)),
    (icon: Icons.gps_fixed_rounded, label: 'Improve focus', color: Color(0xFFAB47BC)),
    (icon: Icons.bedtime_rounded, label: 'Better sleep', color: Color(0xFF26A69A)),
  ];

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      title: 'What brings you here?',
      subtitle: 'We\'ll personalise your experience around your goal.',
      child: Column(
        children: _options.map((o) {
          final sel = selected == o.label;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionCard(
              icon: o.icon,
              label: o.label,
              color: o.color,
              selected: sel,
              onTap: () => onSelected(o.label),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Page 2: Experience ────────────────────────────────────────
class _ExperiencePage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const _ExperiencePage({required this.selected, required this.onSelected});

  static const _options = [
    (icon: Icons.flag_rounded, label: 'Beginner', sub: 'Just starting out', color: Color(0xFF42A5F5)),
    (icon: Icons.trending_up_rounded, label: 'Some experience', sub: 'Occasional practice', color: Color(0xFFFFB300)),
    (icon: Icons.workspace_premium_rounded, label: 'Regular practitioner', sub: 'Daily or weekly routine', color: Color(0xFFAB47BC)),
  ];

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      title: 'Your experience level?',
      subtitle: 'This helps us suggest the right sessions for you.',
      child: Column(
        children: _options.map((o) {
          final sel = selected == o.label;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionCard(
              icon: o.icon,
              label: o.label,
              subtitle: o.sub,
              color: o.color,
              selected: sel,
              onTap: () => onSelected(o.label),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Page 3: Weekly Goal ───────────────────────────────────────
class _WeeklyGoalPage extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _WeeklyGoalPage({required this.selected, required this.onSelected});

  static const _presets = [10, 15, 30, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _PageShell(
      title: 'Set a weekly goal',
      subtitle: 'How many minutes would you like to practice per week?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected value display
          Center(
            child: Column(
              children: [
                Text(
                  '$selected',
                  style: GoogleFonts.inter(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                    height: 1,
                  ),
                ),
                Text(
                  'min / week',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: cs.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _presets.map((m) {
              final sel = selected == m;
              return GestureDetector(
                onTap: () => onSelected(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? cs.primary.withAlpha(20) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? cs.primary : cs.outline.withAlpha(80),
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    '${m}m',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: sel ? cs.primary : cs.onSurface.withAlpha(120),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'That\'s about ${(selected / 7).ceil()} min per day.',
            style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withAlpha(100)),
          ),
        ],
      ),
    );
  }
}

// ─── Page 4: Reminder ─────────────────────────────────────────
class _ReminderPage extends StatelessWidget {
  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTimeTap;

  const _ReminderPage({
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _PageShell(
      title: 'Daily reminder',
      subtitle: 'A gentle nudge to keep your practice consistent.',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outline.withAlpha(80)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.notifications_outlined, color: cs.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Reminder',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
                      ),
                      Text(
                        enabled ? 'Every day at ${time.format(context)}' : 'Off',
                        style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface.withAlpha(100)),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: enabled,
                  onChanged: onToggle,
                  activeTrackColor: cs.primary,
                ),
              ],
            ),
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onTimeTap,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outline.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.schedule_rounded, color: cs.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        time.format(context),
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurface.withAlpha(60)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'You can change this anytime in Settings.',
            style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withAlpha(80)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Shared: Page shell ────────────────────────────────────────
class _PageShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _PageShell({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface.withAlpha(120), height: 1.5),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

// ─── Shared: Option card ───────────────────────────────────────
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(15) : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withAlpha(120) : cs.outline.withAlpha(80),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(selected ? 30 : 18),
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
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface.withAlpha(100)),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? color : cs.outline.withAlpha(80),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
