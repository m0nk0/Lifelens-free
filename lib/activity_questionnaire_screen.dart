import 'package:flutter/material.dart';
import 'plan_detail_screen.dart';

class ActivityQuestionnaireScreen extends StatefulWidget {
  const ActivityQuestionnaireScreen({super.key});

  @override
  State<ActivityQuestionnaireScreen> createState() => _ActivityQuestionnaireScreenState();
}

class _ActivityQuestionnaireScreenState extends State<ActivityQuestionnaireScreen> {
  String? _level;
  String? _type;
  double _hours = 3.0;
  List<String> _limitations = [];
  String? _goal;

  bool get _isValid => 
      _level != null && 
      _type != null && 
      _goal != null && 
      _limitations.isNotEmpty;

  String _generatePlan() {
    final levelText = {
      'beginner': 'Новичок', 'intermediate': 'Средний', 'advanced': 'Продвинутый'
    }[_level]!;
    
    final typeText = {
      'cardio': 'Кардио', 'strength': 'Силовые', 'flexibility': 'Гибкость/Йога', 'mixed': 'Смешанные'
    }[_type]!;

    final goalText = {
      'loss': 'Снижение веса', 'muscle': 'Набор мышц', 'endurance': 'Выносливость', 'health': 'Здоровье'
    }[_goal]!;

    String plan = 'Уровень: $levelText | Тип: $typeText | Цель: $goalText\n';
    plan += 'Время: ${_hours.toStringAsFixed(1)} ч/нед\n\n';
    
    if (_level == 'beginner') {
      plan += '📅 Структура недели:\n• 3 тренировки по 30-40 мин\n• 2 дня активного восстановления (прогулка, растяжка)\n• 2 дня полного отдыха\n\n';
      plan += ' Интенсивность: 60-70% от максимума. Фокус на технике, а не на весах.\n';
    } else if (_level == 'intermediate') {
      plan += '📅 Структура недели:\n• 4 тренировки по 45-60 мин\n• 1 день активного восстановления\n• 2 дня отдыха\n\n';
      plan += ' Интенсивность: 70-80%. Постепенное увеличение нагрузки на 5-10% каждые 2 недели.\n';
    } else {
      plan += '📅 Структура недели:\n• 5-6 тренировок по 60-90 мин\n• 1 день лёгкого кардио/мобильности\n• 1 день отдыха\n\n';
      plan += '⚡ Интенсивность: 80-90%. Периодизация нагрузки, чередование объёма и интенсивности.\n';
    }

    if (_type == 'cardio') plan += ' Акцент: бег, велосипед, плавание, интервальные тренировки (HIIT).\n';
    if (_type == 'strength') plan += '🏋️ Акцент: базовые упражнения (присед, тяга, жим), прогрессия весов.\n';
    if (_type == 'flexibility') plan += '🧘 Акцент: динамическая растяжка, йога, пилатес, мобильность суставов.\n';
    if (_type == 'mixed') plan += '🔄 Акцент: 2 дня силовых, 2 дня кардио, 1 день функциональной тренировки.\n';

    if (_limitations.contains('joints')) plan += '\n⚠️ При проблемах с суставами: исключи ударную нагрузку, замени бег на эллипс/велотренажёр, используй поддержку.\n';
    if (_limitations.contains('back')) plan += '\n⚠️ При проблемах со спиной: избегай осевой нагрузки, добавь упражнения на укрепление кора.\n';
    if (_limitations.contains('heart')) plan += '\n❤️ При сердечно-сосудистых особенностях: следи за пульсом (не выше 130-140 уд/мин), избегай натуживания.\n';

    return plan.trim();
  }

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
        title: Text("План активности", style: TextStyle(fontSize: titleSize)),
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection("📊 Текущий уровень", sectionSize),
              _buildChipRow(["Новичок", "Средний", "Продвинутый"], ["beginner", "intermediate", "advanced"], _level, (v) => setState(() => _level = v), chipHeight, isTablet),

              const SizedBox(height: 20),
              _buildSection("🎯 Предпочтения", sectionSize),
              _buildChipRow(["Кардио", "Силовые", "Йога/Гибкость", "Смешанные"], ["cardio", "strength", "flexibility", "mixed"], _type, (v) => setState(() => _type = v), chipHeight, isTablet),

              const SizedBox(height: 20),
              _buildStepper("Время в неделю (ч)", _hours, 1, 10, 0.5, (val) => setState(() => _hours = val), isTablet, valueSize, iconSize),

              const SizedBox(height: 20),
              _buildSection("🚧 Ограничения", sectionSize),
              _buildMultiSelectChips(["Суставы", "Спина", "Сердце", "Нет ограничений"], ["joints", "back", "heart", "none"], _limitations, (val) {
                setState(() {
                  if (_limitations.contains(val)) {
                    _limitations.remove(val);
                  } else {
                    if (val == "none") _limitations.clear();
                    _limitations.add(val);
                  }
                  if (val != "none" && _limitations.contains("none")) _limitations.remove("none");
                });
              }, chipHeight, isTablet),

              const SizedBox(height: 20),
              _buildSection("🏁 Цель", sectionSize),
              _buildChipRow(["Снижение веса", "Набор мышц", "Выносливость", "Здоровье"], ["loss", "muscle", "endurance", "health"], _goal, (v) => setState(() => _goal = v), chipHeight, isTablet),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: isTablet ? 70.0 : 55.0,
                child: ElevatedButton(
                  onPressed: _isValid ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlanDetailScreen(
                          data: {
                            'title': ' Ваш план активности',
                            'impact': '${_hours.toStringAsFixed(1)} ч/нед | $_type | $_goal',
                            'details': _generatePlan(),
                            'science': 'ВОЗ рекомендует 150-300 мин умеренной активности в неделю. Регулярные тренировки снижают риск ССЗ на 35%, депрессии на 30% и улучшают когнитивные функции.',
                            'disclaimer': 'ОБЯЗАТЕЛЬНО ПРОКОНСУЛЬТИРУЙТЕСЬ С ВРАЧОМ!\n\nПеред началом тренировок убедитесь в отсутствии противопоказаний. При наличии хронических заболеваний, травм или беременности нагрузки могут быть опасны. Прислушивайтесь к своему телу и не превозмогайте боль.'
                          },
                        ),
                      ),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isValid ? const Color(0xFF00D4AA) : Colors.grey[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    "Построить план",
                    style: TextStyle(
                      color: _isValid ? Colors.black : Colors.grey[600],
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

  // --- ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ---
  Widget _buildSection(String title, double fontSize) =>
      Padding(padding: const EdgeInsets.only(top: 12.0, bottom: 12.0), child: Text(title, style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)));

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
              Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text(value.toStringAsFixed(step < 1 ? 1 : 0), style: TextStyle(color: Colors.white, fontSize: valueSize, fontWeight: FontWeight.bold))),
              _buildCircleButton(Icons.add, () { if (value < max) onChange(value + step); }, iconSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onPressed, double size) {
    return SizedBox(
      width: size, height: size,
      child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: EdgeInsets.zero, shape: const CircleBorder()), child: Icon(icon, color: const Color(0xFF00D4AA))),
    );
  }

  Widget _buildChipRow(List<String> labels, List<String> values, String? groupValue, Function(String) onTap, double height, bool isTablet) {
    return Row(children: List.generate(labels.length, (i) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8.0), child: _buildChip(labels[i], values[i] == groupValue, () => onTap(values[i]), height, isTablet)))));
  }

  Widget _buildMultiSelectChips(List<String> labels, List<String> values, List<String> selected, Function(String) onTap, double height, bool isTablet) {
    return Column(children: List.generate(labels.length, (i) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: _buildChip(labels[i], selected.contains(values[i]), () => onTap(values[i]), height, isTablet))));
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap, double height, bool isTablet) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height, alignment: Alignment.center,
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF00D4AA) : Colors.grey[900], borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? const Color(0xFF00D4AA) : Colors.grey[700]!)),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: isTablet ? 18.0 : 14.0)),
      ),
    );
  }
}