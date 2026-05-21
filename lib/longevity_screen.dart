import 'package:flutter/material.dart';
import 'bio_age_calculator.dart';
import 'longevity_calculator.dart';

class LongevityScreen extends StatefulWidget {
  final BioAgeResult result;
  const LongevityScreen({super.key, required this.result});

  @override
  State<LongevityScreen> createState() => _LongevityScreenState();
}

class _LongevityScreenState extends State<LongevityScreen> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<int> _animAgeWithRec;
  late Animation<int> _animAgeCurrent;
  late Animation<double> _animBar;

  late final int expectedWithRec;
  late final int expectedCurrent;
  late List<Map<String, int>> _barData;

  @override
  void initState() {
    super.initState();
    
    expectedWithRec = LongevityCalculator.calculateExpectedLifespan(
      bioAge: widget.result.biologicalAge,
      smokes: false, bmi: 22.0, activity: 'high', sleepHours: 7,
      isOptimized: true,
    );
    
    expectedCurrent = LongevityCalculator.calculateExpectedLifespan(
      bioAge: widget.result.biologicalAge,
      smokes: widget.result.smokes,
      bmi: widget.result.bmi,
      activity: widget.result.activity,
      sleepHours: widget.result.sleepHours,
      isOptimized: false,
    );

    _barData = [
      {
        'label_val': 80,
        'rec': LongevityCalculator.calculateProbability(bioAge: widget.result.biologicalAge, targetAge: 80, smokes: false, bmi: 22.0, activity: 'high', sleepHours: 7, isOptimized: true),
        'cur': LongevityCalculator.calculateProbability(bioAge: widget.result.biologicalAge, targetAge: 80, smokes: widget.result.smokes, bmi: widget.result.bmi, activity: widget.result.activity, sleepHours: widget.result.sleepHours, isOptimized: false),
      },
      {
        'label_val': 90,
        'rec': LongevityCalculator.calculateProbability(bioAge: widget.result.biologicalAge, targetAge: 90, smokes: false, bmi: 22.0, activity: 'high', sleepHours: 7, isOptimized: true),
        'cur': LongevityCalculator.calculateProbability(bioAge: widget.result.biologicalAge, targetAge: 90, smokes: widget.result.smokes, bmi: widget.result.bmi, activity: widget.result.activity, sleepHours: widget.result.sleepHours, isOptimized: false),
      },
      {
        'label_val': 100,
        'rec': LongevityCalculator.calculateProbability(bioAge: widget.result.biologicalAge, targetAge: 100, smokes: false, bmi: 22.0, activity: 'high', sleepHours: 7, isOptimized: true),
        'cur': LongevityCalculator.calculateProbability(bioAge: widget.result.biologicalAge, targetAge: 100, smokes: widget.result.smokes, bmi: widget.result.bmi, activity: widget.result.activity, sleepHours: widget.result.sleepHours, isOptimized: false),
      },
    ];

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

    _animAgeWithRec = IntTween(begin: 0, end: expectedWithRec).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeOut)),
    );
    _animAgeCurrent = IntTween(begin: 0, end: expectedCurrent).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
    _animBar = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Прогноз долголетия'),
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF0F1115),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Ваш персональный прогноз',
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Биовозраст: ${widget.result.biologicalAge} лет',
              style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF00D4AA).withValues(alpha: 0.1), Colors.grey[900]!],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.favorite, color: Color(0xFF00D4AA), size: 32),
                  const SizedBox(height: 12),
                  const Text(
                    'Ожидаемая продолжительность жизни',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildAgeStat(animation: _animAgeWithRec, label: 'с выполнением рекомендаций', color: const Color(0xFF00D4AA), isMain: true),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey, height: 1),
                  const SizedBox(height: 16),
                  _buildAgeStat(animation: _animAgeCurrent, label: 'при текущем образе жизни', color: Colors.orange, isMain: false),
                  
                  if (expectedWithRec > expectedCurrent) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_upward, color: Color(0xFF00D4AA), size: 20),
                          const SizedBox(width: 6),
                          Text(
                            "+${expectedWithRec - expectedCurrent} лет потенциала",
                            style: const TextStyle(
                              color: Color(0xFF00D4AA),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Align(alignment: Alignment.centerLeft, child: Text('Вероятность дожить до...', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600))),
            const SizedBox(height: 20),
            _buildBarSection('80 лет', _barData[0]),
            const SizedBox(height: 16),
            _buildBarSection('90 лет', _barData[1]),
            const SizedBox(height: 16),
            _buildBarSection('100 лет', _barData[2]),
            
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[700]!)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(Icons.info_outline, color: Color(0xFF00D4AA), size: 24), SizedBox(width: 12), Text('Почему такая разница?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
                  SizedBox(height: 12),
                  Text('Эпидемиологические исследования показывают, что совокупность вредных привычек (курение, лишний вес, низкая активность) может сократить жизнь на 10–12 лет.', style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
                  SizedBox(height: 12),
                  Text('Зелёный прогноз показывает, как изменится ситуация, если устранить эти факторы. Это реальный, достижимый потенциал.', style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.4, fontStyle: FontStyle.italic)),
                ],
              ),
            ),

            // 🆕 НОВОЕ: Пояснение про условную продолжительность жизни
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(Icons.timeline, color: Color(0xFF00D4AA), size: 20), SizedBox(width: 10), Text('Как работает прогноз?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
                  SizedBox(height: 8),
                  Text(
                    '💡 Статистический прогноз долголетия естественным образом растёт с возрастом. '
                    'Это не парадокс — актуарные модели учитывают, что вы уже успешно прошли через риски молодости и среднего возраста. '
                    'Цифра показывает не «сколько осталось», а «до какого возраста вы вероятнее всего доживёте при текущих условиях».',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                label: const Text('Вернуться к результатам', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4AA), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeStat({required Animation<int> animation, required String label, required Color color, bool isMain = false}) {
    return AnimatedBuilder(animation: animation, builder: (ctx, _) {
      return Column(children: [
        Text('${animation.value} лет', style: TextStyle(color: color, fontSize: isMain ? 44 : 36, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: isMain ? 16 : 14)),
      ]);
    });
  }

  Widget _buildBarSection(String label, Map<String, int> data) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      AnimatedBuilder(animation: _animBar, builder: (ctx, _) {
        final fraction = data['rec']! / 100.0 * _animBar.value;
        return _buildProgressBar(fraction, 'с рекомендациями', const Color(0xFF00D4AA));
      }),
      const SizedBox(height: 6),
      AnimatedBuilder(animation: _animBar, builder: (ctx, _) {
        final fraction = data['cur']! / 100.0 * _animBar.value;
        return _buildProgressBar(fraction, 'текущий образ жизни', Colors.orange, isSecondary: true);
      }),
    ]);
  }

  Widget _buildProgressBar(double widthFraction, String label, Color color, {bool isSecondary = false}) {
    return Row(children: [
      Expanded(
        child: SizedBox(
          height: 14,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(color: Colors.grey[800]),
              AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widthFraction.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isSecondary ? 0.8 : 1.0),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 12),
      SizedBox(width: 80, child: Text('${(widthFraction * 100).round()}%', textAlign: TextAlign.end, style: TextStyle(color: isSecondary ? Colors.grey : Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
    ]);
  }
}