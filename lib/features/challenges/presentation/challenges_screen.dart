import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eirafocus/core/data/database_helper.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  List<Map<String, dynamic>> _active = [];
  List<Map<String, dynamic>> _completed = [];
  bool _loading = true;

  // Challenge templates
  static const _templates = [
    {
      'title': '7-Day Streak',
      'description': 'Practice every day for 7 days',
      'type': 'streak_days',
      'target': 7,
      'days': 7,
      'icon': '0xF06BB', // fire
    },
    {
      'title': '30-Minute Week',
      'description': 'Accumulate 30 minutes this week',
      'type': 'total_minutes',
      'target': 30,
      'days': 7,
      'icon': '0xF01B7', // schedule
    },
    {
      'title': '10 Sessions',
      'description': 'Complete 10 sessions in 2 weeks',
      'type': 'session_count',
      'target': 10,
      'days': 14,
      'icon': '0xF0634', // check_circle
    },
    {
      'title': '14-Day Streak',
      'description': 'Two weeks of daily practice',
      'type': 'streak_days',
      'target': 14,
      'days': 14,
      'icon': '0xF0B30', // star
    },
    {
      'title': '60-Minute Challenge',
      'description': 'One hour of practice in 7 days',
      'type': 'total_minutes',
      'target': 60,
      'days': 7,
      'icon': '0xF0566', // timer
    },
    {
      'title': 'Daily Dedication',
      'description': '30 days of consistent practice',
      'type': 'streak_days',
      'target': 30,
      'days': 30,
      'icon': '0xF0640', // emoji_events
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final active = await DatabaseHelper.instance.getActiveChallenges();
    final completed = await DatabaseHelper.instance.getCompletedChallenges();

    // Check if any active challenges are now complete
    for (final c in active) {
      final progress = await _getProgress(c);
      if (progress >= (c['target_value'] as int)) {
        await DatabaseHelper.instance.completeChallenge(c['id'] as int);
      }
    }

    // Reload after potential completions
    final refreshedActive = await DatabaseHelper.instance.getActiveChallenges();
    final refreshedCompleted = await DatabaseHelper.instance.getCompletedChallenges();

    if (mounted) {
      setState(() {
        _active = refreshedActive;
        _completed = refreshedCompleted;
        _loading = false;
      });
    }
  }

  Future<int> _getProgress(Map<String, dynamic> challenge) async {
    final start = DateTime.parse(challenge['start_date'] as String);
    final end = DateTime.parse(challenge['end_date'] as String).add(const Duration(days: 1));
    final type = challenge['type'] as String;

    switch (type) {
      case 'streak_days':
        return await DatabaseHelper.instance.getStreakDaysBetween(start, end);
      case 'total_minutes':
        return await DatabaseHelper.instance.getTotalMinutesBetween(start, end);
      case 'session_count':
        return await DatabaseHelper.instance.getSessionCountBetween(start, end);
      default:
        return 0;
    }
  }

  Future<void> _startChallenge(Map<String, dynamic> template) async {
    final now = DateTime.now();
    final end = now.add(Duration(days: template['days'] as int));
    await DatabaseHelper.instance.insertChallenge({
      'title': template['title'],
      'description': template['description'],
      'type': template['type'],
      'target_value': template['target'],
      'start_date': DateTime(now.year, now.month, now.day).toIso8601String(),
      'end_date': DateTime(end.year, end.month, end.day).toIso8601String(),
      'completed': 0,
    });
    _load();
  }

  String _daysLeft(String endDate) {
    final end = DateTime.parse(endDate);
    final now = DateTime.now();
    final diff = end.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff <= 0) return 'Last day';
    if (diff == 1) return '1 day left';
    return '$diff days left';
  }

  String _unitFor(String type) {
    switch (type) {
      case 'streak_days':
        return 'days';
      case 'total_minutes':
        return 'min';
      case 'session_count':
        return 'sessions';
      default:
        return '';
    }
  }

  void _showCreateSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nameController = TextEditingController();
    bool nameValid = false;
    String type = 'session_count';
    int target = 10;
    int days = 7;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
          final keyboardPadding = MediaQuery.of(ctx).viewInsets.bottom;

          final typeOptions = [
            ('session_count', 'Sessions', Icons.check_circle_outline_rounded),
            ('total_minutes', 'Minutes', Icons.schedule_rounded),
            ('streak_days', 'Streak Days', Icons.local_fire_department_rounded),
          ];

          final targetPresets = switch (type) {
            'session_count' => [5, 10, 20, 30],
            'total_minutes' => [30, 60, 120, 240],
            _ => [3, 7, 14, 30],
          };

          final unit = _unitFor(type);

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottomPadding + keyboardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withAlpha(40),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Create Challenge',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Challenge name', isDense: true),
                  onChanged: (v) => setSheet(() => nameValid = v.trim().isNotEmpty),
                ),
                const SizedBox(height: 16),
                Text('Metric', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withAlpha(100))),
                const SizedBox(height: 8),
                Row(
                  children: typeOptions.map((opt) {
                    final selected = type == opt.$1;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: opt.$1 != 'streak_days' ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setSheet(() {
                            type = opt.$1;
                            target = switch (opt.$1) {
                              'session_count' => 10,
                              'total_minutes' => 60,
                              _ => 7,
                            };
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? cs.primary.withAlpha(20) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? cs.primary.withAlpha(100) : cs.outline.withAlpha(80)),
                            ),
                            child: Column(
                              children: [
                                Icon(opt.$3, size: 18, color: selected ? cs.primary : cs.onSurface.withAlpha(100)),
                                const SizedBox(height: 4),
                                Text(opt.$2, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? cs.primary : cs.onSurface.withAlpha(120)), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Target ($unit)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withAlpha(100))),
                const SizedBox(height: 8),
                Row(
                  children: targetPresets.map((v) {
                    final selected = target == v;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setSheet(() => target = v),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? cs.primary.withAlpha(20) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? cs.primary.withAlpha(100) : cs.outline.withAlpha(80)),
                          ),
                          child: Text('$v', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? cs.primary : cs.onSurface.withAlpha(120))),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Duration', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withAlpha(100))),
                const SizedBox(height: 8),
                Row(
                  children: [7, 14, 21, 30].map((d) {
                    final selected = days == d;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setSheet(() => days = d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? cs.primary.withAlpha(20) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? cs.primary.withAlpha(100) : cs.outline.withAlpha(80)),
                          ),
                          child: Text('${d}d', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? cs.primary : cs.onSurface.withAlpha(120))),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: !nameValid ? null : () async {
                      Navigator.pop(ctx);
                      await _startChallenge({
                        'title': nameController.text.trim(),
                        'description': 'Reach $target $unit in ${days} days',
                        'type': type,
                        'target': target,
                        'days': days,
                      });
                    },
                    child: const Text('Create Challenge'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Create custom challenge',
              onPressed: () => _showCreateSheet(context),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                // Active challenges
                if (_active.isNotEmpty) ...[
                  Text('Active', style: tt.headlineMedium),
                  const SizedBox(height: 12),
                  ..._active.map((c) => _ActiveChallengeTile(
                        challenge: c,
                        getProgress: _getProgress,
                        daysLeft: _daysLeft(c['end_date'] as String),
                        unit: _unitFor(c['type'] as String),
                        onDelete: () async {
                          await DatabaseHelper.instance.deleteChallenge(c['id'] as int);
                          _load();
                        },
                      )),
                  const SizedBox(height: 28),
                ],

                // Start a challenge
                Text('Start a Challenge', style: tt.headlineMedium),
                const SizedBox(height: 6),
                Text('Pick a goal and track your progress',
                    style: tt.bodySmall),
                const SizedBox(height: 16),
                ..._templates.map((t) => _TemplateTile(
                      template: t,
                      onStart: () => _startChallenge(t),
                    )),

                // Completed
                if (_completed.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('Completed', style: tt.headlineMedium),
                  const SizedBox(height: 12),
                  ..._completed.map((c) => _CompletedTile(challenge: c)),
                ],
              ],
            ),
    );
  }
}

class _ActiveChallengeTile extends StatefulWidget {
  final Map<String, dynamic> challenge;
  final Future<int> Function(Map<String, dynamic>) getProgress;
  final String daysLeft;
  final String unit;
  final VoidCallback onDelete;

  const _ActiveChallengeTile({
    required this.challenge,
    required this.getProgress,
    required this.daysLeft,
    required this.unit,
    required this.onDelete,
  });

  @override
  State<_ActiveChallengeTile> createState() => _ActiveChallengeTileState();
}

class _ActiveChallengeTileState extends State<_ActiveChallengeTile> {
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final p = await widget.getProgress(widget.challenge);
    if (mounted) setState(() => _progress = p);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final target = widget.challenge['target_value'] as int;
    final progress = (_progress / target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.challenge['title'] as String,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(widget.daysLeft,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.primary)),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(Icons.close_rounded,
                      size: 18, color: cs.onSurface.withAlpha(60)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(widget.challenge['description'] as String,
                style: GoogleFonts.inter(
                    fontSize: 12, color: cs.onSurface.withAlpha(100))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: cs.primary.withAlpha(20),
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$_progress / $target ${widget.unit}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final Map<String, dynamic> template;
  final VoidCallback onStart;

  const _TemplateTile({required this.template, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onStart,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withAlpha(80)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.flag_rounded, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template['title'] as String,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      template['description'] as String,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: cs.onSurface.withAlpha(100)),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${template['days']}d',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
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

class _CompletedTile extends StatelessWidget {
  final Map<String, dynamic> challenge;

  const _CompletedTile({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.primary.withAlpha(8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withAlpha(30)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(challenge['title'] as String,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface)),
            ),
            Text(
              'Done',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.primary),
            ),
          ],
        ),
      ),
    );
  }
}
