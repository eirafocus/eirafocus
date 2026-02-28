import 'package:flutter/material.dart';
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
        const SnackBar(content: Text('Please enter a name for your method')),
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

    if (mounted) {
      Navigator.pop(context, true); // Return true to signal refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Custom Method')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Method Name',
                hintText: 'e.g. Morning Calm',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            _buildSliderSection('Inhale', _inhale, (val) => setState(() => _inhale = val.toInt())),
            _buildSliderSection('Hold (After Inhale)', _holdIn, (val) => setState(() => _holdIn = val.toInt())),
            _buildSliderSection('Exhale', _exhale, (val) => setState(() => _exhale = val.toInt())),
            _buildSliderSection('Hold (After Exhale)', _holdOut, (val) => setState(() => _holdOut = val.toInt())),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveMethod,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('SAVE METHOD', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection(String label, int value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('$value seconds', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 20,
          divisions: 20,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
