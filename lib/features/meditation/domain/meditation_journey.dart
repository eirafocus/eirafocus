class GuidedPrompt {
  final Duration timestamp;
  final String text;

  const GuidedPrompt({required this.timestamp, required this.text});
}

class MeditationJourney {
  final String name;
  final String description;
  final List<GuidedPrompt> prompts;
  final Duration totalDuration;

  const MeditationJourney({
    required this.name,
    required this.description,
    required this.prompts,
    required this.totalDuration,
  });

  static const List<MeditationJourney> journeys = [
    MeditationJourney(
      name: 'Body Scan',
      description: 'A journey through physical sensations to ground yourself.',
      totalDuration: Duration(minutes: 10),
      prompts: [
        GuidedPrompt(timestamp: Duration(seconds: 0), text: "Welcome to this Body Scan meditation. Close your eyes and take a deep breath."),
        GuidedPrompt(timestamp: Duration(seconds: 15), text: "Begin by bringing your attention to your feet. Notice any sensation, warmth, or pressure."),
        GuidedPrompt(timestamp: Duration(seconds: 60), text: "Slowly move your focus up to your knees and thighs. Let any tension melt away."),
        GuidedPrompt(timestamp: Duration(seconds: 120), text: "Now, feel the weight of your body against the surface you are sitting on."),
        GuidedPrompt(timestamp: Duration(seconds: 180), text: "Bring your attention to your lower back and stomach. Inhale deeply, exhaling any stress."),
        GuidedPrompt(timestamp: Duration(seconds: 300), text: "Move up to your chest and shoulders. Let them drop and relax."),
        GuidedPrompt(timestamp: Duration(seconds: 420), text: "Finally, focus on your face and head. Soften your jaw and brow."),
        GuidedPrompt(timestamp: Duration(seconds: 540), text: "Take a few final deep breaths, feeling your entire body at peace."),
      ],
    ),
    MeditationJourney(
      name: 'Loving-Kindness (Metta)',
      description: 'Cultivate compassion for yourself and others.',
      totalDuration: Duration(minutes: 5),
      prompts: [
        GuidedPrompt(timestamp: Duration(seconds: 0), text: "Find a comfortable position. We will begin by focusing on ourselves."),
        GuidedPrompt(timestamp: Duration(seconds: 30), text: "Silently repeat: May I be happy. May I be healthy. May I be safe. May I live with ease."),
        GuidedPrompt(timestamp: Duration(seconds: 90), text: "Now, think of someone you love. Visualize them clearly."),
        GuidedPrompt(timestamp: Duration(seconds: 120), text: "Direct these same thoughts to them: May you be happy. May you be healthy. May you be safe."),
        GuidedPrompt(timestamp: Duration(seconds: 180), text: "Now, expand this to all beings everywhere. May all beings be happy."),
        GuidedPrompt(timestamp: Duration(seconds: 270), text: "Rest in this feeling of universal compassion as we conclude."),
      ],
    ),
  ];
}
