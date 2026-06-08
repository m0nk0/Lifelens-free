// lib/sleep_protocol.dart
import 'user_profile.dart';

class SleepProtocol {
  final UserProfile profile;

  SleepProtocol(this.profile);

  Map<String, dynamic> generate() {
    // 🕐 Расчёт идеального времени отбоя (7-9 часов сна)
    final sleepDuration = _getOptimalDuration();
    final bedtime = profile.targetWakeUpHour - sleepDuration;
    
    // 🌙 Ритуалы перед сном
    final preSleepRoutine = _getRoutine();
    
    // ☀️ Утренние привычки
    final morningRoutine = _getMorningRoutine();
    
    return {
      'targetSleepHours': '$sleepDuration ч',
      'bedtime': '${bedtime.toString().padLeft(2, '0')}:00',
      'wakeTime': '${profile.targetWakeUpHour.toString().padLeft(2, '0')}:00',
      'preSleepRoutine': preSleepRoutine,
      'morningRoutine': morningRoutine,
      'tips': _getTips(),
    };
  }

  int _getOptimalDuration() {
    // 7-9 часов в зависимости от активности и возраста
    if (profile.activity == ActivityLevel.high) return 9;
    if (profile.chronotype == Chronotype.earlyBird) return 7;
    return 8;
  }

  List<String> _getRoutine() {
    final base = [
      'За 1 час до сна: выключи яркие экраны или включи ночной режим',
      'За 30 мин: тёплый душ или ванна (снижает температуру тела, сигнализируя о сне)',
      'За 10 мин: 5 минут глубокого дыхания или лёгкая растяжка',
    ];
    
    if (profile.chronotype == Chronotype.nightOwl) {
      base.add('Используй маску для сна и беруши, если ложишься раньше привычного');
    }
    
    return base;
  }

  List<String> _getMorningRoutine() {
    return [
      'Сразу после пробуждения: стакан воды комнатной температуры',
      'В течение 30 мин: 5-10 минут естественного света (открой шторы или выйди на балкон)',
      'Избегай кофеина первые 90 минут после пробуждения для стабильной энергии',
    ];
  }

  List<String> _getTips() {
    return [
      'Поддерживай температуру в спальне 18-20°C — это оптимум для качества сна',
      'Если не уснул за 20 минут — встань, почитай книгу при тусклом свете и вернись, когда захочешь спать',
      'Избегай алкоголя за 3 часа до сна: он ухудшает фазу глубокого сна на 24%',
    ];
  }
}