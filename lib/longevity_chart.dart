import 'package:flutter/material.dart';
import 'bio_age_calculator.dart';

class LongevityChart extends StatelessWidget {
  final BioAgeResult result;
  final bool showCurrentLifestyle;

  const LongevityChart({
    super.key,
    required this.result,
    this.showCurrentLifestyle = true,
  });

  /// 🧮 Реалистичный расчёт вероятности (актуарная модель)
  static int _calculateProbability({
    required int bioAge,
    required int targetAge,
    required bool smokes,
    required double bmi,
    required String activity,
    required int sleepHours,
    required bool isOptimized,
  }) {
    // 1. БАЗОВАЯ ВЕРОЯТНОСТЬ (актуарная кривая)
    // Стартуем с 75% при совпадении возрастов, плавное снижение/рост
    double baseProb;
    if (bioAge < targetAge) {
      // Если цель впереди: шанс чуть выше базы, но растёт медленно
      baseProb = 75 + ((targetAge - bioAge) * 0.4);
    } else {
      // Если цель "пройдена": шанс падает
      baseProb = 75 - ((bioAge - targetAge) * 1.2);
    }
    // Ограничиваем базу реалистичным коридором 20-85%
    baseProb = baseProb.clamp(20.0, 85.0);

    // 2. КОРРЕКТИРОВКА ОБРАЗОМ ЖИЗНИ
    double adjustment = 0;
    
    if (isOptimized) {
      // ✅ Сценарий "С рекомендациями": небольшой бонус за ЗОЖ
      adjustment += 4; 
    } else {
      // ⚠️ Сценарий "Текущий образ жизни": умеренные штрафы за риски
      
      // Курение: -8% (серьёзный, но не фатальный фактор)
      if (smokes) adjustment -= 8;
      
      // Вес:
      if (bmi > 30) adjustment -= 6;       // Ожирение
      else if (bmi > 25) adjustment -= 3;  // Лишний вес
      else if (bmi >= 18.5 && bmi <= 25) adjustment += 2; // Норма (малый бонус)
      
      // Активность:
      if (activity == 'low') adjustment -= 5;
      else if (activity == 'medium') adjustment -= 1;
      else if (activity == 'high') adjustment += 3;

      // Сон:
      if (sleepHours < 6 || sleepHours > 9) adjustment -= 3;
      else adjustment += 1;
    }

    // 3. ФИНАЛЬНЫЙ РЕЗУЛЬТАТ (диапазон 5-95% для избежания "0%" и "100%")
    return (baseProb + adjustment).round().clamp(5, 95);
  }

  Color _getBarColor(int probability) {
    if (probability >= 65) return const Color(0xFF00D4AA); // 🟢 Высокий
    if (probability >= 35) return Colors.orange;            // 🟡 Средний
    return Colors.redAccent;                                 // 🔴 Низкий
  }

  Widget _buildTargetRow(String label, int targetAge) {
    // ✅ Сценарий 1: с выполнением рекомендаций
    final withRec = _calculateProbability(
      bioAge: result.biologicalAge,
      targetAge: targetAge,
      smokes: false, bmi: 22.0, activity: 'high', sleepHours: 7,
      isOptimized: true,
    );

    // ⚠️ Сценарий 2: текущий образ жизни (реальные данные)
    final current = _calculateProbability(
      bioAge: result.biologicalAge,
      targetAge: targetAge,
      smokes: result.smokes,
      bmi: result.bmi,
      activity: result.activity,
      sleepHours: result.sleepHours,
      isOptimized: false,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _buildProgressBar(probability: withRec, label: 'с рекомендациями', color: _getBarColor(withRec), icon: Icons.check_circle),
          const SizedBox(height: 4),
          if (showCurrentLifestyle)
            _buildProgressBar(probability: current, label: 'текущий образ жизни', color: _getBarColor(current).withOpacity(0.8), icon: Icons.info_outline, isSecondary: true),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required int probability,
    required String label,
    required Color color,
    required IconData icon,
    bool isSecondary = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isSecondary ? Colors.grey : color),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: probability / 100,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$probability%', style: TextStyle(color: isSecondary ? Colors.grey : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: isSecondary ? Colors.grey[600] : Colors.grey[400], fontSize: 10)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.show_chart, color: Color(0xFF00D4AA), size: 18),
            const SizedBox(width: 8),
            const Text('Вероятность дожить до...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          _buildTargetRow('80 лет', 80),
          _buildTargetRow('90 лет', 90),
          _buildTargetRow('100 лет', 100),
          if (showCurrentLifestyle)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '💡 Зелёная шкала — если выполнить рекомендации.\nСерая — при сохранении текущего образа жизни.',
                style: TextStyle(color: Colors.grey[500], fontSize: 11, height: 1.3),
              ),
            ),
        ],
      ),
    );
  }
}