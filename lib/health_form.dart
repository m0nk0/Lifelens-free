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
  final _formKey = GlobalKey<FormState>();
  double _age = 30.0;
  String _gender = 'male';
  double _height = 175.0;
  double _weight = 75.0;
  bool _smokes = false;
  double _sleep = 7.0;
  String _activity = 'medium';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

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
    return Scaffold(
      appBar: AppBar(title: const Text("Анкета здоровья"), backgroundColor: const Color(0xFF0F1115)),
      backgroundColor: const Color(0xFF0F1115),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(20.0), children: [
        _buildSection("👤 Основные данные"),
        _buildSlider("Хронологический возраст", _age, 18, 80, (v) => setState(() => _age = v)),
        _buildDropdown("Пол", _gender, const {'male': 'Мужской', 'female': 'Женский'}, (v) => setState(() => _gender = v!)),
        _buildSection("📏 Телосложение"),
        _buildSlider("Рост (см)", _height, 140, 200, (v) => setState(() => _height = v)),
        _buildSlider("Вес (кг)", _weight, 40, 150, (v) => setState(() => _weight = v)),
        _buildSection("🫁 Привычки"),
        _buildCheckbox("Курение", _smokes, (v) => setState(() => _smokes = v!)),
        _buildSlider("Сон (часов/ночь)", _sleep, 4, 10, (v) => setState(() => _sleep = v)),
        _buildDropdown("Активность", _activity, const {'low': 'Низкая', 'medium': 'Средняя', 'high': 'Высокая'}, (v) => setState(() => _activity = v!)),
        const SizedBox(height: 24.0),
        ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4AA), padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), child: const Text("Рассчитать биовозраст", style: TextStyle(color: Colors.black))),
      ])),
    );
  }

  Widget _buildSection(String title) => Padding(padding: const EdgeInsets.symmetric(vertical: 16.0), child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)));
  Widget _buildSlider(String label, double value, double min, double max, void Function(double) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white70)), Text(value.round().toString(), style: const TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.bold))]),
      Slider(value: value, min: min, max: max, divisions: (max - min).round(), label: value.round().toString(), onChanged: onChanged, activeColor: const Color(0xFF00D4AA)),
    ]);
  }
  Widget _buildDropdown(String label, String value, Map<String, String> options, void Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white70)),
      Container(margin: const EdgeInsets.only(top: 8.0), padding: const EdgeInsets.symmetric(horizontal: 12.0), decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8.0)),
        child: DropdownButton<String>(value: value, isExpanded: true, underline: const SizedBox(), style: const TextStyle(color: Colors.white), items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: onChanged),
      ),
    ]);
  }
  Widget _buildCheckbox(String label, bool value, void Function(bool?) onChanged) {
    return CheckboxListTile(title: Text(label, style: const TextStyle(color: Colors.white70)), value: value, activeColor: const Color(0xFF00D4AA), onChanged: onChanged, contentPadding: EdgeInsets.zero);
  }
}