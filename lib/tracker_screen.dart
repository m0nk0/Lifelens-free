import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TrackerScreen extends StatefulWidget {
  // ✅ Простой конструктор без обязательных параметров
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final String _todayKey = DateTime.now().toIso8601String().split('T')[0];
  
  // ✅ Список привычек (можно менять)
  final List<Map<String, dynamic>> _habits = [
    {'id': 'water', 'title': '💧 Пил воду (1.5-2л)', 'checked': false},
    {'id': 'sleep', 'title': '😴 Сон 7-8 часов', 'checked': false},
    {'id': 'skin', 'title': '🧴 Уход за кожей', 'checked': false},
    {'id': 'nutrition', 'title': '🥗 Правильное питание', 'checked': false},
    {'id': 'walk', 'title': '🚶 Прогулка 30+ мин', 'checked': false},
    {'id': 'scan', 'title': '📸 Скан лица', 'checked': false},
  ];

  int _streak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 🔽 Загрузка данных
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Загружаем галочки за сегодня
    final todayData = prefs.getString('tracker_$_todayKey');
    if (todayData != null) {
      final Map<String, dynamic> decoded = jsonDecode(todayData);
      for (var habit in _habits) {
        if (decoded.containsKey(habit['id'])) {
          habit['checked'] = decoded[habit['id']];
        }
      }
    }

    // Считаем серию дней (streak)
    _streak = 0;
    DateTime checkDate = DateTime.now();
    while (true) {
      final key = 'tracker_${checkDate.toIso8601String().split('T')[0]}';
      final data = prefs.getString(key);
      if (data != null) {
        final Map<String, dynamic> decoded = jsonDecode(data);
        final bool anyChecked = decoded.values.any((v) => v == true);
        if (anyChecked) {
          _streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      } else {
        break;
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // 🔼 Сохранение данных
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, bool> data = {};
    for (var h in _habits) {
      data[h['id']] = h['checked'];
    }
    await prefs.setString('tracker_$_todayKey', jsonEncode(data));
  }

  void _toggleHabit(int index) {
    setState(() {
      _habits[index]['checked'] = !_habits[index]['checked'];
    });
    _saveData();
  }

  String _getMotivation(double progress) {
    if (progress == 0) return 'Начни с малого. Один шаг к лучшей версии себя! 🌱';
    if (progress < 0.5) return 'Хорошее начало! Продолжай в том же духе 💪';
    if (progress < 1.0) return 'Почти идеально! Осталось чуть-чуть 🎯';
    return 'Легенда! Все привычки выполнены. Ты крут! 🏆';
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _habits.where((h) => h['checked']).length;
    final progress = completedCount / _habits.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ежедневный трекер', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                const SizedBox(width: 6),
                Text('$_streak дн.', 
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D4AA)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 📊 Прогресс-кольцо
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 12,
                              backgroundColor: Colors.grey[800],
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontSize: 32, 
                                  fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '$completedCount из ${_habits.length}',
                                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 💬 Мотивация
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1C21),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF00D4AA).withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _getMotivation(progress),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 15, 
                          height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ✅ Список привычек
                    ..._habits.asMap().entries.map((entry) {
                      final index = entry.key;
                      final habit = entry.value;
                      return _HabitTile(
                        title: habit['title'],
                        isChecked: habit['checked'],
                        onTap: () => _toggleHabit(index),
                      );
                    }),

                    const SizedBox(height: 32),
                    Text(
          '📅 ${_formatDate(DateTime.now())}',
                   textAlign: TextAlign.center,
                   style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// 🧩 Виджет одной привычки
class _HabitTile extends StatelessWidget {
  final String title;
  final bool isChecked;
  final VoidCallback onTap;

  const _HabitTile({
    required this.title,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isChecked 
              ? const Color(0xFF00D4AA).withValues(alpha: 0.15) 
              : const Color(0xFF1A1C21),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isChecked 
                ? const Color(0xFF00D4AA) 
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isChecked 
                    ? const Color(0xFF00D4AA) 
                    : Colors.grey[800],
              ),
              child: isChecked
                  ? const Icon(Icons.check, color: Colors.black, size: 18)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isChecked ? Colors.white : Colors.grey[300],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: isChecked ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}