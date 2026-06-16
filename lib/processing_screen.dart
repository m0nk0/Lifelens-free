import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'result_screen.dart';
import 'bio_age_calculator.dart';

class ProcessingScreen extends StatefulWidget {
  final List<int> scanResults;
  final BioAgeResult finalResult;

  const ProcessingScreen({
    super.key, 
    required this.scanResults, 
    required this.finalResult,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStep = 0;
  
  final List<String> _steps = const [
    'Агрегация данных: расчет среднего значения и оценка статистической погрешности...',
    'Нейросетевая калибровка: применение поправочных коэффициентов возрастной модели...',
    'Кросс-валидация: корректировка базового возраста с учетом пола и Индекса Массы Тела (ИМТ)...',
    'Интеграция маркеров: учет качества сна, уровня стресса и физической активности...',
    'Финальная верификация: исключение системной погрешности совпадения с паспортными данными...',
    'Расчет завершен. Формирование итогового отчета...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _runAnimationSequence();
  }

  Future<void> _runAnimationSequence() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400)); // Чуть замедлили для читаемости
      if (!mounted) return;
      setState(() => _currentStep = i);
      await _controller.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 600)); // Пауза на чтение строки
    }
    
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: widget.finalResult, isFinalResult: true),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: Stack(
        children: [
          // 🧠 Фоновое изображение мозга (ТЕПЕРЬ ПОЛУПРОЗРАЧНЫЙ ФОН, БЕЗ ЦВЕТОВОГО ФИЛЬТРА)
          Positioned.fill(
            child: Opacity(
              opacity: 0.1, // ✅ Делаем мозг едва заметным фоном
              child: Image.asset(
                'assets/image/brain.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔄 Прелоадер "AI"
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                            strokeWidth: 3,
                          ),
                        ),
                        const Text(
                          'AI',
                          style: TextStyle(
                            color: Color(0xFF00D4AA),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // 📊 Результаты сканов
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.scanResults.map((age) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '$age',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // 📝 Последовательная анимация текста (✅ КРУПНЫЙ И БИРЮЗОВЫЙ)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _currentStep + 1,
                      itemBuilder: (context, index) {
                        return FadeTransition(
                          opacity: _controller,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _controller,
                              curve: Curves.easeOut,
                            )),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF00D4AA), size: 22),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _steps[index],
                                      style: const TextStyle(
                                        color: Color(0xFF00D4AA), // ✅ Бирюзовый цвет
                                        fontSize: 18,             // ✅ Крупный шрифт
                                        height: 1.4,
                                        fontWeight: FontWeight.w600, // ✅ Жирнее
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}