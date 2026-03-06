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

  static const List<String> _emojis = [
    '\u{1F9D8}', // Calm - meditation
    '\u{1F3AF}', // Focused - target
    '\u{26A1}',  // Stressed - lightning
    '\u{1F634}', // Sleepy - sleeping
    '\u{1F525}', // Energized - fire
    '\u{1F30A}', // Anxious - wave
    '\u{2764}',  // Grateful - heart
    '\u{2600}',  // Morning - sun
    '\u{1F319}', // Evening - moon
    '\u{2615}',  // Quick Break - coffee
  ];

  static String emojiFor(String label) {
    final i = availableLabels.indexOf(label);
    return i >= 0 ? _emojis[i] : '\u{1F3F7}';
  }
}

class MeditationSession {
  final int? id;
  final String type; // 'Breathing' or 'Meditation'
  final String method;
  final int durationSeconds;
  final DateTime timestamp;
  final String? journal;
  final List<String> tags;

  const MeditationSession({
    this.id,
    required this.type,
    required this.method,
    required this.durationSeconds,
    required this.timestamp,
    this.journal,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'method': method,
      'duration_seconds': durationSeconds,
      'timestamp': timestamp.toIso8601String(),
      if (journal != null) 'journal': journal,
      if (tags.isNotEmpty) 'tags': tags.join(','),
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
    );
  }
}
