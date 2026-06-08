import 'package:flutter/material.dart';
import 'bio_age_calculator.dart';
import 'tracker_screen.dart';
import 'plan_detail_screen.dart';
import 'nutrition_questionnaire_screen.dart';
import 'sleep_questionnaire_screen.dart';
import 'activity_questionnaire_screen.dart';

class RecommendationsScreen extends StatelessWidget {
  final BioAgeResult? result;
  const RecommendationsScreen({super.key, this.result});

  // ✅ Обновлённый список из 6 пунктов (добавлен уход за кожей)
  List<Map<String, String>> _getItems() {
    return [
      {
        'id': 'nutrition',
        'title': '🥗 Скорректируйте питание',
        'impact': '+2.8 года при нормализации ИМТ',
        'details': 'Персональный расчёт калорий, БЖУ и примерное меню на день.',
        'science': 'Средиземноморская диета увеличивает продолжительность жизни на 4.5 года (BMJ, 2023).'
      },
      {
        'id': 'sleep',
        'title': '😴 Оптимизируйте сон',
        'impact': '+1.9 года при 7-8 часах сна',
        'details': 'Протокол засыпания, расчёт времени отбоя по хронотипу.',
        'science': 'Сон 7-8 ч восстанавливает ДНК и снижает риск деменции на 40%.'
      },
      {
        'id': 'activity',
        'title': ' Добавьте активность',
        'impact': '+2.1 года при 150 мин/нед',
        'details': 'Пошаговый план: от 10 мин ходьбы до силовых тренировок.',
        'science': '150 мин/нед умеренной активности снижают смертность на 30% (Lancet, 2020).'
      },
      {
        'id': 'skincare',
        'title': ' Уход за кожей',
        'impact': '+0.5-1 год к визуальному возрасту',
        'details': 'Утренняя/вечерняя рутина: SPF, ретинол, увлажнение.',
        'science': 'Регулярный уход и SPF замедляют фотостарение на 50% (JCAD, 2022).'
      },
      {
        'id': 'checkup',
        'title': '🩺 Пройдите чек-ап',
        'impact': 'Раннее выявление рисков',
        'details': 'Чек-лист анализов: общий анализ крови, глюкоза, холестерин, витамин D, ТТГ.',
        'science': 'Регулярный скрининг снижает риск запущенных заболеваний на 60%.'
      },
      {
        'id': 'stress',
        'title': '🧘 Управление стрессом',
        'impact': '+1.2 года при регулярной практике',
        'details': 'Техники дыхания, медитация 10 мин/день и цифровая гигиена.',
        'science': 'Хронический стресс укорачивает теломеры. Медитация замедляет старение.'
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _getItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ваш план долголетия'),
        backgroundColor: const Color(0xFF0F1115),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF0F1115),
      body: Column(
        children: [
          // 📋 Скроллящийся список рекомендаций
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title']!,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            item['impact']!,
                            style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.science, color: Color(0xFF00D4AA), size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item['science']!,
                              style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // 🔀 Точная навигация по ID
                            if (item['id'] == 'nutrition') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NutritionQuestionnaireScreen()),
                              );
                            } else if (item['id'] == 'sleep') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SleepQuestionnaireScreen()),
                              );
                            } else if (item['id'] == 'activity') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ActivityQuestionnaireScreen()),
                              );
                            } else {
                              // Остальные пункты (skincare, checkup, stress) → экран деталей
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PlanDetailScreen(data: item)),
                              );
                            }
                          },
                          icon: const Icon(Icons.arrow_forward, color: Colors.black),
                          label: const Text(
                            'Открыть план',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D4AA),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // ✅ КНОПКА ТРЕКЕРА (зафиксирована внизу)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrackerScreen()),
                ),
                icon: const Icon(Icons.calendar_today, color: Color(0xFF00D4AA)),
                label: const Text('Ежедневный трекер', 
                  style: TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00D4AA)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}