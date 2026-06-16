import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'bio_age_calculator.dart';
import 'interim_result_screen.dart';
import 'processing_screen.dart';

class HealthForm extends StatefulWidget {
  final int faceAgeEstimate;
  final double faceBrightness;
  final double rawModelOutput;

  const HealthForm({
    super.key,
    required this.faceAgeEstimate,
    required this.faceBrightness,
    required this.rawModelOutput,
  });

  @override
  State<HealthForm> createState() => _HealthFormState();
}

class _HealthFormState extends State<HealthForm> {
  int _age = 30;
  String _gender = 'male';
  double _height = 175;
  double _weight = 75;
  bool _smokes = false;
  int _sleepHours = 7;
  String _activity = 'medium';

  bool _isCalculating = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _age = prefs.getInt('saved_age') ?? 30;
      _gender = prefs.getString('saved_gender') ?? 'male';
      _height = prefs.getDouble('saved_height') ?? 175.0;
      _weight = prefs.getDouble('saved_weight') ?? 75.0;
      _smokes = prefs.getBool('saved_smokes') ?? false;
      _sleepHours = prefs.getInt('saved_sleep') ?? 7;
      _activity = prefs.getString('saved_activity') ?? 'medium';
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_age', _age);
    await prefs.setString('saved_gender', _gender);
    await prefs.setDouble('saved_height', _height);
    await prefs.setDouble('saved_weight', _weight);
    await prefs.setBool('saved_smokes', _smokes);
    await prefs.setInt('saved_sleep', _sleepHours);
    await prefs.setString('saved_activity', _activity);
  }

  String _getDirection(int age, int passportAge) {
    if (age <= passportAge - 3) return 'younger';
    if (age >= passportAge + 3) return 'older';
    return 'same';
  }

  Future<void> _calculateAndProceed() async {
    if (_isCalculating) return;
    setState(() => _isCalculating = true);

    await _saveData();

    final result = BioAgeCalculator.calculate(
      chronoAge: _age, gender: _gender, heightCm: _height, weightKg: _weight,
      smokes: _smokes, sleepHours: _sleepHours, activity: _activity,
      faceAgeEstimate: widget.faceAgeEstimate, 
      faceBrightness: widget.faceBrightness, 
      rawModelOutput: widget.rawModelOutput,
    );

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final scansTodayKey = 'scans_today_$today';
    int scansToday = prefs.getInt(scansTodayKey) ?? 0;

    List<String> dailyScansStr = prefs.getStringList('daily_scans_$today') ?? [];
    int firstScanAge = dailyScansStr.isNotEmpty ? int.parse(dailyScansStr.first) : result.biologicalAge;

    int totalScanDays = prefs.getInt('total_scan_days') ?? 0;
    int anchor1 = prefs.getInt('anchor_age_1') ?? result.biologicalAge;
    int anchor2 = prefs.getInt('anchor_age_2') ?? anchor1;
    
    // Динамическое количество сканов: 3 для дней 1-4, 1 для дня 5+
    int requiredScans = (totalScanDays < 4) ? 3 : 1;

    int variedAge = result.biologicalAge;

    if (scansToday == 0) {
      if (variedAge == _age) {
        variedAge += Random().nextBool() ? 1 : -1;
        debugPrint('🛡️ [PROTECT] Первый скан совпал с паспортом! Сдвиг на ±1 → $variedAge');
      }
      String direction = _getDirection(variedAge, _age);
      await prefs.setString('initial_direction', direction);
      await prefs.setInt('last_interim_age', variedAge);
      debugPrint('🎲 [FIRST] Скан 1: Паспорт=$_age | Модель дала=$variedAge | Направление=$direction');
    } else {
      int calculatedAge = result.biologicalAge;
      String newDirection = _getDirection(calculatedAge, _age);
      String initialDirection = prefs.getString('initial_direction') ?? 'same';
      int lastAge = prefs.getInt('last_interim_age') ?? calculatedAge;

      variedAge = calculatedAge;

      if (initialDirection == 'younger' && newDirection == 'older') {
        variedAge = lastAge + 2;
      } else if (initialDirection == 'older' && newDirection == 'younger') {
        variedAge = lastAge - 2;
      } else if (initialDirection == 'same' && newDirection == 'younger') {
        variedAge = lastAge - 2;
      } else if (initialDirection == 'same' && newDirection == 'older') {
        variedAge = lastAge + 2;
      } else {
        // ЛОГИКА РАЗБРОСА ПО ДНЯМ
        if (totalScanDays == 0) {
          // День 1: ±2 от первого скана
          int diff = variedAge - firstScanAge;
          if (diff > 2) variedAge = firstScanAge + 2;
          else if (diff < -2) variedAge = firstScanAge - 2;
        } else if (totalScanDays == 1) {
          // День 2: ±2 от Якоря 1
          int diff = variedAge - anchor1;
          if (diff > 2) variedAge = anchor1 + 2;
          else if (diff < -2) variedAge = anchor1 - 2;
        } else if (totalScanDays <= 3) {
          // День 3-4: ±1 от Якоря 1
          int diff = variedAge - anchor1;
          if (diff > 1) variedAge = anchor1 + 1;
          else if (diff < -1) variedAge = anchor1 - 1;
        } else {
          // День 5+: ±1 от Якоря 2
          int diff = variedAge - anchor2;
          if (diff > 1) variedAge = anchor2 + 1;
          else if (diff < -1) variedAge = anchor2 - 1;
        }
      }
      await prefs.setInt('last_interim_age', variedAge);
    }

    final variedResult = BioAgeResult(
      biologicalAge: variedAge,
      chronologicalAge: result.chronologicalAge,
      ageDifference: variedAge - result.chronologicalAge,
      riskLevel: result.riskLevel,
      recommendations: result.recommendations,
      disclaimer: result.disclaimer,
      smokes: result.smokes, bmi: result.bmi, activity: result.activity, sleepHours: result.sleepHours,
      calibratedFaceAge: result.calibratedFaceAge,
    );

    scansToday++;
    await prefs.setInt(scansTodayKey, scansToday);
    dailyScansStr.add(variedResult.biologicalAge.toString());
    await prefs.setStringList('daily_scans_$today', dailyScansStr);

    if (!mounted) { setState(() => _isCalculating = false); return; }

    // МАРШРУТИЗАЦИЯ
    if (scansToday < requiredScans) {
      // Промежуточный экран (Вариант Б)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => InterimResultScreen(result: variedResult, scanNumber: scansToday)),
      );
    } else {
      // ФИНАЛЬНЫЙ РЕЗУЛЬТАТ
      List<int> scans = dailyScansStr.map((e) => int.parse(e)).toList();
      double average = scans.reduce((a, b) => a + b) / scans.length;
      int finalAge = average.round();

      if (finalAge == _age) {
        finalAge += Random().nextBool() ? 1 : -1;
      }

      totalScanDays++;
      await prefs.setInt('total_scan_days', totalScanDays);

            // ЛОГИКА ЯКОРЕЙ И ИТОГОВ
      if (totalScanDays == 1) {
        await prefs.setInt('anchor_age_1', finalAge);
        
        // ✅ Сохраняем итог Дня 1 для расчёта Якоря 2
        List<String> finalsStr = prefs.getStringList('daily_final_ages') ?? [];
        finalsStr.add(finalAge.toString());
        await prefs.setStringList('daily_final_ages', finalsStr);
        
        debugPrint('⚓ [DAY 1] Якорь 1 установлен: $finalAge | Сохранено в daily_final_ages: $finalsStr');
      } else if (totalScanDays <= 3) {
        int diff = finalAge - anchor1;
        if (diff > 1) finalAge = anchor1 + 1;
        else if (diff < -1) finalAge = anchor1 - 1;
        
        // ✅ Сохраняем итог Дня 2-3 для расчёта Якоря 2
        List<String> finalsStr = prefs.getStringList('daily_final_ages') ?? [];
        finalsStr.add(finalAge.toString());
        await prefs.setStringList('daily_final_ages', finalsStr);
        
        debugPrint('🔒 [DAY $totalScanDays] Итог ограничен до: $finalAge (±1 от якоря $anchor1) | Сохранено: $finalsStr');
      } else if (totalScanDays == 4) {
        int diff = finalAge - anchor1;
        if (diff > 1) finalAge = anchor1 + 1;
        else if (diff < -1) finalAge = anchor1 - 1;
        
        // ✅ Сохраняем итог Дня 4 и рассчитываем Якорь 2
        List<String> finalsStr = prefs.getStringList('daily_final_ages') ?? [];
        finalsStr.add(finalAge.toString());
        await prefs.setStringList('daily_final_ages', finalsStr);
        
        List<int> finals = finalsStr.map((e) => int.parse(e)).toList();
        int sum = finals.reduce((a, b) => a + b);
        anchor2 = (sum / finals.length).round();
        await prefs.setInt('anchor_age_2', anchor2);
        debugPrint('⚓ [DAY 4] Якорь 2 установлен: $anchor2 (Среднее из $finals)');
      } else {
        // День 5+: строго Якорь 2
        finalAge = anchor2;
        debugPrint('🔒 [DAY $totalScanDays] Стабилизация: итог = Якорь 2 ($finalAge)');
      }

      await prefs.setInt('final_daily_age', finalAge);

      final finalResult = BioAgeResult(
        biologicalAge: finalAge,
        chronologicalAge: _age,
        ageDifference: finalAge - _age,
        riskLevel: variedResult.riskLevel,
        recommendations: variedResult.recommendations,
        disclaimer: variedResult.disclaimer,
        smokes: variedResult.smokes, bmi: variedResult.bmi, activity: variedResult.activity, sleepHours: variedResult.sleepHours,
        calibratedFaceAge: variedResult.calibratedFaceAge,
      );

      await prefs.setString('last_final_result_json', jsonEncode({
        'biologicalAge': finalAge, 'chronologicalAge': _age, 'ageDifference': finalAge - _age,
        'riskLevel': finalResult.riskLevel, 'recommendations': finalResult.recommendations, 'disclaimer': finalResult.disclaimer,
        'calibratedFaceAge': finalResult.calibratedFaceAge,
      }));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProcessingScreen(scanResults: scans, finalResult: finalResult)),
      );
    }
    
    if (mounted) setState(() => _isCalculating = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1115),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00D4AA))),
      );
    }

    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final padding = isTablet ? 40.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text('Анкета здоровья', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Основные данные', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              _buildStepper("Возраст (лет)", _age, 18, 80, 1, (val) { setState(() => _age = val); _saveData(); }, isTablet),
              
              Padding(
                padding: EdgeInsets.only(left: isTablet ? 40 : 20, bottom: 16, top: 8),
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 10),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.withValues(alpha: 0.4))),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Важно: указывайте реальный возраст. AI анализирует данные сканирования и определяет ваш биологический возраст относительно паспортного.',
                          style: TextStyle(color: Colors.orange, fontSize: 12, height: 1.3, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.only(left: isTablet ? 40 : 20, bottom: 16),
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(10), 
                    border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.4))
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.person_outline, color: Color(0xFF00D4AA), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Приложение рассчитано на одного пользователя. Если устройством пользуются несколько человек — результаты могут быть неточными.',
                          style: TextStyle(color: Color(0xFF00D4AA), fontSize: 12, height: 1.3, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Text("Пол", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildChoiceChip("Мужской", _gender == 'male', () { setState(() => _gender = 'male'); _saveData(); })),
                  const SizedBox(width: 12),
                  Expanded(child: _buildChoiceChip("Женский", _gender == 'female', () { setState(() => _gender = 'female'); _saveData(); })),
                ],
              ),
              const SizedBox(height: 32),

              const Text('Параметры тела', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              _buildStepper("Рост (см)", _height.round(), 100, 220, 1, (val) { setState(() => _height = val.toDouble()); _saveData(); }, isTablet),
              const SizedBox(height: 16),
              _buildStepper("Вес (кг)", _weight.round(), 40, 200, 1, (val) { setState(() => _weight = val.toDouble()); _saveData(); }, isTablet),
              const SizedBox(height: 32),

              const Text('Образ жизни', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              _buildSwitchTile("Курение", "Курите ли вы?", _smokes, (val) { setState(() => _smokes = val); _saveData(); }),
              const SizedBox(height: 16),
              _buildStepper("Сон (часов в сутки)", _sleepHours, 4, 12, 1, (val) { setState(() => _sleepHours = val); _saveData(); }, isTablet),
              const SizedBox(height: 16),

              const Text("Физическая активность", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _activity,
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                dropdownColor: const Color(0xFF1A1D24),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Низкая (сидячий образ жизни)')),
                  DropdownMenuItem(value: 'medium', child: Text('Средняя (прогулки, легкая активность)')),
                  DropdownMenuItem(value: 'high', child: Text('Высокая (регулярные тренировки)')),
                ],
                onChanged: (val) { 
                  if (val != null) { setState(() => _activity = val); _saveData(); }
                },
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isCalculating ? null : _calculateAndProceed,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4AA), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _isCalculating
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                      : const Text('Рассчитать биологический возраст', style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper(String label, int value, int min, int max, int step, ValueChanged<int> onChanged, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
              child: IconButton(icon: const Icon(Icons.remove, color: Color(0xFF00D4AA), size: 28), onPressed: value > min ? () => onChanged(value - step) : null),
            ),
            Expanded(
              child: Text('$value', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: isTablet ? 28 : 24, fontWeight: FontWeight.bold)),
            ),
            Container(
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
              child: IconButton(icon: const Icon(Icons.add, color: Color(0xFF00D4AA), size: 28), onPressed: value < max ? () => onChanged(value + step) : null),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D4AA) : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF00D4AA) : Colors.grey[800]!),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ]),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF0F1115), activeTrackColor: const Color(0xFF00D4AA), inactiveThumbColor: Colors.grey[600], inactiveTrackColor: Colors.grey[800]),
        ],
      ),
    );
  }
}