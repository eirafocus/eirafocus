import 'package:flutter/material.dart';
import 'package:eirafocus/features/breathing/domain/breathing_method.dart';
import 'package:eirafocus/features/breathing/presentation/breathing_session_screen.dart';
import 'package:eirafocus/features/breathing/presentation/breath_hold_test_screen.dart';

class BreathingScreen extends StatelessWidget {
  const BreathingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathing Exercises'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTestCard(context),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
            child: Text(
              'Predefined Methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ...BreathingMethod.predefinedMethods.map((method) => _buildMethodCard(context, method)).toList(),
        ],
      ),
    );
  }

  Widget _buildTestCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Icon(Icons.timer_outlined, size: 40, color: Theme.of(context).colorScheme.primary),
        title: const Text(
          'Breath Hold Test',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Test your maximum breath retention time.'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const BreathHoldTestScreen()),
          );
        },
      ),
    );
  }

  Widget _buildMethodCard(BuildContext context, BreathingMethod method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          method.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            method.description,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        trailing: Icon(
          Icons.play_circle_fill,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BreathingSessionScreen(method: method),
            ),
          );
        },
      ),
    );
  }
}
