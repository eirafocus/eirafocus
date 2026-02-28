enum BreathingStage { inhale, hold, exhale, holdAfterExhale }

class BreathingMethod {
  final String name;
  final String description;
  final int inhaleDuration;
  final int holdDuration;
  final int exhaleDuration;
  final int holdAfterExhaleDuration;

  const BreathingMethod({
    required this.name,
    required this.description,
    required this.inhaleDuration,
    this.holdDuration = 0,
    required this.exhaleDuration,
    this.holdAfterExhaleDuration = 0,
  });

  int get totalDurationPerCycle =>
      inhaleDuration + holdDuration + exhaleDuration + holdAfterExhaleDuration;

  static const List<BreathingMethod> predefinedMethods = [
    BreathingMethod(
      name: 'Equal Breathing',
      description: 'Inhale and exhale for the same duration to balance your energy.',
      inhaleDuration: 4,
      exhaleDuration: 4,
    ),
    BreathingMethod(
      name: 'Box Breathing',
      description: 'Used by Navy SEALs to stay calm under pressure.',
      inhaleDuration: 4,
      holdDuration: 4,
      exhaleDuration: 4,
      holdAfterExhaleDuration: 4,
    ),
    BreathingMethod(
      name: '4-7-8 Breathing',
      description: 'A relaxing technique that can help you fall asleep.',
      inhaleDuration: 4,
      holdDuration: 7,
      exhaleDuration: 8,
    ),
  ];
}
