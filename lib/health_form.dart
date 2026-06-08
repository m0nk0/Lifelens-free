import 'package:flutter/material.dart';
import 'bio_age_calculator.dart';
import 'result_screen.dart';

class HealthForm extends StatefulWidget {
  final int faceAgeEstimate;
  final double faceBrightness;
  const HealthForm({super.key, required this.faceAgeEstimate, required this.faceBrightness});

  @override
  State<HealthForm> createState() => _HealthFormState();
}

class _HealthFormState extends State<HealthForm> {
  double _age = 30.0;
  String _gender = 'male';
  double _height = 175.0;
  double _weight = 75.0;
  bool _smokes = false;
  double _sleep = 7.0;
  String _activity = 'medium';

  void _calculate() {
    final result = BioAgeCalculator.calculate(
      chronoAge: _age.round(),
      gender: _gender,
      heightCm: _height,
      weightKg: _weight,
      smokes: _smokes,
      sleepHours: _sleep.round(),
      activity: _activity,
      faceAgeEstimate: widget.faceAgeEstimate,
      faceBrightness: widget.faceBrightness,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 📱 Адаптивность: определяем, планшет или телефон
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    // Настройка размеров
    final padding = isTablet ? 40.0 : 20.0;
    final titleSize = isTablet ? 32.0 : 22.0;
    final sectionSize = isTablet ? 26.0 : 18.0;
    final valueSize = isTablet ? 32.0 : 20.0;
    final iconSize = isTablet ? 48.0 : 28.0; // Размер кнопок +/-
    final chipHeight = isTablet ? 60.0 : 44.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text("Анкета здоровья", style: TextStyle(fontSize: titleSize)),
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection("👤 Основные данные", sectionSize),
              
              // Возраст (Stepper)
              _buildStepper(
                "Возраст", 
                _age, 
                18, 80, 
                1.0, // Шаг
                (val) => setState(() => _age = val),
                isTablet, valueSize, iconSize
              ),
              // ✅ Пояснение под возрастом
             Padding(
             padding: EdgeInsets.only(left: isTablet ? 40 : 20, bottom: 16),
            child: Text(
            'Это нужно для расчета реальной разницы с биологическим возрастом и оценки вероятной продолжительности жизни.',
            style: TextStyle(
            color: Colors.grey[400], 
            fontSize: isTablet ? 13 : 11, 
            height: 1.3, 
           fontStyle: FontStyle.italic,
               ),
             ),
           ),

              // Пол (Chips)
              _buildLabel("Пол", sectionSize),
              Row(
                children: [
                  Expanded(
                    child: _buildChip("Мужской", _gender == 'male', () => setState(() => _gender = 'male'), chipHeight, isTablet),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildChip("Женский", _gender == 'female', () => setState(() => _gender = 'female'), chipHeight, isTablet),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              _buildSection("📏 Телосложение", sectionSize),
              
              // Рост (Stepper)
              _buildStepper(
                "Рост (см)", 
                _height, 
                140, 220, 
                1.0, 
                (val) => setState(() => _height = val),
                isTablet, valueSize, iconSize
              ),

              // Вес (Stepper)
              _buildStepper(
                "Вес (кг)", 
                _weight, 
                40, 160, 
                0.5, // Шаг 0.5 для точности
                (val) => setState(() => _weight = val),
                isTablet, valueSize, iconSize
              ),

              const SizedBox(height: 20),
              _buildSection("🫁 Привычки", sectionSize),

              // Курение
              _buildCheckbox("Курение", _smokes, (v) => setState(() => _smokes = v!), isTablet, sectionSize),

              // Сон (Stepper)
              _buildStepper(
                "Сон (часов)", 
                _sleep, 
                4, 10, 
                0.5, 
                (val) => setState(() => _sleep = val),
                isTablet, valueSize, iconSize
              ),

              // Активность (Chips)
              _buildLabel("Активность", sectionSize),
              Column(
                children: [
                  _buildChip("Низкая (офис)", _activity == 'low', () => setState(() => _activity = 'low'), chipHeight, isTablet),
                  const SizedBox(height: 8),
                  _buildChip("Средняя (спорт 1-3 раза)", _activity == 'medium', () => setState(() => _activity = 'medium'), chipHeight, isTablet),
                  const SizedBox(height: 8),
                  _buildChip("Высокая (спорт 4+ раза)", _activity == 'high', () => setState(() => _activity = 'high'), chipHeight, isTablet),
                ],
              ),

              const SizedBox(height: 40),

              // 🚀 Кнопка расчета
              SizedBox(
                width: double.infinity,
                height: isTablet ? 70.0 : 55.0,
                child: ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: Text(
                    "Рассчитать биовозраст",
                    style: TextStyle(
                      color: Colors.black, 
                      fontSize: isTablet ? 24.0 : 18.0,
                      fontWeight: FontWeight.bold
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

  Widget _buildSection(String title, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
      child: Text(title, style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLabel(String title, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: TextStyle(color: Colors.white70, fontSize: fontSize)),
    );
  }

  // Виджет с кнопками +/-
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

  // Виджет чипса (кнопки выбора)
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

  // Виджет чекбокса
  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged, bool isTablet, double fontSize) {
    return CheckboxListTile(
      title: Text(label, style: TextStyle(color: Colors.white70, fontSize: fontSize)),
      value: value,
      activeColor: const Color(0xFF00D4AA),
      checkColor: Colors.black,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}