import 'package:flutter/material.dart';

class MeditationPrompt {
  final String text;
  final Duration interval;

  const MeditationPrompt({
    required this.text,
    required this.interval,
  });

  static const List<MeditationPrompt> defaultPrompts = [
    MeditationPrompt(text: "Focus on your breath.", interval: Duration(seconds: 0)),
    MeditationPrompt(text: "Let go of any tension in your shoulders.", interval: Duration(seconds: 60)),
    MeditationPrompt(text: "Acknowledge your thoughts, then let them pass.", interval: Duration(seconds: 120)),
    MeditationPrompt(text: "Bring your attention back to the present moment.", interval: Duration(seconds: 180)),
    MeditationPrompt(text: "Inhale peace, exhale stress.", interval: Duration(seconds: 240)),
  ];
}

class SessionTag {
  static const List<String> availableLabels = [
    'Calm',
    'Focused',
    'Stressed',
    'Sleepy',
    'Energized',
    'Anxious',
    'Grateful',
    'Morning',
    'Evening',
    'Quick Break',
  ];

  static const List<IconData> _icons = [
    Icons.spa_rounded,              // Calm
    Icons.gps_fixed_rounded,        // Focused
    Icons.bolt_rounded,             // Stressed
    Icons.bedtime_rounded,          // Sleepy
    Icons.local_fire_department_rounded, // Energized
    Icons.waves_rounded,            // Anxious
    Icons.favorite_rounded,         // Grateful
    Icons.wb_sunny_rounded,         // Morning
    Icons.nightlight_round,         // Evening
    Icons.coffee_rounded,           // Quick Break
  ];

  static IconData iconFor(String label) {
    final i = availableLabels.indexOf(label);
    return i >= 0 ? _icons[i] : Icons.label_rounded;
  }

  // Keep for DB backwards-compat
  static String emojiFor(String label) => label;
}

class MoodData {
  static const labels = ['Awful', 'Bad', 'Okay', 'Good', 'Great'];

  static const moodColors = [
    Color(0xFFEF5350), // Awful  - red
    Color(0xFFFF7043), // Bad    - orange
    Color(0xFFFFB300), // Okay   - amber
    Color(0xFF66BB6A), // Good   - light green
    Color(0xFF2E7D32), // Great  - green
  ];
}

class MeditationSession {
  final int? id;
  final String type; // 'Breathing' or 'Meditation'
  final String method;
  final int durationSeconds;
  final DateTime timestamp;
  final String? journal;
  final List<String> tags;
  final int? moodBefore; // 1-5
  final int? moodAfter;  // 1-5

  const MeditationSession({
    this.id,
    required this.type,
    required this.method,
    required this.durationSeconds,
    required this.timestamp,
    this.journal,
    this.tags = const [],
    this.moodBefore,
    this.moodAfter,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'method': method,
      'duration_seconds': durationSeconds,
      'timestamp': timestamp.toIso8601String(),
      if (journal != null) 'journal': journal,
      if (tags.isNotEmpty) 'tags': tags.join(','),
      if (moodBefore != null) 'mood_before': moodBefore,
      if (moodAfter != null) 'mood_after': moodAfter,
    };
  }

  factory MeditationSession.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['tags'] as String?;
    return MeditationSession(
      id: map['id'],
      type: map['type'],
      method: map['method'],
      durationSeconds: map['duration_seconds'],
      timestamp: DateTime.parse(map['timestamp']),
      journal: map['journal'] as String?,
      tags: tagsStr != null && tagsStr.isNotEmpty ? tagsStr.split(',') : [],
      moodBefore: map['mood_before'] as int?,
      moodAfter: map['mood_after'] as int?,
    );
  }
}
