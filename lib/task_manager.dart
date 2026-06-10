import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'task_database.dart';

class TaskFeedback {
  final List<String> taskIds;
  final bool liked;
  final bool wasHard;
  final bool wantChange;
  final DateTime date;

  TaskFeedback({
    required this.taskIds,
    required this.liked,
    required this.wasHard,
    required this.wantChange,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'taskIds': taskIds,
    'liked': liked,
    'wasHard': wasHard,
    'wantChange': wantChange,
    'date': date.toIso8601String(),
  };

  factory TaskFeedback.fromJson(Map<String, dynamic> json) => TaskFeedback(
    taskIds: List<String>.from(json['taskIds']),
    liked: json['liked'],
    wasHard: json['wasHard'],
    wantChange: json['wantChange'],
    date: DateTime.parse(json['date']),
  );
}

class TaskManager {
  static const String _todayTasksKey = 'today_tasks';
  static const String _taskHistoryKey = 'task_history';
  static const String _feedbackKey = 'task_feedback';

  // Ротация ПАР категорий по дням недели (2 задания из разных категорий)
  static const Map<int, List<String>> _weeklyPairs = {
    DateTime.monday: ['nutrition', 'sleep'],
    DateTime.tuesday: ['activity', 'stress'],
    DateTime.wednesday: ['skincare', 'hydration'],
    DateTime.thursday: ['nutrition', 'activity'],
    DateTime.friday: ['sleep', 'stress'],
    DateTime.saturday: ['skincare', 'hydration'],
    DateTime.sunday: ['free', 'free'], // Свободный выбор
  };

  /// Получить 2 задания на сегодня
  static Future<List<Task>> getTodayTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];

    final savedJson = prefs.getString('${_todayTasksKey}_$today');
    if (savedJson != null) {
      final List<dynamic> taskIds = jsonDecode(savedJson);
      return taskIds.map((id) => findTaskById(id)).toList();
    }

    final tasks = await _selectNewPair();
    await saveTodayTasks(tasks);
    return tasks;
  }

  /// Сохранить 2 задания на сегодня
  static Future<void> saveTodayTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];

    await prefs.setString(
      '${_todayTasksKey}_$today',
      jsonEncode(tasks.map((t) => t.id).toList()),
    );

    for (var task in tasks) {
      await _addToHistory(task.id);
    }
  }

  /// Быстрая замена одного задания (без опросника)
  static Future<Task> replaceTask(String oldTaskId) async {
    final newTask = await _selectNewTask(
      excludeTaskIds: [oldTaskId],
      forceCategory: getCategoryByTaskId(oldTaskId).id,
    );

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedJson = prefs.getString('${_todayTasksKey}_$today');

    if (savedJson != null) {
      final List<dynamic> taskIds = jsonDecode(savedJson);
      final index = taskIds.indexOf(oldTaskId);
      if (index != -1) {
        taskIds[index] = newTask.id;
        await prefs.setString('${_todayTasksKey}_$today', jsonEncode(taskIds));
        await _addToHistory(newTask.id);
      }
    }

    return newTask;
  }

  /// Сохранить фидбек
  static Future<void> saveFeedback({
    required List<String> taskIds,
    required bool liked,
    required bool wasHard,
    required bool wantChange,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];

    final feedback = TaskFeedback(
      taskIds: taskIds,
      liked: liked,
      wasHard: wasHard,
      wantChange: wantChange,
      date: DateTime.now(),
    );

    await prefs.setString('${_feedbackKey}_$today', jsonEncode(feedback.toJson()));

    if (wantChange) {
      final newPair = await _selectNewPair(excludeTaskIds: taskIds);
      await saveTodayTasks(newPair);
    }
  }

  /// Получить фидбек за сегодня
  static Future<TaskFeedback?> getTodayFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final feedbackJson = prefs.getString('${_feedbackKey}_$today');
    if (feedbackJson == null) return null;
    return TaskFeedback.fromJson(jsonDecode(feedbackJson));
  }

  /// Проверить, есть ли задания на сегодня
  static Future<bool> hasTodayTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    return prefs.containsKey('${_todayTasksKey}_$today');
  }

  /// Проверить, есть ли история (для определения первого дня)
  static Future<bool> hasHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_taskHistoryKey) ?? [];
    return history.isNotEmpty;
  }

  /// Подобрать новую пару заданий
  static Future<List<Task>> _selectNewPair({List<String>? excludeTaskIds}) async {
    final weekday = DateTime.now().weekday;
    final pair = _weeklyPairs[weekday] ?? ['nutrition', 'sleep'];

    final List<Task> result = [];

    for (final categoryId in pair) {
      String finalCategoryId = categoryId;
      if (categoryId == 'free') {
        finalCategoryId = await _getWeakestCategory(exclude: result.map((t) => getCategoryByTaskId(t.id).id).toList());
      }
      final task = await _selectNewTask(
        forceCategory: finalCategoryId,
        excludeTaskIds: [...?excludeTaskIds, ...result.map((t) => t.id)],
      );
      result.add(task);
    }

    return result;
  }

  /// Подобрать одно задание из категории
  static Future<Task> _selectNewTask({
    required String forceCategory,
    List<String>? excludeTaskIds,
  }) async {
    final categories = TaskDatabase.getAllCategories();
    final category = categories.firstWhere((c) => c.id == forceCategory);

    final history = await _getRecentHistory(7);

    final availableTasks = category.tasks.where((task) {
      if (excludeTaskIds != null && excludeTaskIds.contains(task.id)) return false;
      if (history.contains(task.id)) return false;
      return true;
    }).toList();

    final List<Task> finalTasks;
    if (availableTasks.isEmpty) {
      finalTasks = category.tasks.where((t) => excludeTaskIds == null || !excludeTaskIds.contains(t.id)).toList();
    } else {
      finalTasks = availableTasks;
    }

    if (finalTasks.isEmpty) return category.tasks.first;

    final random = Random();
    return finalTasks[random.nextInt(finalTasks.length)];
  }

  /// Получить историю заданий за последние N дней
  static Future<List<String>> _getRecentHistory(int days) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = [];

    for (int i = 0; i < days; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = date.toIso8601String().split('T')[0];
      final taskJson = prefs.getString('${_todayTasksKey}_$dateKey');

      if (taskJson != null) {
        final List<dynamic> taskIds = jsonDecode(taskJson);
        history.addAll(taskIds.cast<String>());
      }
    }

    return history;
  }

  /// Добавить задание в историю
  static Future<void> _addToHistory(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_taskHistoryKey) ?? [];

    history.remove(taskId);
    history.insert(0, taskId);

    if (history.length > 30) {
      history.removeRange(30, history.length);
    }

    await prefs.setStringList(_taskHistoryKey, history);
  }

  /// Найти задание по ID
  static Task findTaskById(String taskId) {
    final categories = TaskDatabase.getAllCategories();
    for (final category in categories) {
      for (final task in category.tasks) {
        if (task.id == taskId) return task;
      }
    }
    return categories.first.tasks.first;
  }

  /// Получить категорию задания по ID
  static TaskCategory getCategoryByTaskId(String taskId) {
    final categories = TaskDatabase.getAllCategories();
    for (final category in categories) {
      for (final task in category.tasks) {
        if (task.id == taskId) return category;
      }
    }
    return categories.first;
  }

  /// Определить самую слабую категорию
  static Future<String> _getWeakestCategory({List<String>? exclude}) async {
    final prefs = await SharedPreferences.getInstance();
    final categoryStats = <String, int>{};

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = date.toIso8601String().split('T')[0];
      final taskJson = prefs.getString('${_todayTasksKey}_$dateKey');

      if (taskJson != null) {
        final List<dynamic> taskIds = jsonDecode(taskJson);
        for (var taskId in taskIds) {
          final category = getCategoryByTaskId(taskId);
          categoryStats[category.id] = (categoryStats[category.id] ?? 0) + 1;
        }
      }
    }

    if (categoryStats.isEmpty) return 'nutrition';

    String weakest = categoryStats.keys.first;
    int minCount = categoryStats[weakest]!;

    for (var entry in categoryStats.entries) {
      if (exclude != null && exclude.contains(entry.key)) continue;
      if (entry.value < minCount) {
        minCount = entry.value;
        weakest = entry.key;
      }
    }

    return weakest;
  }
}