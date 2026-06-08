import 'package:flutter/material.dart';
import 'plan_detail_screen.dart';

class NutritionQuestionnaireScreen extends StatefulWidget {
  const NutritionQuestionnaireScreen({super.key});

  @override
  State<NutritionQuestionnaireScreen> createState() => _NutritionQuestionnaireScreenState();
}

class _NutritionQuestionnaireScreenState extends State<NutritionQuestionnaireScreen> {
  String? _gender;
  int? _age;
  double? _weight;
  double? _height;
  String? _activity;
  String? _goal;

  bool get _isFormValid =>
      _gender != null &&
      _age != null && _age! >= 18 && _age! <= 100 &&
      _weight != null && _weight! >= 30 && _weight! <= 300 &&
      _height != null && _height! >= 120 && _height! <= 250 &&
      _activity != null &&
      _goal != null;

  Map<String, dynamic> _calculatePlan() {
    final bmr = _gender == 'male'
        ? (10 * _weight! + 6.25 * _height! - 5 * _age! + 5)
        : (10 * _weight! + 6.25 * _height! - 5 * _age! - 161);

    final activityMultiplier = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    }[_activity]!;

    final tdee = bmr * activityMultiplier;
    final goalAdjustment = {'lose': -500, 'maintain': 0, 'gain': 300}[_goal]!;
    final targetCalories = (tdee + goalAdjustment).round();
    
    return {
      'calories': targetCalories,
      'protein': ((targetCalories * 0.3) / 4).round(),
      'fat': ((targetCalories * 0.3) / 9).round(),
      'carbs': ((targetCalories * 0.4) / 4).round(),
      'bmr': bmr.round(),
      'tdee': tdee.round(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final padding = isTablet ? 40.0 : 20.0;
    final titleSize = isTablet ? 32.0 : 22.0;
    final sectionSize = isTablet ? 26.0 : 18.0;
    final valueSize = isTablet ? 20.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text('План питания', style: TextStyle(fontSize: titleSize)),
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
              Text('Персональный расчёт', style: TextStyle(color: Colors.white, fontSize: titleSize, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Ответьте на вопросы — расчёт займёт 30 секунд', style: TextStyle(color: Colors.grey[400], fontSize: valueSize)),
              const SizedBox(height: 24),

              _buildSection('Ваш пол', sectionSize),
              Row(
                children: [
                  Expanded(child: _buildChip('Мужской', _gender == 'male', () => setState(() => _gender = 'male'), isTablet)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildChip('Женский', _gender == 'female', () => setState(() => _gender = 'female'), isTablet)),
                ],
              ),
              const SizedBox(height: 20),

              _buildSection('Возраст', sectionSize),
              _buildTextField(_age?.toString() ?? '', TextInputType.number, (v) => setState(() => _age = int.tryParse(v))),
              const SizedBox(height: 20),

              _buildSection('Вес (кг)', sectionSize),
              _buildTextField(_weight?.toString() ?? '', TextInputType.numberWithOptions(decimal: true), (v) => setState(() => _weight = double.tryParse(v))),
              const SizedBox(height: 20),

              _buildSection('Рост (см)', sectionSize),
              _buildTextField(_height?.toString() ?? '', TextInputType.number, (v) => setState(() => _height = double.tryParse(v))),
              const SizedBox(height: 20),

              _buildSection('Уровень активности', sectionSize),
              _buildRadio('Сидячий (офис, мало движения)', 'sedentary', _activity, (v) => setState(() => _activity = v)),
              _buildRadio('Лёгкая (прогулки 1-3 раза/нед)', 'light', _activity, (v) => setState(() => _activity = v)),
              _buildRadio('Умеренная (тренировки 3-5 раз/нед)', 'moderate', _activity, (v) => setState(() => _activity = v)),
              _buildRadio('Высокая (ежедневные тренировки)', 'active', _activity, (v) => setState(() => _activity = v)),
              _buildRadio('Очень высокая (физ. работа + спорт)', 'very_active', _activity, (v) => setState(() => _activity = v)),
              const SizedBox(height: 20),

              _buildSection('Ваша цель', sectionSize),
              _buildRadio('Снижение веса', 'lose', _goal, (v) => setState(() => _goal = v)),
              _buildRadio('Поддержание веса', 'maintain', _goal, (v) => setState(() => _goal = v)),
              _buildRadio('Набор массы', 'gain', _goal, (v) => setState(() => _goal = v)),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: isTablet ? 70.0 : 55.0,
                child: ElevatedButton(
                  onPressed: _isFormValid ? () {
                    final plan = _calculatePlan();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlanDetailScreen(
                          data: {
                            'title': '⚖️ Ваш план питания',
                            'impact': '${plan['calories']} ккал/день',
                            'details': 'Белки: ${plan['protein']} г | Жиры: ${plan['fat']} г | Углеводы: ${plan['carbs']} г\n\nBMR: ${plan['bmr']} ккал | TDEE: ${plan['tdee']} ккал',
                            'science': 'Расчёт по формуле Миффлина-Сан Жеора (WHO). Дефицит/профицит подобран под цель: ${_goal == 'lose' ? 'снижение' : _goal == 'gain' ? 'набор' : 'поддержание'}.'
                          },
                        ),
                      ),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid ? const Color(0xFF00D4AA) : Colors.grey[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Рассчитать план',
                    style: TextStyle(
                      color: _isFormValid ? Colors.black : Colors.grey[600],
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

  Widget _buildSection(String title, double fontSize) =>
      Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Text(title, style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)));

  Widget _buildTextField(String hint, TextInputType type, Function(String) onChanged) {
    return TextField(
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint.isEmpty ? 'Введите значение' : hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap, bool isTablet) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isTablet ? 60.0 : 44.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D4AA) : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF00D4AA) : Colors.grey[700]!),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: isTablet ? 18.0 : 14.0)),
      ),
    );
  }

  // ✅ ИСПРАВЛЕНО: Теперь принимает callback и обновляет состояние
  Widget _buildRadio(String label, String value, String? groupValue, Function(String?) onChanged) {
    return RadioListTile<String>(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: value,
      groupValue: groupValue,
      activeColor: const Color(0xFF00D4AA),
      onChanged: onChanged, // <-- Теперь реально обновляет _activity / _goal
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}