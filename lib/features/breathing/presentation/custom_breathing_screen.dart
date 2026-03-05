import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/core/data/database_helper.dart';

class CustomBreathingScreen extends StatefulWidget {
  const CustomBreathingScreen({super.key});

  @override
  State<CustomBreathingScreen> createState() => _CustomBreathingScreenState();
}

class _CustomBreathingScreenState extends State<CustomBreathingScreen> {
  final _nameController = TextEditingController();
  int _inhale = 4;
  int _holdIn = 4;
  int _exhale = 4;
  int _holdOut = 4;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveMethod() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }
    await DatabaseHelper.instance.insertCustomMethod({
      'name': _nameController.text.trim(),
      'inhale': _inhale,
      'hold_after_inhale': _holdIn,
      'exhale': _exhale,
      'hold_after_exhale': _holdOut,
    });
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final totalCycle = _inhale + _holdIn + _exhale + _holdOut;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Pattern')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name', style: tt.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Morning Calm',
              ),
            ),

            const SizedBox(height: 32),

            // Pattern visualizer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.primary.withAlpha(40)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PatternPhase(label: 'IN', value: _inhale, color: EiraTheme.breathingColor),
                      _PatternDot(),
                      _PatternPhase(label: 'HOLD', value: _holdIn, color: EiraTheme.meditationColor),
                      _PatternDot(),
                      _PatternPhase(label: 'OUT', value: _exhale, color: EiraTheme.statsColor),
                      _PatternDot(),
                      _PatternPhase(label: 'HOLD', value: _holdOut, color: EiraTheme.historyColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${totalCycle}s per cycle',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: cs.onSurface.withAlpha(100),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Sliders
            _buildSlider(context, 'Inhale', _inhale, EiraTheme.breathingColor,
                (v) => setState(() => _inhale = v.toInt())),
            _buildSlider(context, 'Hold after inhale', _holdIn, EiraTheme.meditationColor,
                (v) => setState(() => _holdIn = v.toInt())),
            _buildSlider(context, 'Exhale', _exhale, EiraTheme.statsColor,
                (v) => setState(() => _exhale = v.toInt())),
            _buildSlider(context, 'Hold after exhale', _holdOut, EiraTheme.historyColor,
                (v) => setState(() => _holdOut = v.toInt())),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveMethod,
                child: const Text('Save Pattern'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(BuildContext context, String label, int value, Color color,
      ValueChanged<double> onChanged) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value}s',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withAlpha(30),
              thumbColor: color,
              overlayColor: color.withAlpha(25),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 20,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternPhase extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _PatternPhase({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value}s',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _PatternDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withAlpha(50),
        shape: BoxShape.circle,
      ),
    );
  }
}
