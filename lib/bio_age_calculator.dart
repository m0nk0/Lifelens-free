import 'age_estimator.dart'; // ✅ Импорт для калибровки

class BioAgeResult {
  final int biologicalAge;
  final int chronologicalAge;
  final int ageDifference;
  final String riskLevel;
  final List<String> recommendations;
  final String disclaimer;
  
  final bool smokes;
  final double bmi;
  final String activity;
  final int sleepHours;
  
  final int calibratedFaceAge; // ✅ Калиброванный возраст модели (для плашки)

  BioAgeResult({
    required this.biologicalAge,
    required this.chronologicalAge,
    required this.ageDifference,
    required this.riskLevel,
    required this.recommendations,
    required this.disclaimer,
    required this.smokes,
    required this.bmi,
    required this.activity,
    required this.sleepHours,
    required this.calibratedFaceAge,
  });
}

class BioAgeCalculator {
  static const double aiWeight = 0.65;
  static const double chronoWeight = 0.35;
  static const double maxAiInfluence = 8.0;
  
  static const Map<String, double> penalties = {
    'smoking': 4.0,
    'obesity': 3.5,
    'overweight': 1.5,
    'low_activity': 2.0,
    'sleep_less': 2.0,
    'sleep_more': 1.0,
    'poor_lighting': 1.5,
  };

  static const String disclaimerText = 
    "⚠️ Расчёт является оценочным и основан на анализе визуальных маркеров возраста "
    "с учётом популяционных данных о влиянии привычек на долголетие. "
    "Не является медицинским диагнозом или клиническим заключением.";

  static BioAgeResult calculate({
    required int chronoAge,
    required String gender,
    required double heightCm,
    required double weightKg,
    required bool smokes,
    required int sleepHours,
    required String activity,
    required int faceAgeEstimate,
    required double faceBrightness,
    required double rawModelOutput, // ✅ Сырой вывод модели
  }) {
    // ✅ Калибруем возраст модели по паспортному возрасту
    final calibratedFaceAge = AgeEstimator.calibrateAge(rawModelOutput, chronoAge);
    
    print('🤖 [AI] Паспорт: $chronoAge | Калиброванный ИИ: $calibratedFaceAge | Освещённость: ${(faceBrightness*100).toInt()}%');

    // Используем калиброванное значение в формуле (вместо faceAgeEstimate)
    double rawDiff = (calibratedFaceAge - chronoAge).toDouble();
    double clampedAiDiff = rawDiff.clamp(-maxAiInfluence, maxAiInfluence);
    print('🤖 [AI] Сырая разница: $rawDiff → Ограничена до: $clampedAiDiff');

    double baseAge = chronoAge + (clampedAiDiff * aiWeight);
    print(' [BASE] Итог ИИ-влияния: ${baseAge.toStringAsFixed(1)} лет');

    double lifestylePenalty = 0.0;
    double bmi = weightKg / ((heightCm / 100) * (heightCm / 100));

    if (smokes) lifestylePenalty += penalties['smoking']!;
    if (bmi > 30) lifestylePenalty += penalties['obesity']!;
    else if (bmi > 25) lifestylePenalty += penalties['overweight']!;
    if (activity == 'low') lifestylePenalty += penalties['low_activity']!;
    if (sleepHours < 6) lifestylePenalty += penalties['sleep_less']!;
    else if (sleepHours > 9) lifestylePenalty += penalties['sleep_more']!;
    if (faceBrightness < 0.25 || faceBrightness > 0.85) {
      lifestylePenalty += penalties['poor_lighting']!;
    }
    print(' [LIFE] Сумма штрафов: +$lifestylePenalty');

    double totalBio = baseAge + lifestylePenalty;
    int bioAge = totalBio.round().clamp(16, 95);
    int finalDiff = bioAge - chronoAge;
    print('🧮 [FINAL] Био: $bioAge | Разница: $finalDiff');

    String riskLevel;
    List<String> recommendations = [];

    if (finalDiff <= -3) {
      riskLevel = "🌟 Отлично! Вы выглядите моложе своих лет";
      recommendations.add("Продолжайте текущий режим питания и активности");
      recommendations.add("Регулярные профилактические осмотры раз в год");
    } else if (finalDiff <= 2) {
      riskLevel = "✅ Норма: биологический возраст соответствует хронологическому";
      recommendations.add("Поддерживайте текущую физическую форму");
      recommendations.add("Следите за качеством сна (7-8 часов)");
    } else if (finalDiff <= 6) {
      riskLevel = "⚠️ Незначительное опережение: есть потенциал для улучшения";
      recommendations.add("Добавьте 30 мин кардио 3 раза в неделю");
      recommendations.add("Скорректируйте график сна");
      if (smokes) recommendations.add("Рассмотрите снижение дозы или отказ от курения");
    } else {
      riskLevel = "🔴 Внимание: биологический возраст значительно выше";
      recommendations.add("Пройдите комплексное обследование (сердце, сосуды, гормоны)");
      recommendations.add("Пересмотрите рацион и уровень стресса");
    }

    if (faceBrightness < 0.25 || faceBrightness > 0.85) {
      recommendations.add("💡 Для следующего замера используйте мягкий рассеянный свет спереди");
    }

    return BioAgeResult(
      biologicalAge: bioAge,
      chronologicalAge: chronoAge,
      ageDifference: finalDiff,
      riskLevel: riskLevel,
      recommendations: recommendations,
      disclaimer: disclaimerText,
      smokes: smokes,
      bmi: bmi,
      activity: activity,
      sleepHours: sleepHours,
      calibratedFaceAge: calibratedFaceAge, // ✅ Передаём калиброванное значение
    );
  }
}