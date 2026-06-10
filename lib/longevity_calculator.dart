import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LongevityCalculator {
  // ==========================================
  // 🧬 БАЗОВАЯ МАТЕМАТИКА ВЫЖИВАНИЯ
  // ==========================================
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

  // ==========================================
  // 🎯 ПРОГРЕССИВНАЯ ШКАЛА БОНУСОВ ПО ВОЗРАСТАМ
  // ==========================================
  // Чем выше целевой возраст — тем ценнее дисциплина
  static const Map<int, double> _progressiveBonusScale = {
    70: 0.3,   // +0.3% за 14 дней
    75: 0.4,   // +0.4% за 14 дней
    80: 0.5,   // +0.5% за 14 дней
    85: 0.7,   // +0.7% за 14 дней
    90: 0.9,   // +0.9% за 14 дней
    95: 1.2,   // +1.2% за 14 дней
    100: 1.5,  // +1.5% за 14 дней
  };

  // ==========================================
  // 📊 РАСЧЁТ ВЕРОЯТНОСТИ (С БОНУСАМИ)
  // ==========================================
  static int calculateProbability({
    required int bioAge, required int targetAge,
    required bool smokes, required double bmi, required String activity,
    required int sleepHours, required bool isOptimized,
    double loyaltyBonus = 0.0, // ✅ Теперь double, не int
  }) {
    if (targetAge <= bioAge) return 99;
    final years = targetAge - bioAge;
    double prob = 1.0;
    final mult = _getLifestyleMultiplier(
      smokes: smokes, bmi: bmi, activity: activity, 
      sleepHours: sleepHours, isOptimized: isOptimized,
    );
    for (int i = 0; i < years; i++) {
      prob *= _getBaseAnnualSurvival(bioAge + i) * mult;
    }
    final basePercent = prob * 100;
    final withBonus = basePercent + loyaltyBonus;
    return withBonus.round().clamp(2, 98);
  }

  // ==========================================
  // 🎂 ОЖИДАЕМАЯ ПРОДОЛЖИТЕЛЬНОСТЬ ЖИЗНИ
  // ==========================================
  static int calculateExpectedLifespan({
    required int bioAge, required bool smokes, required double bmi,
    required String activity, required int sleepHours, required bool isOptimized,
    int bioAgeReduction = 0, // ✅ Бонус: -X лет к биовозрасту
  }) {
    final effectiveBioAge = bioAge - bioAgeReduction;
    final optimistic = _calculateRaw(effectiveBioAge, false, 22.0, 'high', 7, true);
    final rawCurrent = _calculateRaw(effectiveBioAge, smokes, bmi, activity, sleepHours, false);
    
    const maxDiff = 10.0;
    const minBuffer = 5;
    final rawDiff = optimistic - rawCurrent;
    final cappedDiff = rawDiff > maxDiff ? maxDiff : rawDiff;
    final adjusted = optimistic - cappedDiff;
    
    return adjusted.clamp(effectiveBioAge + minBuffer, 95.0).clamp(0, optimistic).round();
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

  // ==========================================
  // 🎁 ПОЛНАЯ СИСТЕМА БОНУСОВ ЛОЯЛЬНОСТИ
  // ==========================================
  static Future<Map<String, dynamic>> calculateLoyaltyBonus() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    // 1. Собираем данные за 180 дней
    final List<Map<String, dynamic>> dailyStats = [];
    final Set<String> completedCategories = {}; // Для бонуса за разнообразие
    
    for (int i = 0; i < 180; i++) {
      final date = now.subtract(Duration(days: i));
      final key = 'tracker_${date.toIso8601String().split('T')[0]}';
      final data = prefs.getString(key);
      
      if (data != null) {
        final decoded = jsonDecode(data);
        if (decoded['completed'] is List) {
          final completedList = List<bool>.from(decoded['completed']);
          final completionRate = completedList.where((c) => c).length / completedList.length;
          
          // Собираем категории для бонуса за разнообразие
          if (decoded['taskIds'] is List) {
            final taskIds = List<String>.from(decoded['taskIds']);
            for (var taskId in taskIds) {
              // Определяем категорию по первой букве ID
              final prefix = taskId.substring(0, 1);
              final categoryMap = {
                'n': 'nutrition', 's': 'sleep', 'a': 'activity',
                'k': 'skincare', 't': 'stress', 'h': 'hydration',
              };
              if (categoryMap.containsKey(prefix)) {
                completedCategories.add(categoryMap[prefix]!);
              }
            }
          }
          
          dailyStats.add({
            'date': date,
            'completionRate': completionRate,
            'completed': completedList.every((c) => c),
            'anyCompleted': completedList.any((c) => c),
          });
        }
      }
    }
    
    // 2. Считаем streak (серия дней с 100% выполнением)
    int currentStreak = 0;
    int maxStreak = 0;
    for (var stat in dailyStats.reversed) {
      if (stat['completed'] == true) {
        currentStreak++;
        if (currentStreak > maxStreak) maxStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
    }
    
    // 3. Считаем периоды лояльности (14 дней с ≥70% выполнением)
    int loyaltyPeriods = 0;
    final sortedStats = List.from(dailyStats)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    for (int i = 0; i < sortedStats.length - 13; i++) {
      final period = sortedStats.sublist(i, i + 14);
      final avgCompletion = period
          .map((d) => d['completionRate'] as double)
          .reduce((a, b) => a + b) / 14;
      
      if (avgCompletion >= 0.70) {
        loyaltyPeriods++;
        i += 13; // Пропускаем пересекающиеся
      }
    }
    
    // 4. Считаем дни с ≥80% выполнением (для бонуса к биовозрасту)
    int highDisciplineDays = 0;
    for (var stat in dailyStats) {
      if ((stat['completionRate'] as double) >= 0.80) {
        highDisciplineDays++;
      }
    }
    
    // 5. Бонус к БИОВОЗРАСТУ (за долгосрочную дисциплину)
    int bioAgeReduction = 0;
    if (highDisciplineDays >= 180) {
      bioAgeReduction = 3; // -3 года максимум
    } else if (highDisciplineDays >= 120) {
      bioAgeReduction = 2; // -2 года
    } else if (highDisciplineDays >= 60) {
      bioAgeReduction = 1; // -1 год
    }
    
    // 6. STREAK-БОНУС
    int streakBonus = 0;
    if (maxStreak >= 60) streakBonus = 10;
    else if (maxStreak >= 30) streakBonus = 5;
    else if (maxStreak >= 14) streakBonus = 2;
    else if (maxStreak >= 7) streakBonus = 1;
    
    // 7. БОНУС ЗА РАЗНООБРАЗИЕ (все 6 категорий за 30 дней)
    int diversityBonus = 0;
    final last30Days = dailyStats.where((s) {
      final daysDiff = now.difference(s['date'] as DateTime).inDays;
      return daysDiff <= 30;
    }).toList();
    
    if (last30Days.length >= 20 && completedCategories.length >= 6) {
      diversityBonus = 1; // +1% ко всем возрастам
    }
    
    // 8. БОНУС ЗА УЛУЧШЕНИЕ БИОВОЗРАСТА
    int improvementBonus = 0;
    final bioHistory = await _getBioAgeHistory(prefs);
    if (bioHistory.length >= 2) {
      final firstBio = bioHistory.last;
      final lastBio = bioHistory.first;
      final improvement = firstBio - lastBio;
      
      if (improvement >= 2) {
        improvementBonus = 2; // +2% за снижение биовозраста на 2+ года
      } else if (improvement >= 1) {
        improvementBonus = 1; // +1% за снижение на 1 год
      }
    }
    
    // 9. ПРОГРЕССИВНЫЕ БОНУСЫ ПО ВОЗРАСТАМ
    final Map<int, double> bonusesByAge = {};
    for (var entry in _progressiveBonusScale.entries) {
      final age = entry.key;
      final ratePerPeriod = entry.value;
      
      // Базовый бонус за периоды
      double bonus = loyaltyPeriods * ratePerPeriod;
      
      // Добавляем все дополнительные бонусы
      bonus += streakBonus;
      bonus += diversityBonus;
      bonus += improvementBonus;
      
      bonusesByAge[age] = bonus;
    }
    
    // 10. Дней до следующего бонуса
    final daysSinceLastPeriod = dailyStats.isEmpty 
        ? 14 
        : now.difference(dailyStats.first['date'] as DateTime).inDays;
    final daysToNextBonus = (14 - (daysSinceLastPeriod % 14)).clamp(1, 14);
    
    return {
      // Основные метрики
      'loyaltyPeriods': loyaltyPeriods,
      'maxStreak': maxStreak,
      'highDisciplineDays': highDisciplineDays,
      'totalDaysTracked': dailyStats.length,
      'daysToNextBonus': daysToNextBonus,
      
      // Бонус к биовозрасту
      'bioAgeReduction': bioAgeReduction,
      
      // Бонусы по возрастам (double для точности)
      'bonusesByAge': bonusesByAge,
      
      // Составляющие бонусов
      'streakBonus': streakBonus,
      'diversityBonus': diversityBonus,
      'improvementBonus': improvementBonus,
      'completedCategories': completedCategories.length,
    };
  }
  
  // ==========================================
  // 📈 ИСТОРИЯ БИОВОЗРАСТА (для бонуса за улучшение)
  // ==========================================
  static Future<List<int>> _getBioAgeHistory(SharedPreferences prefs) async {
    final List<int> history = [];
    final now = DateTime.now();
    
    // Берём замеры раз в 14 дней за последние 90 дней
    for (int i = 0; i < 90; i += 14) {
      final date = now.subtract(Duration(days: i));
      final key = 'bio_age_${date.toIso8601String().split('T')[0]}';
      final bioAge = prefs.getInt(key);
      if (bioAge != null) {
        history.add(bioAge);
      }
    }
    
    return history;
  }
  
  // Сохранить текущий биовозраст в историю (вызывать после расчёта)
  static Future<void> saveBioAgeToHistory(int bioAge) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setInt('bio_age_$today', bioAge);
  }
}