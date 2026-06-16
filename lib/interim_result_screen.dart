import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bio_age_calculator.dart';

class InterimResultScreen extends StatelessWidget {
  final BioAgeResult result;
  final int scanNumber; // 1 или 2

  const InterimResultScreen({
    super.key, 
    required this.result, 
    required this.scanNumber,
  });

  // ✅ Цвет для надписи (такой же как в result_screen.dart)
  Color _getDifferenceColor() {
    final diff = result.ageDifference.abs();
    if (diff <= 2) {
      return const Color(0xFF00D4AA); // Бирюзовый для 0-2 года
    } else {
      return Colors.redAccent; // Красный для 3+ лет
    }
  }

  // ✅ Текст для надписи (такой же как в result_screen.dart)
  String _getDifferenceText() {
    final diff = result.ageDifference;
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

  String _getYearWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'год';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) return 'года';
    return 'лет';
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _getDifferenceColor();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text('Замер $scanNumber из 3'),
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              Text(
                '${result.biologicalAge} лет',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                ),
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
              
              const SizedBox(height: 40),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.analytics_outlined, color: Color(0xFF00D4AA), size: 32),
                    const SizedBox(height: 12),
                    Text(
                      scanNumber == 1 
                          ? 'Сканирование 1 из 3\n\nСделайте еще 2 замера сегодня для финального усреднения и максимальной точности.'
                          : 'Сканирование 2 из 3\n\nОтлично! Еще 1 замер для финального расчета.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    // Просто возвращаемся на экран камеры
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.camera_alt, color: Colors.black),
                  label: Text(
                    scanNumber == 1 ? 'Сделать замер 2' : 'Сделать финальный замер 3',
                    style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}