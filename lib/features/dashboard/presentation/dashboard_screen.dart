import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/features/breathing/presentation/breathing_screen.dart';
import 'package:eirafocus/features/meditation/presentation/meditation_selection_screen.dart';
import 'package:eirafocus/features/analytics/presentation/analytics_screen.dart';
import 'package:eirafocus/features/analytics/presentation/history_screen.dart';
import 'package:eirafocus/core/presentation/settings_screen.dart';
import 'package:eirafocus/core/data/database_helper.dart';
import 'package:eirafocus/features/streak/presentation/milestone_dialog.dart';
import 'package:eirafocus/features/challenges/presentation/challenges_screen.dart';
import 'package:eirafocus/features/breathing/domain/breathing_method.dart';
import 'package:eirafocus/features/breathing/presentation/breathing_session_screen.dart';
import 'package:eirafocus/features/meditation/presentation/meditation_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentStreak = 0;
  int _totalSessions = 0;
  int _totalMinutes = 0;
  int? _weeklyGoal;
  int _weeklyMinutes = 0;
  List<Map<String, dynamic>> _presets = [];

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _loadData();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final streak = await DatabaseHelper.instance.getCurrentStreak();
    final sessions = await DatabaseHelper.instance.getSessions();
    final weeklyGoal = await DatabaseHelper.instance.getWeeklyGoal();
    final weeklyMinutes = await DatabaseHelper.instance.getWeeklyMinutes();
    final presets = await DatabaseHelper.instance.getPresets();
    if (mounted) {
      setState(() {
        _currentStreak = streak;
        _totalSessions = sessions.length;
        _totalMinutes = sessions.fold<int>(0, (s, e) => s + e.durationSeconds) ~/ 60;
        _weeklyGoal = weeklyGoal;
        _weeklyMinutes = weeklyMinutes;
        _presets = presets;
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _navigate(Widget screen) {
    Navigator.of(context)
        .push(EiraTheme.smoothRoute(screen))
        .then((_) => _loadDataAndCheckMilestone());
  }

  Future<void> _loadDataAndCheckMilestone() async {
    final oldStreak = _currentStreak;
    await _loadData();
    if (_currentStreak > oldStreak) {
      final milestone = MilestoneDialog.checkMilestone(_currentStreak);
      if (milestone != null && mounted) {
        MilestoneDialog.show(context, milestone);
        return;
      }
    }
    // Check weekly goal celebration
    if (_weeklyGoal != null && _weeklyMinutes >= _weeklyGoal! && mounted) {
      final oldWeeklyMinutes = _weeklyMinutes - 1; // approximate
      if (oldWeeklyMinutes < _weeklyGoal!) {
        // Just hit the goal
      }
    }
  }

  void _launchPreset(Map<String, dynamic> preset) {
    final type = preset['type'] as String;
    final method = preset['method'] as String;
    final duration = preset['duration_minutes'] as int?;

    if (type == 'Breathing') {
      final breathingMethod = BreathingMethod.predefinedMethods.cast<BreathingMethod?>().firstWhere(
        (m) => m!.name == method,
        orElse: () => null,
      );
      if (breathingMethod != null) {
        _navigate(BreathingSessionScreen(
          method: breathingMethod,
          targetMinutes: duration,
        ));
      }
    } else {
      _navigate(MeditationScreen(
        initialMinutes: duration,
      ));
    }
  }

  Widget _buildPresetCard(Map<String, dynamic> preset) {
    final cs = Theme.of(context).colorScheme;
    final isBreathing = preset['type'] == 'Breathing';
    final color = isBreathing ? EiraTheme.breathingColor : EiraTheme.meditationColor;
    final duration = preset['duration_minutes'] as int?;

    return GestureDetector(
      onTap: () => _launchPreset(preset),
      onLongPress: () => _showDeletePresetDialog(preset['id'] as int, preset['name'] as String),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isBreathing ? Icons.air_rounded : Icons.self_improvement_rounded,
                  size: 16,
                  color: color,
                ),
                const Spacer(),
                Icon(Icons.play_circle_filled_rounded, size: 20, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              preset['name'] as String,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              duration != null ? '$duration min' : 'Free',
              style: GoogleFonts.inter(fontSize: 11, color: cs.onSurface.withAlpha(100)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeletePresetDialog(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Preset'),
        content: Text('Remove "$name" from quick start?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.deletePreset(id);
              _loadData();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreatePresetDialog() {
    final cs = Theme.of(context).colorScheme;
    String name = '';
    String type = 'Breathing';
    String method = BreathingMethod.predefinedMethods.first.name;
    int? duration; // null = Free
    bool durationSelected = true; // Free is selected by default

    final breathingNames = BreathingMethod.predefinedMethods.map((m) => m.name).toList();
    final durations = [null, 3, 5, 10, 15, 20, 30];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: cs.onSurface.withAlpha(40), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Text('Create Preset', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) => setSheetState(() => name = v),
                decoration: const InputDecoration(hintText: 'Preset name', isDense: true),
              ),
              const SizedBox(height: 14),
              // Type toggle
              Row(
                children: ['Breathing', 'Meditation'].map((t) {
                  final selected = type == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setSheetState(() {
                        type = t;
                        if (t == 'Breathing') method = breathingNames.first;
                        if (t == 'Meditation') method = 'Meditation';
                      }),
                      child: Container(
                        margin: EdgeInsets.only(right: t == 'Breathing' ? 4 : 0, left: t == 'Meditation' ? 4 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? cs.primary.withAlpha(20) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? cs.primary.withAlpha(80) : cs.outline.withAlpha(80)),
                        ),
                        child: Center(
                          child: Text(t, style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: selected ? cs.primary : cs.onSurface.withAlpha(120),
                          )),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Method picker for breathing
              if (type == 'Breathing') ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: breathingNames.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final selected = method == breathingNames[i];
                      return GestureDetector(
                        onTap: () => setSheetState(() => method = breathingNames[i]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? cs.primary.withAlpha(20) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? cs.primary.withAlpha(80) : cs.outline.withAlpha(80)),
                          ),
                          child: Text(breathingNames[i], style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: selected ? cs.primary : cs.onSurface.withAlpha(120),
                          )),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 14),
              // Duration
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: durations.map((d) {
                  final selected = durationSelected && duration == d;
                  final label = d == null ? 'Free' : '$d min';
                  return GestureDetector(
                    onTap: () => setSheetState(() { duration = d; durationSelected = true; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? cs.primary.withAlpha(20) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? cs.primary.withAlpha(80) : cs.outline.withAlpha(80)),
                      ),
                      child: Text(label, style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: selected ? cs.primary : cs.onSurface.withAlpha(120),
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: name.trim().isEmpty ? null : () async {
                    Navigator.pop(ctx);
                    await DatabaseHelper.instance.insertPreset({
                      'name': name,
                      'type': type,
                      'method': type == 'Meditation' ? 'Meditation' : method,
                      'duration_minutes': duration,
                      'created_at': DateTime.now().toIso8601String(),
                    });
                    _loadData();
                  },
                  child: const Text('Save Preset'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                children: [
                  Image.asset('assets/eirafocus.png', height: 32),
                  const SizedBox(width: 10),
                  Text('EiraFocus', style: tt.titleLarge),
                  const Spacer(),
                  _IconBtn(
                    icon: Icons.settings_outlined,
                    onTap: () => _navigate(const SettingsScreen()),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Greeting
              Text(_greeting(), style: tt.headlineLarge),
              const SizedBox(height: 4),
              Text(
                'What would you like to practice?',
                style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(120)),
              ),

              const SizedBox(height: 20),

              // Daily quote
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _DailyQuoteCard(),
                ),
              ),

              const SizedBox(height: 20),

              // Stats row
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Row(
                    children: [
                      _StatChip(label: 'Streak', value: '$_currentStreak day${_currentStreak == 1 ? '' : 's'}', icon: Icons.local_fire_department_rounded, color: const Color(0xFFFF7043)),
                      const SizedBox(width: 10),
                      _StatChip(label: 'Sessions', value: '$_totalSessions', icon: Icons.check_circle_outline_rounded, color: EiraTheme.breathingColor),
                      const SizedBox(width: 10),
                      _StatChip(label: 'Minutes', value: '$_totalMinutes', icon: Icons.schedule_rounded, color: EiraTheme.meditationColor),
                    ],
                  ),
                ),
              ),

              // Weekly goal progress
              if (_weeklyGoal != null) ...[
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _WeeklyGoalCard(
                      currentMinutes: _weeklyMinutes,
                      goalMinutes: _weeklyGoal!,
                    ),
                  ),
                ),
              ],

              // Milestone badges
              if (_currentStreak >= 3) ...[
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _MilestoneBadges(currentStreak: _currentStreak),
                  ),
                ),
              ],


              // Quick presets
              if (_presets.isNotEmpty || _totalSessions > 0) ...[
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Quick Start', style: Theme.of(context).textTheme.headlineMedium),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showCreatePresetDialog(),
                              child: Icon(Icons.add_rounded, size: 22, color: Theme.of(context).colorScheme.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _presets.length + 1,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              if (i < _presets.length) return _buildPresetCard(_presets[i]);
                              // Add button
                              return GestureDetector(
                                onTap: _showCreatePresetDialog,
                                child: Container(
                                  width: 88,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(80)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_rounded, size: 24, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(height: 4),
                                      Text('Add', style: GoogleFonts.inter(
                                        fontSize: 12, fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      )),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Main action cards
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      _ActionCard(
                        title: 'Breathing',
                        subtitle: 'Guided breathing exercises',
                        icon: Icons.air_rounded,
                        color: EiraTheme.breathingColor,
                        onTap: () => _navigate(const BreathingScreen()),
                        large: true,
                      ),
                      const SizedBox(height: 14),
                      _ActionCard(
                        title: 'Meditation',
                        subtitle: 'Timed mindfulness sessions',
                        icon: Icons.self_improvement_rounded,
                        color: EiraTheme.meditationColor,
                        onTap: () => _navigate(const MeditationSelectionScreen()),
                        large: true,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              title: 'Stats',
                              subtitle: 'Your progress',
                              icon: Icons.insights_rounded,
                              color: EiraTheme.statsColor,
                              onTap: () => _navigate(const AnalyticsScreen()),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ActionCard(
                              title: 'History',
                              subtitle: 'Past sessions',
                              icon: Icons.history_rounded,
                              color: EiraTheme.historyColor,
                              onTap: () => _navigate(const HistoryScreen()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ActionCard(
                        title: 'Challenges',
                        subtitle: 'Set goals and track progress',
                        icon: Icons.flag_rounded,
                        color: const Color(0xFFFF7043),
                        onTap: () => _navigate(const ChallengesScreen()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Weekly Goal Card ──────────────────────────────────────────
class _WeeklyGoalCard extends StatelessWidget {
  final int currentMinutes;
  final int goalMinutes;

  const _WeeklyGoalCard({required this.currentMinutes, required this.goalMinutes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (currentMinutes / goalMinutes).clamp(0.0, 1.0);
    final met = currentMinutes >= goalMinutes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                met ? Icons.check_circle_rounded : Icons.flag_rounded,
                size: 18,
                color: met ? EiraTheme.statsColor : cs.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Weekly Goal',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
              ),
              const Spacer(),
              Text(
                '$currentMinutes / $goalMinutes min',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: met ? EiraTheme.statsColor : cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: cs.outline.withAlpha(40),
              valueColor: AlwaysStoppedAnimation(met ? EiraTheme.statsColor : cs.primary),
            ),
          ),
          if (met) ...[
            const SizedBox(height: 8),
            Text(
              'Goal reached! Great work this week!',
              style: GoogleFonts.inter(fontSize: 12, color: EiraTheme.statsColor, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Milestone Badges ──────────────────────────────────────────
class _MilestoneBadges extends StatelessWidget {
  final int currentStreak;

  const _MilestoneBadges({required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final achieved = MilestoneDialog.getAchievedMilestones(currentStreak);
    if (achieved.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, size: 18, color: const Color(0xFFFF7043)),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: achieved.map((m) {
                return GestureDetector(
                  onTap: () => MilestoneDialog.show(context, m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7043).withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFF7043).withAlpha(40)),
                    ),
                    child: Text(
                      '${m}d',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF7043),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Daily Quote ────────────────────────────────────────────────
class _DailyQuoteCard extends StatelessWidget {
  static const _quotes = [
    ('The present moment is the only moment available to us, and it is the door to all moments.', 'Thich Nhat Hanh'),
    ('Feelings come and go like clouds in a windy sky. Conscious breathing is my anchor.', 'Thich Nhat Hanh'),
    ('The mind is everything. What you think you become.', 'Buddha'),
    ('Peace comes from within. Do not seek it without.', 'Buddha'),
    ('In the midst of movement and chaos, keep stillness inside of you.', 'Deepak Chopra'),
    ('Breathe in deeply to bring your mind home to your body.', 'Thich Nhat Hanh'),
    ('Almost everything will work again if you unplug it for a few minutes, including you.', 'Anne Lamott'),
    ('The greatest weapon against stress is our ability to choose one thought over another.', 'William James'),
    ('Do not dwell in the past, do not dream of the future, concentrate the mind on the present moment.', 'Buddha'),
    ('Quiet the mind, and the soul will speak.', 'Ma Jaya Sati Bhagavati'),
    ('You are the sky. Everything else is just the weather.', 'Pema Chödrön'),
    ('Be where you are, not where you think you should be.', 'Unknown'),
    ('The only way to live is by accepting each minute as an unrepeatable miracle.', 'Tara Brach'),
    ('Surrender to what is. Let go of what was. Have faith in what will be.', 'Sonia Ricotti'),
    ('When you realize nothing is lacking, the whole world belongs to you.', 'Lao Tzu'),
    ('Smile, breathe, and go slowly.', 'Thich Nhat Hanh'),
    ('The soul always knows what to do to heal itself. The challenge is to silence the mind.', 'Caroline Myss'),
    ('Nature does not hurry, yet everything is accomplished.', 'Lao Tzu'),
    ('Within you there is a stillness and a sanctuary to which you can retreat at any time.', 'Hermann Hesse'),
    ('Each morning we are born again. What we do today is what matters most.', 'Buddha'),
    ('Life is a dance. Mindfulness is witnessing that dance.', 'Amit Ray'),
    ('Wherever you are, be there totally.', 'Eckhart Tolle'),
    ('Silence is not empty. It is full of answers.', 'Unknown'),
    ('What lies behind us and what lies before us are tiny matters compared to what lies within us.', 'Ralph Waldo Emerson'),
    ('Meditation is not about stopping thoughts, but recognizing that we are more than our thoughts.', 'Arianna Huffington'),
    ('Every breath is a chance to begin again.', 'Unknown'),
    ('Respond; don\'t react. Listen; don\'t talk. Think; don\'t assume.', 'Raji Lukkoor'),
    ('The best time to relax is when you don\'t have time for it.', 'Sydney J. Harris'),
    ('Your calm mind is the ultimate weapon against your challenges.', 'Bryant McGill'),
    ('Mindfulness is a way of befriending ourselves and our experience.', 'Jon Kabat-Zinn'),
    ('Breathing in, I calm body and mind. Breathing out, I smile.', 'Thich Nhat Hanh'),
  ];

  const _DailyQuoteCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final quote = _quotes[dayOfYear % _quotes.length];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.primary.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, size: 20, color: cs.primary.withAlpha(120)),
          const SizedBox(height: 6),
          Text(
            quote.$1,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: cs.onSurface.withAlpha(180),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${quote.$2}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withAlpha(90),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small icon button ──────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withAlpha(80)),
        ),
        child: Icon(icon, size: 20, color: cs.onSurface.withAlpha(180)),
      ),
    );
  }
}

// ─── Stat chip ──────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withAlpha(80)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
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
          ],
        ),
      ),
    );
  }
}

// ─── Action card ────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool large;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(large ? 22 : 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline.withAlpha(80)),
        ),
        child: large
            ? Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withAlpha(22),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: cs.onSurface.withAlpha(100),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurface.withAlpha(60),
                    size: 22,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withAlpha(22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: cs.onSurface.withAlpha(60),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(100),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }
}
