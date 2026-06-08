// lib/user_profile.dart
enum Gender { male, female }
enum ActivityLevel { low, moderate, high }
enum DietPreference { all, noMeat, noLactose, vegan }
enum Chronotype { earlyBird, neutral, nightOwl }

class UserProfile {
  final Gender gender;
  final double weightKg;      // вес в кг
  final double heightCm;      // рост в см
  final ActivityLevel activity;
  final DietPreference diet;
  final Chronotype chronotype;
  final int targetWakeUpHour; // желаемый подъём (0-23)
  final String goal;          // 'lose', 'maintain', 'gain'

  const UserProfile({
    required this.gender,
    required this.weightKg,
    required this.heightCm,
    required this.activity,
    required this.diet,
    required this.chronotype,
    required this.targetWakeUpHour,
    this.goal = 'maintain',
  });

  // 🔬 Формула Миффлина-Сан Жеора для расчёта BMR
  double get bmr {
    // BMR = 10×вес + 6.25×рост - 5×возраст + 5 (муж) / -161 (жен)
    // Возраст берём из BioAgeResult.chronologicalAge
    return 10 * weightKg + 6.25 * heightCm - 5 * 40 + (gender == Gender.male ? 5 : -161);
  }

  // 🔥 TDEE с учётом активности
  double get tdee {
    final multiplier = {
      ActivityLevel.low: 1.2,
      ActivityLevel.moderate: 1.55,
      ActivityLevel.high: 1.725,
    }[activity]!;
    return bmr * multiplier;
  }

  // 🎯 Калории под цель
  int get targetCalories {
    final adjustment = {
      'lose': -500,
      'maintain': 0,
      'gain': 300,
    }[goal]!;
    return (tdee + adjustment).round();
  }
}