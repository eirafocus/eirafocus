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
      description: 'A 10-minute journey focusing on every part of your body.',
      totalDuration: Duration(minutes: 10),
      prompts: [
        GuidedPrompt(timestamp: Duration(seconds: 0), text: "Find a comfortable seat. Close your eyes. Take a deep breath. We will begin our body scan journey."),
        GuidedPrompt(timestamp: Duration(seconds: 15), text: "Bring your full attention to the soles of your feet. Notice any tingling or warmth."),
        GuidedPrompt(timestamp: Duration(seconds: 35), text: "Move your focus up to your ankles. Let them go soft and heavy."),
        GuidedPrompt(timestamp: Duration(seconds: 55), text: "Slowly move up to your shins and calves. Let the muscles relax."),
        GuidedPrompt(timestamp: Duration(seconds: 80), text: "Bring awareness to your knees. Notice any tension, and let it dissolve."),
        GuidedPrompt(timestamp: Duration(seconds: 105), text: "Now focus on your thighs. Feel the weight of them against the seat."),
        GuidedPrompt(timestamp: Duration(seconds: 130), text: "Shift your focus to your hips and lower back. Imagine a warm light loosening the muscles there."),
        GuidedPrompt(timestamp: Duration(seconds: 160), text: "Now move to your stomach. Feel it rise and fall with each breath."),
        GuidedPrompt(timestamp: Duration(seconds: 190), text: "Bring awareness to your chest. Feel the expansion of your lungs."),
        GuidedPrompt(timestamp: Duration(seconds: 220), text: "Focus on your hands and fingers. Let them curl naturally. Release all effort."),
        GuidedPrompt(timestamp: Duration(seconds: 250), text: "Move up to your wrists and forearms. Soften them."),
        GuidedPrompt(timestamp: Duration(seconds: 280), text: "Focus on your shoulders. Let them drop away from your ears."),
        GuidedPrompt(timestamp: Duration(seconds: 310), text: "Bring attention to your neck. Move it slightly if it feels tight."),
        GuidedPrompt(timestamp: Duration(seconds: 340), text: "Finally, focus on your jaw and face. Soften your eyes. Relax your brow."),
        GuidedPrompt(timestamp: Duration(seconds: 380), text: "Feel your whole body as one. Stable. Calm. At peace."),
        GuidedPrompt(timestamp: Duration(seconds: 450), text: "Stay with this feeling of total relaxation. Breathe naturally."),
        GuidedPrompt(timestamp: Duration(seconds: 580), text: "We are now concluding the body scan. When you are ready, gently open your eyes."),
      ],
    ),
    MeditationJourney(
      name: 'Mantra: So-Hum',
      description: 'A rhythmic meditation using the mantra of being.',
      totalDuration: Duration(minutes: 5),
      prompts: [
        GuidedPrompt(timestamp: Duration(seconds: 0), text: "We will use the mantra So-Hum. It means 'I am that'."),
        GuidedPrompt(timestamp: Duration(seconds: 15), text: "As you inhale, silently say 'So'. As you exhale, silently say 'Hum'."),
        GuidedPrompt(timestamp: Duration(seconds: 30), text: "Inhale... So. Exhale... Hum."),
        GuidedPrompt(timestamp: Duration(seconds: 50), text: "Continue the rhythm. So... Hum."),
        GuidedPrompt(timestamp: Duration(seconds: 75), text: "If your mind wanders, gently bring it back to the sound. So... Hum."),
        GuidedPrompt(timestamp: Duration(seconds: 100), text: "Breathe in 'So'. Breathe out 'Hum'."),
        GuidedPrompt(timestamp: Duration(seconds: 125), text: "So... Hum. Let the sound fill your mind."),
        GuidedPrompt(timestamp: Duration(seconds: 150), text: "I am that. So... Hum."),
        GuidedPrompt(timestamp: Duration(seconds: 180), text: "So... Hum. Calm and steady."),
        GuidedPrompt(timestamp: Duration(seconds: 210), text: "Rest in the silence of the mantra. So... Hum."),
        GuidedPrompt(timestamp: Duration(seconds: 240), text: "So... Hum."),
        GuidedPrompt(timestamp: Duration(seconds: 285), text: "Gently let go of the mantra. Sit in the quiet for a moment before finishing."),
      ],
    ),
  ];
}
