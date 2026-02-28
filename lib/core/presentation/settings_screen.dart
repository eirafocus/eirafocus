import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: const Text('The app follows your system theme'),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('EiraFocus automatically matches your device Light/Dark mode.')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Notice'),
            onTap: () => _showPrivacyNotice(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About EiraFocus'),
            subtitle: const Text('Version 1.0.0'),
          ),
          const SizedBox(height: 40),
          Center(
            child: Opacity(
              opacity: 0.5,
              child: Image.asset('assets/eirafocus.png', width: 60),
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Focus on what matters.', style: TextStyle(fontStyle: FontStyle.italic)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyNotice(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Notice'),
        content: const SingleChildScrollView(
          child: Text(
            'EiraFocus is built with privacy as a priority.

'
            '• All your session data (breathing and meditation history) is stored locally on your device.
'
            '• No data is ever uploaded to a server or shared with third parties.
'
            '• The app works entirely offline.
'
            '• No analytics tracking is performed.

'
            'Your data, your peace of mind.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}
