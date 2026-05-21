import 'package:flutter/material.dart';

class TrackerScreen extends StatefulWidget {
  final List<Map<String, String>> recommendations;
  final bool isPremium;

  const TrackerScreen({
    super.key,
    required this.recommendations,
    required this.isPremium,
  });

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final Map<String, List<bool>> _weeklyProgress = {};
  int _streak = 0;
  DateTime? _lastVisit;

  @override
  void initState() {
    super.initState();
    _initData();
    _checkStreak();
  }

  void _initData() {
    for (final rec in widget.recommendations) {
      _weeklyProgress[rec['id']!] = List.generate(7, (i) => i < 3);
    }
  }

  void _checkStreak() {
    final now = DateTime.now();
    final last = _lastVisit;
    
    if (last == null) {
      _streak = 1;
    } else {
      final diff = now.difference(last).inDays;
      if (diff <= 1) {
        _streak += 1;
      } else if (diff > 2) {
        _streak = 1;
      }
    }
    _lastVisit = now;
  }

  String _getMotivationMessage() {
    if (_streak >= 7) return '🔥 Неделя подряд! Вы меняете траекторию старения.';
    if (_streak >= 3) return '⭐ Отличный ритм! Каждая привычка — +0.3 года жизни.';
    if (_streak == 1) return '🚀 Начало положено! Завтра будет легче.';
    return '💪 Вернитесь сегодня — ваш биовозраст ждёт улучшений.';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekday = today.weekday % 7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Трекер привычек'),
        backgroundColor: const Color(0xFF0F1115),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF0F1115),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00D4AA).withOpacity(0.2),
                  Colors.grey[900]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '$_streak дней подряд 🔥',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getMotivationMessage(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'].asMap().entries.map((entry) {
                final idx = entry.key;
                final day = entry.value;
                final isToday = idx == weekday;
                return Column(
                  children: [
                    Text(day, style: TextStyle(color: isToday ? const Color(0xFF00D4AA) : Colors.grey[600], fontSize: 11)),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isToday ? const Color(0xFF00D4AA) : Colors.grey[800],
                        shape: BoxShape.circle,
                        border: Border.all(color: isToday ? Colors.white : Colors.transparent, width: 2),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: isToday ? Colors.black : Colors.transparent,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.recommendations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rec = widget.recommendations[index];
                final id = rec['id']!;
                final progress = _weeklyProgress[id] ?? List.filled(7, false);

                return Container(
                  padding: const EdgeInsets.all(12),
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
                              rec['title']!,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (widget.isPremium)
                            IconButton(
                              icon: const Icon(Icons.notifications_none, color: Color(0xFF00D4AA), size: 20),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('🔔 Напоминание установлено на 20:00')),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (i) {
                          final isDone = progress[i];
                          final isPast = i < weekday;
                          return GestureDetector(
                            onTap: widget.isPremium && isPast 
                                ? () => setState(() => progress[i] = !isDone) 
                                : null,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDone 
                                    ? const Color(0xFF00D4AA) 
                                    : (isPast ? Colors.grey[800] : Colors.grey[850]),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDone ? Colors.black : Colors.transparent,
                                  width: isDone ? 2 : 0,
                                ),
                              ),
                              child: isDone 
                                  ? const Icon(Icons.check, size: 18, color: Colors.black) 
                                  : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${progress.where((v) => v).length}/7 дней',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          if (!widget.isPremium)
                            TextButton(
                              onPressed: () => _showPremiumDialog(context),
                              child: const Text(
                                '🔓 Редактировать',
                                style: TextStyle(color: Color(0xFF00D4AA), fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          if (_streak >= 3)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: Color(0xFF00D4AA), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎁 Бонус за постоянство!',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.isPremium 
                              ? 'Открыт доступ к расширенной аналитике старения' 
                              : 'Разблокируйте премиум, чтобы получить персональный отчёт',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isPremium)
                    ElevatedButton(
                      onPressed: () => _showPremiumDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4AA),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('Получить', style: TextStyle(color: Colors.black, fontSize: 12)),
                    ),
                ],
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Разблокируйте полный доступ:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...[
              '✅ Редактирование прогресса',
              '✅ Напоминания о привычках',
              '✅ Расширенная аналитика',
              '✅ Персональные отчёты в PDF',
            ].map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00D4AA), size: 16),
                  const SizedBox(width: 8),
                  Text(feature, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            )),
          ],
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
            child: const Text('Разблокировать за \$2.99/мес', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}