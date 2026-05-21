class LongevityCalculator {
  static double _getBaseAnnualSurvival(int age) {
    if (age < 40) return 0.998;
    if (age < 60) return 0.992;
    if (age < 75) return 0.975;
    if (age < 85) return 0.940;
    return 0.880;
  }

  static double _getLifestyleMultiplier({
    required bool smokes, required double bmi, required String activity, 
    required int sleepHours, required bool isOptimized,
  }) {
    if (isOptimized) return 1.01;
    double m = 1.0;
    if (smokes) m *= 0.99;
    if (bmi > 30) m *= 0.992; else if (bmi > 25) m *= 0.996;
    if (activity == 'low') m *= 0.993; else if (activity == 'high') m *= 1.003;
    if (sleepHours < 6 || sleepHours > 9) m *= 0.997;
    return m.clamp(0.94, 1.02);
  }

  static int calculateProbability({
    required int bioAge, required int targetAge,
    required bool smokes, required double bmi, required String activity,
    required int sleepHours, required bool isOptimized,
  }) {
    if (targetAge <= bioAge) return 99;
    final years = targetAge - bioAge;
    double prob = 1.0;
    final mult = _getLifestyleMultiplier(smokes: smokes, bmi: bmi, activity: activity, sleepHours: sleepHours, isOptimized: isOptimized);
    for (int i = 0; i < years; i++) {
      prob *= _getBaseAnnualSurvival(bioAge + i) * mult;
    }
    // ✅ ИСПРАВЛЕНО: вернул умножение на 100 для перевода доли в проценты
    return (prob * 100).round().clamp(2, 98);
  }

  static int calculateExpectedLifespan({
    required int bioAge, required bool smokes, required double bmi,
    required String activity, required int sleepHours, required bool isOptimized,
  }) {
    final optimistic = _calculateRaw(bioAge, false, 22.0, 'high', 7, true);
    final rawCurrent = _calculateRaw(bioAge, smokes, bmi, activity, sleepHours, false);
    
    const maxDiff = 10.0;
    const minBuffer = 5;
    final rawDiff = optimistic - rawCurrent;
    final cappedDiff = rawDiff > maxDiff ? maxDiff : rawDiff;
    final adjusted = optimistic - cappedDiff;
    
    return adjusted.clamp(bioAge + minBuffer, 95.0).clamp(0, optimistic).round();
  }
  
  static int _calculateRaw(int bioAge, bool smokes, double bmi, String activity, int sleepHours, bool isOptimized) {
    final mult = _getLifestyleMultiplier(smokes: smokes, bmi: bmi, activity: activity, sleepHours: sleepHours, isOptimized: isOptimized);
    double prob = 1.0;
    for (int age = bioAge; age < 120; age++) {
      prob *= _getBaseAnnualSurvival(age) * mult;
      if (prob < 0.50) return age;
    }
    return 119;
  }
}