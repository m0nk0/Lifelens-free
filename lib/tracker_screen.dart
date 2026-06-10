import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'task_manager.dart';
import 'task_database.dart';
import 'task_feedback_screen.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  List<Task> _todayTasks = [];
  List<bool> _completed = [false, false];
  int _streak = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _weekHistory = [];

  final String _todayKey = DateTime.now().toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    _initTracker();
  }

  Future<void> _initTracker() async {
    final hasTasks = await TaskManager.hasTodayTasks();

    if (!hasTasks) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TaskFeedbackScreen()),
        );
      }
      return;
    }

    final tasks = await TaskManager.getTodayTasks();

    final prefs = await SharedPreferences.getInstance();
    final todayData = prefs.getString('tracker_$_todayKey');
    List<bool> completed = [false, false];
    if (todayData != null) {
      final decoded = jsonDecode(todayData);
      if (decoded['completed'] is List) {
        completed = List<bool>.from(decoded['completed']);
      }
    }

    final streak = await _calculateStreak();
    final weekHistory = await _loadWeekHistory();

    if (mounted) {
      setState(() {
        _todayTasks = tasks;
        _completed = completed;
        _streak = streak;
        _weekHistory = weekHistory;
        _isLoading = false;
      });
    }
  }

  Future<int> _calculateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    int streak = 0;
    DateTime checkDate = DateTime.now();

    while (true) {
      final key = 'tracker_${checkDate.toIso8601String().split('T')[0]}';
      final data = prefs.getString(key);
      if (data != null) {
        final decoded = jsonDecode(data);
        if (decoded['completed'] is List) {
          final completedList = List<bool>.from(decoded['completed']);
          if (completedList.every((c) => c == true)) {
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        } else {
          break;
        }
      } else {
        break;
      }
    }
    return streak;
  }

  Future<List<Map<String, dynamic>>> _loadWeekHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> history = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key = 'tracker_${date.toIso8601String().split('T')[0]}';
      final data = prefs.getString(key);

      String dayName;
      switch (date.weekday) {
        case DateTime.monday: dayName = 'Пн'; break;
        case DateTime.tuesday: dayName = 'Вт'; break;
        case DateTime.wednesday: dayName = 'Ср'; break;
        case DateTime.thursday: dayName = 'Чт'; break;
        case DateTime.friday: dayName = 'Пт'; break;
        case DateTime.saturday: dayName = 'Сб'; break;
        default: dayName = 'Вс';
      }

      bool completed = false;
      if (data != null) {
        final decoded = jsonDecode(data);
        if (decoded['completed'] is List) {
          completed = List<bool>.from(decoded['completed']).every((c) => c == true);
        }
      }

      history.add({
        'date': date,
        'dayName': dayName,
        'completed': completed,
        'isToday': i == 0,
      });
    }
    return history;
  }

  Future<void> _toggleTask(int index) async {
    setState(() {
      _completed[index] = !_completed[index];
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tracker_$_todayKey', jsonEncode({
      'taskIds': _todayTasks.map((t) => t.id).toList(),
      'completed': _completed,
      'date': _todayKey,
    }));

    final newStreak = await _calculateStreak();
    final newWeekHistory = await _loadWeekHistory();

    if (mounted) {
      setState(() {
        _streak = newStreak;
        _weekHistory = newWeekHistory;
      });

      if (_completed.every((c) => c) && !_completed.every((c) => !c)) {
        _showCelebration();
      }
    }
  }

  Future<void> _replaceTask(int index) async {
    final oldTask = _todayTasks[index];
    final newTask = await TaskManager.replaceTask(oldTask.id);

    setState(() {
      _todayTasks[index] = newTask;
      _completed[index] = false;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tracker_$_todayKey', jsonEncode({
      'taskIds': _todayTasks.map((t) => t.id).toList(),
      'completed': _completed,
      'date': _todayKey,
    }));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔄 Задание заменено: ${newTask.title}'),
          backgroundColor: const Color(0xFF00D4AA),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCelebration() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _streak > 1
                    ? ' Серия: $_streak дней подряд!'
                    : '✅ Все задания выполнены!',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00D4AA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getMotivation() {
    final completedCount = _completed.where((c) => c).length;
    if (completedCount == 0) return 'Начни с первого задания. Один шаг к лучшей версии себя! 🌱';
    if (completedCount == 1) return 'Половина пути! Осталось одно задание 💪';
    if (_streak == 0) return 'Отлично! Первое выполнение. Так держать!';
    if (_streak < 3) return 'Хорошее начало! Продолжай в том же духе ';
    if (_streak < 7) return 'Отличная серия! Ты на правильном пути 🎯';
    if (_streak < 14) return 'Неделя дисциплины! Ты крут! 🏆';
    if (_streak < 30) return 'Месяц привычки! Легенда! ';
    return '$_streak дней! Ты вдохновляешь! 🌟';
  }

  String _getDifficultyText(int level) {
    switch (level) {
      case 1: return 'Легко';
      case 2: return 'Просто';
      case 3: return 'Средне';
      case 4: return 'Сложно';
      case 5: return 'Очень сложно';
      default: return 'Средне';
    }
  }

  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1: return Colors.green;
      case 2: return const Color(0xFF00D4AA);
      case 3: return Colors.orange;
      case 4: return Colors.deepOrange;
      case 5: return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1115),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF00D4AA))),
      );
    }

    if (_todayTasks.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1115),
        body: Center(child: Text('Ошибка загрузки заданий', style: TextStyle(color: Colors.white))),
      );
    }

    final completedCount = _completed.where((c) => c).length;
    final progress = completedCount / 2;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Задания дня',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                const SizedBox(width: 6),
                Text(
                  '$_streak дн.',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Прогресс-кольцо
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
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
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$completedCount из 2',
                          style: TextStyle(color: Colors.grey[400]!, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Недельная история
              _buildWeekHistory(),
              const SizedBox(height: 20),

              // Карточки заданий
              ..._todayTasks.asMap().entries.map((entry) {
                final index = entry.key;
                final task = entry.value;
                return _buildTaskCard(task, index);
              }),
              const SizedBox(height: 20),

              // Мотивация
              _buildMotivationCard(),
              const SizedBox(height: 20),

              // Дата
              Text(
                '📅 ${_formatDate(DateTime.now())}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Эта неделя',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekHistory.map((day) {
              return Column(
                children: [
                  Text(
                    day['dayName'] as String,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: day['isToday'] == true
                          ? const Color(0xFF00D4AA).withValues(alpha: 0.3)
                          : (day['completed'] == true
                              ? const Color(0xFF00D4AA)
                              : Colors.grey[800]),
                      border: Border.all(
                        color: day['isToday'] == true
                            ? const Color(0xFF00D4AA)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: day['completed'] == true
                        ? const Icon(Icons.check, color: Colors.black, size: 18)
                        : null,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, int index) {
    final category = TaskManager.getCategoryByTaskId(task.id);
    final isCompleted = _completed[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [
                  const Color(0xFF00D4AA).withValues(alpha: 0.2),
                  Colors.grey[900]!,
                ]
              : [
                  const Color(0xFF00D4AA).withValues(alpha: 0.05),
                  Colors.grey[900]!,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF00D4AA)
              : const Color(0xFF00D4AA).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка: категория + сложность + кнопка замены
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    category.title,
                    style: const TextStyle(
                      color: Color(0xFF00D4AA),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(task.difficulty).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getDifficultyText(task.difficulty),
                      style: TextStyle(
                        color: _getDifficultyColor(task.difficulty),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _replaceTask(index),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.refresh, color: Colors.grey[400]!, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Название задания
          Text(
            task.title,
            style: TextStyle(
              color: isCompleted ? Colors.grey[400]! : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 8),

          // Описание
          Text(
            task.description,
            style: TextStyle(
              color: Colors.grey[400]!,
              fontSize: 14,
              height: 1.4,
            ),
          ),

          // Медицинское предупреждение
          if (task.medicalWarning != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Важно: ${task.medicalWarning}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Альтернативы
          if (task.alternatives != null && task.alternatives!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    ' Альтернативы:',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...task.alternatives!.map((alt) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.blue, fontSize: 12)),
                        Expanded(
                          child: Text(
                            alt,
                            style: TextStyle(
                              color: Colors.blue.withValues(alpha: 0.9),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],

          // Спонсорские ссылки
          if (task.sponsorLinks != null && task.sponsorLinks!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...task.sponsorLinks!.map((link) => GestureDetector(
              onTap: () {
                // TODO: Открыть URL
                debugPrint('Открыть: ${link.url}');
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      link.type == 'video' ? Icons.play_circle : Icons.shopping_bag,
                      color: const Color(0xFF00D4AA),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link.title,
                            style: const TextStyle(
                              color: Color(0xFF00D4AA),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            link.description,
                            style: TextStyle(
                              color: Colors.grey[400]!,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Color(0xFF00D4AA), size: 14),
                  ],
                ),
              ),
            )),
          ],

          // Кнопка выполнения
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _toggleTask(index),
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: Colors.black,
              ),
              label: Text(
                isCompleted ? '✅ Выполнено' : 'Отметить выполненным',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? Colors.grey[700] : const Color(0xFF00D4AA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D4AA).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFF00D4AA), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getMotivation(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
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