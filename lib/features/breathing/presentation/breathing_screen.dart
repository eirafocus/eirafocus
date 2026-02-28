import 'package:flutter/material.dart';
import 'package:eirafocus/features/breathing/domain/breathing_method.dart';
import 'package:eirafocus/features/breathing/presentation/breathing_session_screen.dart';

class BreathingScreen extends StatelessWidget {
  const BreathingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathing Exercises'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: BreathingMethod.predefinedMethods.length,
        itemBuilder: (context, index) {
          final method = BreathingMethod.predefinedMethods[index];
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
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
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
        },
      ),
    );
  }
}
