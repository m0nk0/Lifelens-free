// lib/nutrition_plan.dart
import 'user_profile.dart';

class NutritionPlan {
  final UserProfile profile;

  NutritionPlan(this.profile);

  // 🍽️ Структура плана
  Map<String, dynamic> generate() {
    final calories = profile.targetCalories;
    final protein = (profile.weightKg * 1.6).round(); // 1.6г на кг для поддержания
    final fat = (calories * 0.3 / 9).round(); // 30% калорий из жиров
    final carbs = (calories - protein * 4 - fat * 9) ~/ 4; // остаток — углеводы

    // 🥗 Примеры блюд (можно расширять)
    final breakfast = _getBreakfast(profile.diet);
    final lunch = _getLunch(profile.diet);
    final dinner = _getDinner(profile.diet);
    final snacks = _getSnacks(profile.diet);

    return {
      'dailyCalories': calories,
      'macros': {
        'protein': '$protein г',
        'fat': '$fat г',
        'carbs': '$carbs г',
      },
      'meals': {
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
        'snacks': snacks,
      },
      'tips': _getTips(profile),
    };
  }

  String _getBreakfast(DietPreference diet) {
    final options = {
      DietPreference.all: 'Овсянка с ягодами и орехами (350 ккал)',
      DietPreference.noMeat: 'Тост с авокадо и яйцом пашот (320 ккал)',
      DietPreference.noLactose: 'Смузи на кокосовом молоке с бананом (300 ккал)',
      DietPreference.vegan: 'Тофу-скрэмбл с овощами и цельнозерновым хлебом (340 ккал)',
    };
    return options[diet]!;
  }

  String _getLunch(DietPreference diet) {
    final options = {
      DietPreference.all: 'Куриная грудка с киноа и салатом (500 ккал)',
      DietPreference.noMeat: 'Чечевичный суп с овощами и цельнозерновым хлебом (450 ккал)',
      DietPreference.noLactose: 'Запечённая рыба с бурым рисом (480 ккал)',
      DietPreference.vegan: 'Фалафель с хумусом и овощным салатом (460 ккал)',
    };
    return options[diet]!;
  }

  String _getDinner(DietPreference diet) {
    final options = {
      DietPreference.all: 'Лосось на пару с брокколи (400 ккал)',
      DietPreference.noMeat: 'Греческий салат с тофу (350 ккал)',
      DietPreference.noLactose: 'Индейка с тушёными овощами (380 ккал)',
      DietPreference.vegan: 'Овощное рагу с нутом (360 ккал)',
    };
    return options[diet]!;
  }

  List<String> _getSnacks(DietPreference diet) {
    final options = {
      DietPreference.all: ['Греческий йогурт', 'Миндаль (10 шт.)', 'Яблоко'],
      DietPreference.noMeat: ['Хумус с морковью', 'Горсть орехов', 'Фрукт'],
      DietPreference.noLactose: ['Авокадо с солью', 'Рисовые хлебцы', 'Ягоды'],
      DietPreference.vegan: ['Эдамаме', 'Фруктовый салат', 'Ореховая паста с хлебом'],
    };
    return options[diet]!;
  }

  List<String> _getTips(UserProfile profile) {
    final tips = <String>[];
    
    if (profile.goal == 'lose') {
      tips.add('Пей стакан воды за 20 мин до еды — это снижает потребление калорий на ~13%');
    }
    if (profile.activity == ActivityLevel.low) {
      tips.add('Добавь 10-минутную прогулку после каждого приёма пищи для улучшения метаболизма');
    }
    if (profile.chronotype == Chronotype.nightOwl) {
      tips.add('Старайся ужинать не позднее, чем за 3 часа до сна, даже если ложишься поздно');
    }
    
    tips.add('Веди дневник питания 3 дня в неделю — это повышает осознанность на 40%');
    
    return tips;
  }
}