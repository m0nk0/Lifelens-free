import 'package:flutter/material.dart';
import 'plan_detail_screen.dart';

class SleepQuestionnaireScreen extends StatefulWidget {
  const SleepQuestionnaireScreen({super.key});

  @override
  State<SleepQuestionnaireScreen> createState() => _SleepQuestionnaireScreenState();
}

class _SleepQuestionnaireScreenState extends State<SleepQuestionnaireScreen> {
  // 🌙 Данные анкеты
  double _duration = 7.0;
  int _wakeHour = 7;
  String _chronotype = 'neutral';
  List<String> _issues = [];
  String _routine = 'no_screens';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    final padding = isTablet ? 40.0 : 20.0;
    final titleSize = isTablet ? 32.0 : 22.0;
    final sectionSize = isTablet ? 26.0 : 18.0;
    final valueSize = isTablet ? 32.0 : 20.0;
    final iconSize = isTablet ? 48.0 : 28.0;
    final chipHeight = isTablet ? 60.0 : 44.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text("Протокол сна", style: TextStyle(fontSize: titleSize)),
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection("🕐 Режим сна", sectionSize),
              
              _buildStepper(
                "Длительность сна (ч)", 
                _duration, 
                4, 10, 
                0.5, 
                (val) => setState(() => _duration = val),
                isTablet, valueSize, iconSize
              ),

              _buildStepper(
                "Желаемый подъём (час)", 
                _wakeHour.toDouble(), 
                5, 10, 
                1.0, 
                (val) => setState(() => _wakeHour = val.round()),
                isTablet, valueSize, iconSize
              ),

              const SizedBox(height: 20),
              _buildSection("🦉 Хронотип", sectionSize),
              _buildChipRow(
                ["Жаворонок", "Сова", "Нейтральный"],
                ["early_bird", "night_owl", "neutral"],
                _chronotype,
                (val) => setState(() => _chronotype = val),
                chipHeight, isTablet
              ),

              const SizedBox(height: 20),
              _buildSection("🚧 Проблемы со сном", sectionSize),
              _buildMultiSelectChips(
                ["Трудно уснуть", "Просыпаюсь ночью", "Храп/апноэ", "Нет проблем"],
                ["fall_asleep", "wake_up", "snoring", "none"],
                _issues,
                (val) {
                  setState(() {
                    if (_issues.contains(val)) {
                      _issues.remove(val);
                    } else {
                      if (val == "none") _issues.clear();
                      _issues.add(val);
                    }
                    if (val != "none" && _issues.contains("none")) {
                      _issues.remove("none");
                    }
                  });
                },
                chipHeight, isTablet
              ),

              const SizedBox(height: 20),
              _buildSection("🛁 Вечерний ритуал", sectionSize),
              _buildChipRow(
                ["Чтение", "Медитация", "Без экранов", "Тёплый душ"],
                ["reading", "meditation", "no_screens", "shower"],
                _routine,
                (val) => setState(() => _routine = val),
                chipHeight, isTablet
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: isTablet ? 70.0 : 55.0,
                child: ElevatedButton(
                  onPressed: _issues.isEmpty ? null : _calculateAndNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _issues.isEmpty ? Colors.grey[800] : const Color(0xFF00D4AA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: Text(
                    "Построить протокол сна",
                    style: TextStyle(
                      color: _issues.isEmpty ? Colors.grey[600] : Colors.black,
                      fontSize: isTablet ? 24.0 : 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _calculateAndNavigate() {
    // 🔬 Логика расчёта
    int bedtimeHour = _wakeHour - _duration.round();
    if (bedtimeHour < 0) bedtimeHour += 24;
    
    String chronotypeLabel = {
      'early_bird': 'Жаворонок',
      'night_owl': 'Сова',
      'neutral': 'Нейтральный'
    }[_chronotype]!;

    String routineLabel = {
      'reading': 'Чтение книги',
      'meditation': 'Медитация 10 мин',
      'no_screens': 'Отказ от экранов за 1 ч',
      'shower': 'Тёплый душ/ванна'
    }[_routine]!;

    List<String> tips = [];
    if (_issues.contains("fall_asleep")) tips.add("• Метод 4-7-8: вдох 4с, задержка 7с, выдох 8с. Снижает время засыпания на 30%");
    if (_issues.contains("wake_up")) tips.add("• Поддерживай температуру в спальне 18-20°C. Это критично для фазы глубокого сна");
    if (_chronotype == "night_owl") tips.add("• Используй маску для сна и плотные шторы. Свет подавляет мелатонин");
    if (_routine == "no_screens") tips.add("• Синий свет экранов сдвигает циркадные ритмы на 1.5 часа. Фильтр или отказ обязательны");
    tips.add("• Стабильное время отбоя важнее длительности. Сдвиг >1 часа в выходные = социальный джетлаг");

    // 🚀 Навигация на экран деталей
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanDetailScreen(
          data: {
            'title': '😴 Ваш протокол сна',
            'impact': 'Отбой в ${bedtimeHour.toString().padLeft(2, '0')}:00 | Подъём в ${_wakeHour.toString().padLeft(2, '0')}:00',
            'details': 'Хронотип: $chronotypeLabel\nРитуал: $routineLabel\nДлительность: ${_duration.toStringAsFixed(1)} ч\n\nРекомендации:\n${tips.join('\n')}',
            'science': 'Национальный фонд сна (NSF) рекомендует 7-9 ч для взрослых. Регулярный режим снижает риск деменции на 40% и улучшает консолидацию памяти.'
          },
        ),
      ),
    );
  }

  // --- ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ (идентичны HealthForm для единообразия) ---

  Widget _buildSection(String title, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
      child: Text(title, style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStepper(String label, double value, double min, double max, double step, Function(double) onChange, bool isTablet, double valueSize, double iconSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: valueSize * 0.8)),
          Row(
            children: [
              _buildCircleButton(Icons.remove, () { if (value > min) onChange(value - step); }, iconSize),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(value.toStringAsFixed(step < 1 ? 1 : 0), style: TextStyle(color: Colors.white, fontSize: valueSize, fontWeight: FontWeight.bold)),
              ),
              _buildCircleButton(Icons.add, () { if (value < max) onChange(value + step); }, iconSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onPressed, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        child: Icon(icon, color: const Color(0xFF00D4AA)),
      ),
    );
  }

  Widget _buildChipRow(List<String> labels, List<String> values, String groupValue, Function(String) onTap, double height, bool isTablet) {
    return Row(
      children: List.generate(labels.length, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildChip(labels[i], values[i] == groupValue, () => onTap(values[i]), height, isTablet),
          ),
        );
      }),
    );
  }

  Widget _buildMultiSelectChips(List<String> labels, List<String> values, List<String> selected, Function(String) onTap, double height, bool isTablet) {
    return Column(
      children: List.generate(labels.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _buildChip(labels[i], selected.contains(values[i]), () => onTap(values[i]), height, isTablet),
        );
      }),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap, double height, bool isTablet) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D4AA) : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF00D4AA) : Colors.grey[700]!),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 18.0 : 14.0,
          ),
        ),
      ),
    );
  }
}