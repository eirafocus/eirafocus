import 'package:flutter/material.dart';
import 'package:eirafocus/features/breathing/domain/breathing_method.dart';
import 'package:eirafocus/features/breathing/presentation/breathing_session_screen.dart';
import 'package:eirafocus/features/breathing/presentation/breath_hold_test_screen.dart';
import 'package:eirafocus/features/breathing/presentation/custom_breathing_screen.dart';
import 'package:eirafocus/core/data/database_helper.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> {
  late Future<List<Map<String, dynamic>>> _customMethodsFuture;

  @override
  void initState() {
    super.initState();
    _refreshCustomMethods();
  }

  void _refreshCustomMethods() {
    setState(() {
      _customMethodsFuture = DatabaseHelper.instance.getCustomMethods();
    });
  }

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
          const SizedBox(height: 32),
          _buildCustomHeader(context),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _customMethodsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final methods = snapshot.data ?? [];
              if (methods.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No custom methods yet.', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }
              return Column(
                children: methods.map((m) => _buildCustomCard(context, m)).toList(),
              );
            },
          ),
          const SizedBox(height: 32),
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

  Widget _buildCustomHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Custom Methods',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CustomBreathingScreen()),
            );
            if (result == true) {
              _refreshCustomMethods();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('New Method'),
        ),
      ],
    );
  }

  Widget _buildCustomCard(BuildContext context, Map<String, dynamic> m) {
    final method = BreathingMethod(
      name: m['name'],
      description: 'Custom pattern: ${m['inhale']}-${m['hold_after_inhale']}-${m['exhale']}-${m['hold_after_exhale']}',
      inhaleDuration: m['inhale'],
      holdDuration: m['hold_after_inhale'],
      exhaleDuration: m['exhale'],
      holdAfterExhaleDuration: m['hold_after_exhale'],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(method.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(method.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                await DatabaseHelper.instance.deleteCustomMethod(m['id']);
                _refreshCustomMethods();
              },
            ),
            Icon(Icons.play_circle_fill, size: 32, color: Theme.of(context).colorScheme.primary),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => BreathingSessionScreen(method: method)),
          );
        },
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
