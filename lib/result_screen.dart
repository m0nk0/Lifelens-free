import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/rendering.dart';
import 'bio_age_calculator.dart';
import 'methodology_screen.dart';

class ResultScreen extends StatefulWidget {
  final BioAgeResult result;
  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _shareKey = GlobalKey();
  int _displayAge = 0;

  @override
  void initState() {
    super.initState();
    _applyLiveModelAdjustment();
  }

  Future<void> _applyLiveModelAdjustment() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 🎯 КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: читаем базовый возраст ПЕРВОГО скана
    final baselineAge = prefs.getInt('baseline_age');
    final initialDirection = prefs.getString('initial_direction');
    
    int finalAge = widget.result.biologicalAge;
    final chronoAge = widget.result.chronologicalAge;
    
    String currentDirection;
    if (finalAge <= chronoAge - 3) {
      currentDirection = 'younger';
    } else if (finalAge >= chronoAge + 3) {
      currentDirection = 'older';
    } else {
      currentDirection = 'same';
    }
    
    debugPrint('📊 [DEBUG] Модель выдала: $finalAge | Паспорт: $chronoAge | Направление: $currentDirection');

    if (baselineAge != null && initialDirection != null) {
      // === ЭТО НЕ ПЕРВЫЙ СКРИН ===
      
      // 1. Проверяем запрещенный переход сырых данных
      if (initialDirection == 'younger' && currentDirection == 'older') {
        debugPrint('🚫 [DEBUG] Модель пытается стать "старше", но база была "моложе". Ограничиваем.');
      } else if (initialDirection == 'older' && currentDirection == 'younger') {
        debugPrint('🚫 [DEBUG] Модель пытается стать "моложе", но база была "старше". Ограничиваем.');
      }

      // 2. Применяем органичную вариативность ОТНОСИТЕЛЬНО БАЗЫ (baselineAge)
      int roll = Random().nextInt(100);
      int change = 0;

      if (roll < 50) {
        change = 0; // 50% шанс: Стабильность
      } else if (roll < 80) {
        change = Random().nextBool() ? 1 : -1; // 30% шанс: колебание на 1 год
      } else {
        change = Random().nextBool() ? 2 : -2; // 20% шанс: колебание на 2 года
      }

      int proposedAge = baselineAge + change;
      debugPrint('🎲 [DEBUG] Бросок: $roll | Сдвиг от базы: $change | База: $baselineAge | Предлагаемый: $proposedAge');

      // 3. Финальная проверка границ относительно паспортного возраста
      if (initialDirection == 'younger' && proposedAge > chronoAge) {
        finalAge = chronoAge; // ⛔ Не даем стать "старше"
        debugPrint('⚠️ [DEBUG] Попытка выйти за границу! Обрезано до "соответствует": $finalAge');
      } else if (initialDirection == 'older' && proposedAge < chronoAge) {
        finalAge = chronoAge; // ⛔ Не даем стать "моложе"
        debugPrint('⚠️ [DEBUG] Попытка выйти за границу! Обрезано до "соответствует": $finalAge');
      } else if (initialDirection == 'same') {
        // Если начали с "соответствует", держим в коридоре ±3 года от паспорта
        finalAge = proposedAge.clamp(chronoAge - 3, chronoAge + 3);
        debugPrint('✅ [DEBUG] Направление "same". Итог после clamp: $finalAge');
      } else {
        finalAge = proposedAge;
        debugPrint('✅ [DEBUG] Направление сохранено. Итоговый возраст: $finalAge');
      }
      
    } else {
      // === ПЕРВЫЙ СКРИН ===
      await prefs.setString('initial_direction', currentDirection);
      await prefs.setInt('baseline_age', finalAge); // 🎯 ЗАПОМИНАЕМ БАЗУ НАВСЕГДА
      debugPrint('🆕 [DEBUG] ПЕРВЫЙ СКРИН! Запомнили БАЗУ: $finalAge, Направление: $currentDirection');
    }
    
    // Сохраняем дату скана (базу не перезаписываем!)
    await prefs.setString('last_scan_date', DateTime.now().toIso8601String());
    
    setState(() {
      _displayAge = finalAge;
    });
  }

  Future<void> _shareResult() async {
    try {
      HapticFeedback.lightImpact();
      RenderRepaintBoundary boundary = _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/lifelens_result.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Мой биологический возраст: $_displayAge лет! Узнай свой в LifeLens AI 🧬',
        );
      }
    } catch (e) {
      debugPrint('Ошибка шаринга: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось создать изображение')),
      );
    }
  }

  String _getDifferenceText() {
    final diff = _displayAge - widget.result.chronologicalAge;
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
    final diffColor = (_displayAge - widget.result.chronologicalAge) <= 0
        ? const Color(0xFF00D4AA)
        : ((_displayAge - widget.result.chronologicalAge) <= 3 ? Colors.orange : Colors.redAccent);

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
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F1115), Color(0xFF1A1D24), Color(0xFF0F1115)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.3), width: 2),
                  boxShadow: [BoxShadow(color: const Color(0xFF00D4AA).withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF00D4AA).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.health_and_safety, color: Color(0xFF00D4AA), size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Text('LifeLens AI', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ],
                        ),
                        Text('📅 ${DateTime.now().toString().substring(0, 10)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('ВАШ БИОЛОГИЧЕСКИЙ ВОЗРАСТ', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 2.0)),
                    const SizedBox(height: 20),
                    Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF00D4AA), Color(0xFF00FFE0)]),
                        boxShadow: [BoxShadow(color: const Color(0xFF00D4AA).withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5)],
                      ),
                      alignment: Alignment.center,
                      child: Text('$_displayAge', style: const TextStyle(color: Color(0xFF0F1115), fontSize: 72, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    const Text('биологических лет', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(30), border: Border.all(color: diffColor.withValues(alpha: 0.5))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_displayAge < widget.result.chronologicalAge ? Icons.trending_down : Icons.trending_up, color: diffColor, size: 20),
                          const SizedBox(width: 8),
                          Text(_getDifferenceText(), style: TextStyle(color: diffColor, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Паспортный возраст', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              Text('${widget.result.chronologicalAge} лет', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(value: (widget.result.chronologicalAge / 100).clamp(0.0, 1.0), backgroundColor: Colors.grey[800], valueColor: const AlwaysStoppedAnimation<Color>(Colors.white54), minHeight: 8),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Биологический возраст', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              Text('$_displayAge лет', style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(value: (_displayAge / 100).clamp(0.0, 1.0), backgroundColor: Colors.grey[800], valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)), minHeight: 8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                      child: Text(widget.result.riskLevel, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 20),
                    ...widget.result.recommendations.take(2).map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Color(0xFF00D4AA), fontSize: 16, fontWeight: FontWeight.bold)),
                            Expanded(child: Text(r, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFF00D4AA).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link, color: Color(0xFF00D4AA), size: 16),
                          SizedBox(width: 8),
                          Text('lifelens.app', style: TextStyle(color: Color(0xFF00D4AA), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _shareResult,
              icon: const Icon(Icons.share, color: Colors.black),
              label: const Text('Поделиться результатом', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4AA), padding: const EdgeInsets.symmetric(vertical: 14), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MethodologyScreen())),
              icon: const Icon(Icons.science_outlined, color: Color(0xFF00D4AA)),
              label: const Text('Как это работает?', style: TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF00D4AA)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              label: const Text('Новое сканирование', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}