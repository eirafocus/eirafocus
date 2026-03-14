import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/core/data/database_helper.dart';
import 'package:eirafocus/core/services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _weeklyGoal = 0;
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final goal = await DatabaseHelper.instance.getWeeklyGoal();
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('reminders_enabled') ?? false;
    final hour = prefs.getInt('reminder_hour') ?? 9;
    final minute = prefs.getInt('reminder_minute') ?? 0;
    if (mounted) {
      setState(() {
        _weeklyGoal = goal ?? 0;
        _remindersEnabled = enabled;
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
      });
    }
  }

  Future<void> _saveWeeklyGoal(int minutes) async {
    setState(() => _weeklyGoal = minutes);
    if (minutes > 0) {
      await DatabaseHelper.instance.setWeeklyGoal(minutes);
    }
  }

  Future<void> _toggleReminders(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', enabled);
    setState(() => _remindersEnabled = enabled);
    if (enabled) {
      await NotificationService.instance.scheduleDailyReminder(
        _reminderTime.hour,
        _reminderTime.minute,
      );
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('reminder_hour', picked.hour);
      await prefs.setInt('reminder_minute', picked.minute);
      if (_remindersEnabled) {
        await NotificationService.instance.scheduleDailyReminder(
          picked.hour,
          picked.minute,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          // Theme picker
          _SectionLabel('Appearance'),
          const SizedBox(height: 10),
          _ThemePicker(
            currentMode: currentMode,
            onChanged: (mode) {
              ref.read(themeModeProvider.notifier).setMode(mode);
            },
          ),
          const SizedBox(height: 12),
          _AccentColorPicker(
            currentIndex: ref.watch(accentColorProvider),
            onChanged: (idx) {
              ref.read(accentColorProvider.notifier).setIndex(idx);
            },
          ),

          const SizedBox(height: 24),

          // Weekly goal
          _SectionLabel('Weekly Goal'),
          const SizedBox(height: 10),
          _GoalSetting(
            currentGoal: _weeklyGoal,
            onChanged: _saveWeeklyGoal,
          ),

          const SizedBox(height: 24),

          // Reminders
          _SectionLabel('Daily Reminder'),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Daily Reminder',
            subtitle: _remindersEnabled
                ? 'Every day at ${_reminderTime.format(context)}'
                : 'Off',
            trailing: Switch.adaptive(
              value: _remindersEnabled,
              onChanged: _toggleReminders,
              activeTrackColor: cs.primary,
            ),
          ),
          if (_remindersEnabled) ...[
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.schedule_rounded,
              title: 'Reminder Time',
              subtitle: _reminderTime.format(context),
              onTap: _pickReminderTime,
            ),
          ],

          const SizedBox(height: 24),

          _SectionLabel('General'),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: 'Privacy',
            subtitle: 'Your data never leaves this device',
            onTap: () => _showPrivacy(context),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About',
            subtitle: 'EiraFocus v1.0.0',
          ),

          const SizedBox(height: 24),

          // Developer tools
          _SectionLabel('Developer'),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.science_outlined,
            title: 'Simulate Missed Day',
            subtitle: 'Shifts streak back 2 days to test freeze card',
            onTap: () async {
              await DatabaseHelper.instance.debugSimulateMissedDay();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Done — go to Dashboard to see freeze card')),
                );
              }
            },
          ),

          const SizedBox(height: 56),

          // Footer
          Center(
            child: Column(
              children: [
                Opacity(
                  opacity: 0.4,
                  child: Image.asset('assets/eirafocus.png', width: 40),
                ),
                const SizedBox(height: 8),
                Text(
                  'Breathe. Focus. Grow.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: cs.onSurface.withAlpha(70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy'),
        content: const SingleChildScrollView(
          child: Text(
            'EiraFocus stores all data locally on your device.\n\n'
            '\u2022  No servers, no cloud uploads\n'
            '\u2022  Works fully offline\n'
            '\u2022  No analytics or tracking\n'
            '\u2022  Delete anytime from app storage\n\n'
            'Your data, your peace of mind.',
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ──────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(90),
      ),
    );
  }
}

// ─── Goal Setting ───────────────────────────────────────────────
class _GoalSetting extends StatelessWidget {
  final int currentGoal;
  final ValueChanged<int> onChanged;

  const _GoalSetting({required this.currentGoal, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final presets = [0, 5, 15, 30, 60, 90, 120, 180];

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
              Icon(Icons.flag_rounded, size: 20, color: cs.primary),
              const SizedBox(width: 10),
              Text(
                currentGoal > 0 ? '$currentGoal min / week' : 'No goal set',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((m) {
              final selected = currentGoal == m;
              final label = m == 0 ? 'Off' : '${m}m';
              return GestureDetector(
                onTap: () => onChanged(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary.withAlpha(20) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? cs.primary.withAlpha(80) : cs.outline.withAlpha(80),
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? cs.primary : cs.onSurface.withAlpha(120),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Theme picker ───────────────────────────────────────────────
class _ThemePicker extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemePicker({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withAlpha(80)),
      ),
      child: Row(
        children: [
          _buildOption(context, Icons.phone_android_rounded, 'System', ThemeMode.system),
          const SizedBox(width: 4),
          _buildOption(context, Icons.light_mode_rounded, 'Light', ThemeMode.light),
          const SizedBox(width: 4),
          _buildOption(context, Icons.dark_mode_rounded, 'Dark', ThemeMode.dark),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String label, ThemeMode mode) {
    final cs = Theme.of(context).colorScheme;
    final selected = currentMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? cs.primary.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cs.primary.withAlpha(80) : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? cs.primary : cs.onSurface.withAlpha(100),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? cs.primary : cs.onSurface.withAlpha(100),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Accent color picker ────────────────────────────────────────
class _AccentColorPicker extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _AccentColorPicker({required this.currentIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final presets = AccentColorPreset.presets;

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
          Text(
            'Accent Color',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(presets.length, (i) {
              final preset = presets[i];
              final selected = currentIndex == i;
              return GestureDetector(
                onTap: () => onChanged(i),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: preset.primary,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: cs.onSurface, width: 3)
                            : null,
                        boxShadow: selected
                            ? [BoxShadow(color: preset.primary.withAlpha(60), blurRadius: 8, spreadRadius: 2)]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preset.name,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? cs.onSurface : cs.onSurface.withAlpha(100),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Settings tile ──────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
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
                color: cs.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface.withAlpha(100)),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurface.withAlpha(60)),
          ],
        ),
      ),
    );
  }
}
