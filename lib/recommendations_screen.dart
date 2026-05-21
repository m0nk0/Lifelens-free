import 'package:flutter/material.dart';
import 'bio_age_calculator.dart';
import 'tracker_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  final BioAgeResult result;
  final bool isPremium;

  const RecommendationsScreen({
    super.key,
    required this.result,
    this.isPremium = false,
  });

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final Map<String, bool> _completed = {};

  final Map<String, String> _evidence = {
    'smoking': 'Курение ускоряет эпигенетическое старение на 2-4 года (Horvath Clock, 2021). Отказ возвращает траекторию к норме за 5-10 лет.',
    'activity': '150 мин/нед умеренной активности снижают смертность на 30% (Lancet, 2020). Начинайте с 10 мин в день.',
    'sleep': 'Сон 7-8 ч оптимизирует выработку мелатонина и восстановление ДНК. Недосып повышает риск деменции на 40%.',
    'nutrition': 'Средиземноморская диета увеличивает ожидаемую продолжительность жизни на 4.5 года (BMJ, 2023).',
    'stress': 'Хронический стресс укорачивает теломеры. 10 мин медитации в день замедляют клеточное старение.',
  };

  List<Map<String, String>> _getRecommendations() {
    final recs = <Map<String, String>>[];

    if (widget.result.smokes) {
      recs.add({
        'id': 'smoking',
        'title': '🚭 Снижайте дозу курения',
        'action': widget.isPremium 
            ? 'План: неделя 1 — на 2 сигареты меньше, неделя 2 — замените одну на никотиновую жвачку...'
            : '🔓 Разблокируйте премиум для персонального плана отказа',
        'impact': '+3.2 года к ожидаемой продолжительности',
      });
    }

    if (widget.result.bmi > 25) {
      recs.add({
        'id': 'nutrition',
        'title': '⚖️ Скорректируйте питание',
        'action': widget.isPremium
            ? 'Ваш план: 1200 ккал/день, 30% белков, исключите добавленный сахар после 18:00...'
            : '🔓 Разблокируйте премиум для персонального плана питания',
        'impact': '+2.8 года при нормализации ИМТ',
      });
    }

    if (widget.result.activity == 'low') {
      recs.add({
        'id': 'activity',
        'title': '🚶 Добавьте активность',
        'action': widget.isPremium
            ? 'Неделя 1: 10 мин ходьбы после ужина. Неделя 2: +5 мин. Неделя 3: добавьте приседания...'
            : '🔓 Разблокируйте премиум для пошагового плана активности',
        'impact': '+2.1 года при 150 мин/нед',
      });
    }

    if (widget.result.sleepHours < 7 || widget.result.sleepHours > 8) {
      recs.add({
        'id': 'sleep',
        'title': '😴 Оптимизируйте сон',
        'action': widget.isPremium
            ? 'Ваш протокол: отбой в 22:30, без экранов за 1 ч, температура 18-20°C, магний перед сном...'
            : '🔓 Разблокируйте премиум для персонального протокола сна',
        'impact': '+1.9 года при 7-8 часах сна',
      });
    }

    // Общие рекомендации (всегда бесплатные)
    recs.addAll([
      {
        'id': 'checkup',
        'title': '🩺 Пройдите чек-ап',
        'action': 'Базовый набор: общий анализ крови, глюкоза, холестерин, витамин D, ТТГ.',
        'impact': 'Раннее выявление рисков',
      },
      {
        'id': 'stress',
        'title': '🧘 Практикуйте управление стрессом',
        'action': '5 мин глубокого дыхания 2 раза в день снижают кортизол на 23%.',
        'impact': '+1.2 года при регулярной практике',
      },
    ]);

    return recs;
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = _getRecommendations();
    final completedCount = _completed.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ваш план долголетия'),
        backgroundColor: const Color(0xFF0F1115),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!widget.isPremium)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00D4AA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFF00D4AA), size: 14),
                  SizedBox(width: 4),
                  Text('PREMIUM', style: TextStyle(color: Color(0xFF00D4AA), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
      backgroundColor: const Color(0xFF0F1115),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Выполнено рекомендаций', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('$completedCount/${recommendations.length}', style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: recommendations.isEmpty ? 0 : completedCount / recommendations.length,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: recommendations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = recommendations[index];
                final id = item['id']!;
                final isCompleted = _completed[id] ?? false;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleted ? const Color(0xFF00D4AA).withOpacity(0.5) : Colors.grey[800]!,
                      width: isCompleted ? 1.5 : 1,
                    ),
                  ),
                  child: ExpansionTile(
                    leading: Checkbox(
                      value: isCompleted,
                      onChanged: widget.isPremium 
                          ? (value) => setState(() => _completed[id] = value!)
                          : null,
                      activeColor: const Color(0xFF00D4AA),
                      checkColor: Colors.black,
                    ),
                    title: Text(
                      item['title']!,
                      style: TextStyle(
                        color: isCompleted ? const Color(0xFF00D4AA) : Colors.white,
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      item['impact']!,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.science, color: Color(0xFF00D4AA), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _evidence[id] ?? 'Исследования подтверждают пользу этой привычки.',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['action']!,
                              style: TextStyle(
                                color: widget.isPremium ? Colors.white : Colors.grey[600],
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            if (!widget.isPremium && !['checkup', 'stress'].contains(id))
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _showPremiumDialog(context),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF00D4AA)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    child: const Text(
                                      '🔓 Разблокировать план',
                                      style: TextStyle(color: Color(0xFF00D4AA), fontSize: 13),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(top: BorderSide(color: Colors.grey[800]!)),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrackerScreen(
                      recommendations: recommendations,
                      isPremium: widget.isPremium,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.track_changes, color: Colors.black),
              label: Text(
                widget.isPremium ? '📊 Открыть трекер привычек' : '🔓 Премиум: трекер + напоминания',
                style: TextStyle(color: widget.isPremium ? Colors.black : Colors.grey[600]),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isPremium ? const Color(0xFF00D4AA) : Colors.grey[800],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1115),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🔓 LifeLens Premium', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Разблокируйте персональные планы действий, трекер привычек, напоминания и научные отчёты.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Позже', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('💡 В реальной версии здесь откроется оплата')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4AA)),
            child: const Text('Разблокировать за \$2.99', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}