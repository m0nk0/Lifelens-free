class BioAgeResult {
  final int biologicalAge;
  final int chronologicalAge;
  final String riskLevel;
  final List<String> recommendations;

  const BioAgeResult({
    required this.biologicalAge,
    required this.chronologicalAge,
    required this.riskLevel,
    required this.recommendations,
  });
}

class BioAgeCalculator {
  static BioAgeResult calculate({
    required int chronoAge,
    required String gender,
    required double heightCm,
    required double weightKg,
    required bool smokes,
    required int sleepHours,
    required String activity,
    required int faceAgeEstimate,
  }) {
    int bioAge = faceAgeEstimate;
    List<String> recs = [];

    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);
    
    // ✅ Добавлены скобки {}
    if (bmi < 18.5 || bmi > 25.0) {
      bioAge += 2;
      recs.add("📊 Оптимизируйте вес (BMI: ${bmi.toStringAsFixed(1)})");
    } else {
      bioAge -= 1;
    }

    if (smokes) {
      bioAge += 4;
      recs.add("🚭 Отказ от курения снизит биовозраст на ~3-4 года");
    }

    if (sleepHours < 7) {
      bioAge += 3;
      recs.add("🌙 Увеличьте сон до 7-8 часов");
    } else if (sleepHours > 9) {
      bioAge += 1;
    } else {
      bioAge -= 1;
    }

    switch (activity) {
      case 'low':
        bioAge += 3;
        recs.add("🏃 Добавьте 150 мин активности в неделю");
        break;
      case 'medium':
        bioAge -= 1;
        break;
      case 'high':
        bioAge -= 2;
        break;
    }

    if (gender == 'female') {
      bioAge -= 1;
    }

    final diff = bioAge - chronoAge;
    String risk;
    
    // ✅ Добавлены скобки {}
    if (diff <= -2) {
      risk = "Отличный (моложе паспорта)";
    } else if (diff <= 1) {
      risk = "Норма";
    } else if (diff <= 4) {
      risk = "Повышенный";
    } else {
      risk = "Высокий (рекомендуется консультация врача)";
    }

    return BioAgeResult(
      biologicalAge: bioAge,
      chronologicalAge: chronoAge,
      riskLevel: risk,
      recommendations: recs,
    );
  }
}