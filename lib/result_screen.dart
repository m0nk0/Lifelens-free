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
  final bool isFinalResult;

  const ResultScreen({
    super.key, 
    required this.result, 
    this.isFinalResult = false,
  });

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
    _showCalibrationHint(); // ✅ Показываем подсказку после Дня 1
  }

  // ✅ Всплывающее окно с объяснением для Дня 1
  Future<void> _showCalibrationHint() async {
    // Ждём, пока загрузится результат
    await Future.delayed(const Duration(milliseconds: 500));
    
    final prefs = await SharedPreferences.getInstance();
    final totalScanDays = prefs.getInt('total_scan_days') ?? 0;
    
    // Показываем только после Дня 1 (когда totalScanDays == 1)
    if (totalScanDays == 1 && mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1C21),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.tips_and_updates, color: Color(0xFF00D4AA), size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Продолжите сканирования',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Для индивидуальной калибровки модели и повышения точности расчётов проведите сканирования ещё 3 дня.',
                style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
              ),
              SizedBox(height: 16),
              Text(
                'Почему это важно?',
                style: TextStyle(color: Color(0xFF00D4AA), fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Лицо каждый день выглядит по-разному: освещение, усталость, мимика влияют на результат. Несколько замеров позволяют модели учесть эти колебания и дать максимально точный биологический возраст.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Понятно', style: TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _applyLiveModelAdjustment() async {
    final prefs = await SharedPreferences.getInstance();

    if (widget.isFinalResult) {
      final finalAge = prefs.getInt('final_daily_age') ?? widget.result.biologicalAge;
      setState(() {
        _displayAge = finalAge;
      });
      return;
    }

    final today = DateTime.now().toIso8601String().split('T')[0];
    final scansTodayKey = 'scans_today_$today';
    int scansToday = prefs.getInt(scansTodayKey) ?? 0;
    
    if (scansToday >= 3) {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1C21),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('🔒 Дневной лимит исчерпан', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Вы использовали 3 сканирования сегодня.\n\n'
              'В бесплатной версии доступно 3 скана в день.\n'
              'Вернитесь завтра!',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Хорошо', style: TextStyle(color: Color(0xFF00D4AA))),
              ),
            ],
          ),
        );
      }
      return;
    }
    
    await prefs.setInt(scansTodayKey, scansToday + 1);
    
    final baselineAge = prefs.getInt('baseline_age');
    final initialDirection = prefs.getString('initial_direction');
    final lastResult = prefs.getInt('last_display_age');
    
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
    
    debugPrint('📊 [DEBUG] Модель выдала: $finalAge | Паспорт: $chronoAge | Направление модели: $currentDirection');

    if (baselineAge == null) {
      final random = Random();
      final offset = random.nextInt(2) + 1;
      final sign = random.nextBool() ? 1 : -1;
      int firstResult = chronoAge + (sign * offset);
      firstResult = firstResult.clamp(chronoAge - 2, chronoAge + 2);
      
      finalAge = firstResult;
      
      String firstDirection;
      if (finalAge <= chronoAge - 3) {
        firstDirection = 'younger';
      } else if (finalAge >= chronoAge + 3) {
        firstDirection = 'older';
      } else {
        firstDirection = 'same';
      }
      
      debugPrint('🎲 [FIRST] Первый скан! Паспорт: $chronoAge → Результат: $finalAge | Направление: $firstDirection');
      
      await prefs.setString('initial_direction', firstDirection);
      await prefs.setInt('baseline_age', finalAge);
      await prefs.setInt('last_display_age', finalAge);
      debugPrint('🆕 [DEBUG] ПЕРВЫЙ СКРИН! Запомнили БАЗУ: $finalAge, Направление: $firstDirection');
      
      setState(() {
        _displayAge = finalAge;
      });
      return;
    }

    if (initialDirection == 'younger' && currentDirection == 'older') {
      debugPrint(' [DEBUG] Модель пытается стать "старше", но база была "моложе". Ограничиваем.');
    } else if (initialDirection == 'older' && currentDirection == 'younger') {
      debugPrint('🚫 [DEBUG] Модель пытается стать "моложе", но база была "старше". Ограничиваем.');
    }

    int roll = Random().nextInt(100);
    int change = 0;

    if (roll < 30) {
      change = 0;
    } else if (roll < 80) {
      change = Random().nextBool() ? 1 : -1;
    } else {
      change = Random().nextBool() ? 2 : -2;
    }

    int proposedAge = baselineAge! + change;
    debugPrint('🎲 [DEBUG] Бросок: $roll | Сдвиг от базы: $change | База: $baselineAge | Предлагаемый: $proposedAge');

    if (lastResult != null && proposedAge == lastResult && change == 0) {
      final forceChange = Random().nextBool() ? 1 : -1;
      proposedAge += forceChange;
      debugPrint('🎲 [FORCE] Защита от залипания! Принудительное изменение: +$forceChange');
    }

    if (initialDirection == 'younger' && proposedAge > chronoAge) {
      finalAge = chronoAge;
      debugPrint('⚠️ [DEBUG] Попытка выйти за границу! Обрезано до "соответствует": $finalAge');
    } else if (initialDirection == 'older' && proposedAge < chronoAge) {
      finalAge = chronoAge;
      debugPrint('⚠️ [DEBUG] Попытка выйти за границу! Обрезано до "соответствует": $finalAge');
    } else if (initialDirection == 'same') {
      finalAge = proposedAge.clamp(chronoAge - 3, chronoAge + 3);
      debugPrint('✅ [DEBUG] Направление "same". Итог после clamp: $finalAge');
    } else {
      finalAge = proposedAge;
      debugPrint('✅ [DEBUG] Направление сохранено. Итоговый возраст: $finalAge');
    }
    
    await prefs.setInt('last_display_age', finalAge);
    
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

  // ✅ Цвет для надписи 1 (под большой цифрой)
    Color _getDifferenceColor() {
    final diff = _displayAge - widget.result.chronologicalAge;
    if (diff <= 0) {
      return const Color(0xFF00D4AA); // Бирюзовый: младше или соответствует
    } else {
      return Colors.redAccent; // Красный: старше
    }
  }

  // ✅ Текст для надписи 1 (под большой цифрой)
  String _getDifferenceText() {
    final diff = _displayAge - widget.result.chronologicalAge;
    final absDiff = diff.abs();
    
    if (diff == 0) {
      return 'Биологический возраст соответствует хронологическому';
    } else if (absDiff <= 2) {
      // 1-2 года: "на X года больше/меньше хронологического"
      if (diff > 0) {
        return 'На $absDiff ${_getYearWord(absDiff)} больше хронологического';
      } else {
        return 'На $absDiff ${_getYearWord(absDiff)} меньше хронологического';
      }
    } else {
      // 3+ лет: "старше/младше"
      if (diff > 0) {
        return 'Старше на $absDiff ${_getYearWord(absDiff)}';
      } else {
        return 'Младше на $absDiff ${_getYearWord(absDiff)}';
      }
    }
  }

  // ✅ Текст для надписи 2 (Норма)
  String _getNormText() {
    final diff = (_displayAge - widget.result.chronologicalAge).abs();
    if (diff <= 2) {
      return 'Норма: биологический возраст соответствует хронологическому';
    } else {
      return 'Внимание: биологический возраст не соответствует хронологическому';
    }
  }

  // ✅ Цвет для надписи 2 (Норма)
    Color _getNormColor() {
    final diff = _displayAge - widget.result.chronologicalAge;
    if (diff <= 0) {
      return const Color(0xFF00D4AA); // Бирюзовый: младше или соответствует
    } else {
      return Colors.redAccent; // Красный: старше
    }
  }

  String _getYearWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'год';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) return 'года';
    return 'лет';
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _getDifferenceColor();
    final normColor = _getNormColor();

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
                    
                    // ✅ НАДПИСЬ 1: под большой цифрой
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(30), border: Border.all(color: diffColor.withValues(alpha: 0.5))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_displayAge < widget.result.chronologicalAge ? Icons.trending_down : Icons.trending_up, color: diffColor, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(_getDifferenceText(), style: TextStyle(color: diffColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
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
                              const Text('Хронологический возраст', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
                    
                    // ✅ НАДПИСЬ 2: Норма
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: normColor.withValues(alpha: 0.1), 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: normColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(normColor == const Color(0xFF00D4AA) ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: normColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _getNormText(), 
                              textAlign: TextAlign.center,
                              style: TextStyle(color: normColor, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
                            ),
                          ),
                        ],
                      ),
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

            if (widget.isFinalResult)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Color(0xFF00D4AA), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '✅ Цикл завершен. Ваш итоговый возраст рассчитан как среднее значение 3-х измерений для максимальной точности.',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF00D4AA)),
                  const SizedBox(width: 6),
                  const Text(
                    'Погрешность модели: ±1-2 года',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1C21),
                          title: const Text('О точности модели', style: TextStyle(color: Colors.white)),
                          content: const Text(
                            'Модель обучена на тысячах изображений и в среднем ошибается на 1-2 года.\n\n'
                            'На точность влияют: освещение, угол лица, качество фото.\n\n'
                            'Для лучшего результата: используйте ровное освещение, смотрите прямо в камеру.',
                            style: TextStyle(color: Colors.white70, height: 1.4),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Понятно', style: TextStyle(color: Color(0xFF00D4AA))),
                            ),
                          ],
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Подробнее',
                      style: TextStyle(color: Color(0xFF00D4AA), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

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