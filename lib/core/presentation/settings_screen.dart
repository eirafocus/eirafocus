import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eirafocus/core/theme/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

// ─── Settings tile ──────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
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
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurface.withAlpha(60)),
          ],
        ),
      ),
    );
  }
}
