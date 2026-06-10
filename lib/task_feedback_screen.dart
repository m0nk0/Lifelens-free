import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'task_manager.dart';
import 'task_database.dart';
import 'tracker_screen.dart';

class TaskFeedbackScreen extends StatefulWidget {
  const TaskFeedbackScreen({super.key});

  @override
  State<TaskFeedbackScreen> createState() => _TaskFeedbackScreenState();
}

class _TaskFeedbackScreenState extends State<TaskFeedbackScreen> {
  bool _isLoading = true;
  bool _isFirstDay = false;

  // Для первого дня — выбор 2 категорий
  final Set<String> _selectedCategories = {};

  // Для последующих дней — опросник
  bool _liked = true;
  bool _wasHard = false;
  bool _wantChange = false;
  List<Task>? _yesterdayTasks;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final hasHistory = await TaskManager.hasHistory();
    final hasTodayTasks = await TaskManager.hasTodayTasks();

    if (!hasHistory || !hasTodayTasks) {
      // Первый день — показываем выбор категорий
      setState(() {
        _isFirstDay = true;
        _isLoading = false;
      });
    } else {
      // Последующие дни — показываем опросник
      await _loadYesterdayTasks();
    }
  }

  Future<void> _loadYesterdayTasks() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey = yesterday.toIso8601String().split('T')[0];

      final prefs = await SharedPreferences.getInstance();
      final taskJson = prefs.getString('today_tasks_$yesterdayKey');

      if (taskJson != null) {
        final List<dynamic> taskIds = jsonDecode(taskJson);
        final tasks = taskIds.map((id) => TaskManager.findTaskById(id)).toList();
        setState(() {
          _yesterdayTasks = tasks;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('️ Ошибка загрузки вчерашних заданий: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else if (_selectedCategories.length < 2) {
        _selectedCategories.add(categoryId);
      }
    });
  }

  Future<void> _submitFirstDay() async {
    if (_selectedCategories.length != 2) return;

    final categories = TaskDatabase.getAllCategories();
    final selected = categories.where((c) => _selectedCategories.contains(c.id)).toList();

    final List<Task> tasks = [];
    for (var category in selected) {
      final task = await _pickRandomTask(category.id);
      tasks.add(task);
    }

    await TaskManager.saveTodayTasks(tasks);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TrackerScreen()),
      );
    }
  }

  Future<Task> _pickRandomTask(String categoryId) async {
    final categories = TaskDatabase.getAllCategories();
    final category = categories.firstWhere((c) => c.id == categoryId);
    final random = DateTime.now().millisecondsSinceEpoch % category.tasks.length;
    return category.tasks[random];
  }

  Future<void> _submitFeedback() async {
    final hasTask = await TaskManager.hasTodayTasks();
    List<String>? currentTaskIds;

    if (hasTask) {
      final tasks = await TaskManager.getTodayTasks();
      currentTaskIds = tasks.map((t) => t.id).toList();
    }

    if (currentTaskIds != null) {
      await TaskManager.saveFeedback(
        taskIds: currentTaskIds,
        liked: _liked,
        wasHard: _wasHard,
        wantChange: _wantChange,
      );
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TrackerScreen()),
      );
    }
  }

  Future<void> _skipFeedback() async {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TrackerScreen()),
      );
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isFirstDay ? 'Выбери приоритеты' : 'Подбор заданий',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _isFirstDay ? _buildFirstDayUI() : _buildFeedbackUI(),
        ),
      ),
    );
  }

  Widget _buildFirstDayUI() {
    final categories = TaskDatabase.getAllCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00D4AA).withValues(alpha: 0.2),
                Colors.grey[900]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              const Icon(Icons.flag, color: Color(0xFF00D4AA), size: 48),
              const SizedBox(height: 12),
              const Text(
                'Добро пожаловать в LifeLens!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Выбери 2 приоритета на сегодня — мы подберём задания под тебя',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Выбрано: ${_selectedCategories.length} из 2',
          style: TextStyle(
            color: _selectedCategories.length == 2 ? const Color(0xFF00D4AA) : Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        ...categories.map((category) {
          final isSelected = _selectedCategories.contains(category.id);
          return GestureDetector(
            onTap: () => _toggleCategory(category.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00D4AA).withValues(alpha: 0.15)
                    : Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00D4AA) : Colors.grey[800]!,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      category.title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[300],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Color(0xFF00D4AA), size: 24),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed: _selectedCategories.length == 2 ? _submitFirstDay : null,
          icon: const Icon(Icons.arrow_forward, color: Colors.black),
          label: const Text(
            'Подобрать задания',
            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedCategories.length == 2
                ? const Color(0xFF00D4AA)
                : Colors.grey[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00D4AA).withValues(alpha: 0.2),
                Colors.grey[900]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              const Icon(Icons.rate_review, color: Color(0xFF00D4AA), size: 48),
              const SizedBox(height: 12),
              const Text(
                'Помоги подобрать задания на сегодня',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_yesterdayTasks != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Вчерашние задания:',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 8),
                ..._yesterdayTasks!.map((task) {
                  final category = TaskManager.getCategoryByTaskId(task.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${category.emoji} ${task.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        _buildQuestion(
          question: 'Понравились ли вчерашние задания?',
          value: _liked,
          onChanged: (val) => setState(() => _liked = val),
        ),
        const SizedBox(height: 16),

        _buildQuestion(
          question: 'Сложно ли было выполнить?',
          value: _wasHard,
          onChanged: (val) => setState(() => _wasHard = val),
        ),
        const SizedBox(height: 16),

        _buildQuestion(
          question: 'Хотите другие задания на сегодня?',
          value: _wantChange,
          onChanged: (val) => setState(() => _wantChange = val),
        ),
        const SizedBox(height: 32),

        ElevatedButton.icon(
          onPressed: _submitFeedback,
          icon: const Icon(Icons.arrow_forward, color: Colors.black),
          label: const Text(
            'Подобрать задания',
            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4AA),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),

        TextButton(
          onPressed: _skipFeedback,
          child: Text(
            'Пропустить опрос',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion({
    required String question,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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
          Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  label: 'Да',
                  icon: Icons.thumb_up,
                  isSelected: value,
                  onTap: () => onChanged(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleButton(
                  label: 'Нет',
                  icon: Icons.thumb_down,
                  isSelected: !value,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00D4AA).withValues(alpha: 0.2)
              : Colors.grey[850],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF00D4AA) : Colors.grey[800]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00D4AA) : Colors.grey[500],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00D4AA) : Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}