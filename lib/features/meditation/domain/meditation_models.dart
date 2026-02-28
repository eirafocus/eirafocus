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

class MeditationSession {
  final int? id;
  final String type; // 'Breathing' or 'Meditation'
  final String method;
  final int durationSeconds;
  final DateTime timestamp;

  const MeditationSession({
    this.id,
    required this.type,
    required this.method,
    required this.durationSeconds,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'method': method,
      'duration_seconds': durationSeconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MeditationSession.fromMap(Map<String, dynamic> map) {
    return MeditationSession(
      id: map['id'],
      type: map['type'],
      method: map['method'],
      durationSeconds: map['duration_seconds'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
