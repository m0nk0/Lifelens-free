import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'bio_age_calculator.dart';
import 'history_manager.dart';
import 'longevity_screen.dart';
import 'methodology_screen.dart';
import 'recommendations_screen.dart';
import 'tracker_screen.dart';

class ResultScreen extends StatefulWidget {
  final BioAgeResult result;
  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _saveResult();
  }

  // 🔍 Проверяем: прошло ли 14+ дней с последнего сохранения?
  Future<bool> _shouldSaveThisInterval() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSave = prefs.getString('last_bio_save');
    if (lastSave == null) return true;
    
    final lastDate = DateTime.parse(lastSave);
    final now = DateTime.now();
    final diff = now.difference(lastDate).inDays;
    
    return diff >= 14; // ✅ Интервал: не чаще 1 раза в 2 недели
  }

  // 🎁 Проверяем лояльность: трекер ≥ 80% за последние 28 дней
  Future<Map<String, dynamic>> _checkLoyaltyBonus() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    int checkedDays = 0;
    int totalDays = 0;
    
    for (int i = 0; i < 28; i++) {
      final date = now.subtract(Duration(days: i));
      final key = 'tracker_${date.toIso8601String().split('T')[0]}';
      final data = prefs.getString(key);
      if (data != null) {
        totalDays++;
        final decoded = jsonDecode(data);
        if (decoded.values.any((v) => v == true)) {
          checkedDays++;
        }
      }
    }
    
    final hasBonus = totalDays >= 20 && (checkedDays / totalDays) >= 0.8;
    
    return {
      'hasBonus': hasBonus,
      'consistency': totalDays > 0 ? (checkedDays / totalDays) : 0,
    };
  }

  Future<void> _saveResult() async {
    final shouldSave = await _shouldSaveThisInterval();
    if (!shouldSave) return;
    
    final loyalty = await _checkLoyaltyBonus();
    
    await HistoryManager.save(ScanHistory(
      date: DateTime.now(),
      bioAge: widget.result.biologicalAge,
      chronoAge: widget.result.chronologicalAge,
      riskLevel: widget.result.riskLevel,
      hasLoyaltyBonus: loyalty['hasBonus'],
    ));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_bio_save', DateTime.now().toIso8601String());
  }

  String _getDifferenceText() {
    final diff = widget.result.ageDifference;
    if (diff < 0) {
      return 'На ${diff.abs()} ${_getYearWord(diff.abs())} моложе';
    }
    if (diff == 0) {
      return 'Биологический возраст соответствует хронологическому';
    }
    return 'На $diff ${_getYearWord(diff)} старше';
  }

  String _getYearWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'год';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) return 'года';
    return 'лет';
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = widget.result.ageDifference <= 0
        ? const Color(0xFF00D4AA)
        : (widget.result.ageDifference <= 3 ? Colors.orange : Colors.redAccent);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат'),
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0F1115),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            RepaintBoundary(
              key: _shareKey,
              child: Container(
                width: double.infinity,
                color: const Color(0xFF0F1115),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.health_and_safety, color: Color(0xFF00D4AA), size: 32),
                        const SizedBox(width: 10),
                        const Text(
                          'LifeLens AI',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Ваш биологический возраст\nс учетом всех факторов',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    FutureBuilder<Map<String, dynamic>>(
                      future: _checkLoyaltyBonus(),
                      builder: (context, snapshot) {
                        final loyalty = snapshot.data ?? {'hasBonus': false};
                        final displayAge = loyalty['hasBonus'] 
                            ? widget.result.biologicalAge - 1
                            : widget.result.biologicalAge;
                        
                        return Text(
                          '$displayAge лет',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 8),
                    Text(
                      _getDifferenceText(),
                      style: TextStyle(
                        color: diffColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      widget.result.riskLevel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...widget.result.recommendations.take(4).map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          '• $r',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.result.disclaimer,
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      ' ${DateTime.now().toString().substring(0, 10)} | lifelens.app',
                      style: TextStyle(color: Colors.grey[700], fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.grey, height: 1),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                  const Icon(Icons.timeline, color: Color(0xFF00D4AA), size: 28),
                  const SizedBox(height: 12),
                  const Text(
                    '🔮 Хотите узнать ожидаемую продолжительность жизни?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Персональный прогноз с учётом ваших привычек и рекомендаций',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LongevityScreen(result: widget.result),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, color: Colors.black),
                      label: const Text(
                        'Посмотреть прогноз',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4AA),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecommendationsScreen(
                      result: widget.result,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.lightbulb_outline, color: Colors.black),
              label: const Text(
                '💡 Получить план продления жизни',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MethodologyScreen()),
                );
              },
              icon: const Icon(Icons.science_outlined, color: Color(0xFF00D4AA)),
              label: const Text(
                'Как это работает?',
                style: TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00D4AA)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Вернуться к камере',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}