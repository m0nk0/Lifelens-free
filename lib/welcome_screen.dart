import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'camera_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  const WelcomeScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Логотип / Иконка
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4AA).withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: const Icon(Icons.biotech, color: Color(0xFF00D4AA), size: 56),
              ),
              const SizedBox(height: 32),
              const Text(
                'LifeLens',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Узнайте свой истинный биологический возраст за 2 минуты',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 20,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Шаги
              _buildStep(1, 'Сканирование лица', 'ИИ-камера анализирует микрорельеф кожи, тонус мышц и маркеры усталости'),
              _buildStep(2, 'Анкета здоровья', 'Учтём ваш образ жизни, качество сна, вес и уровень физической активности'),
              _buildStep(3, 'Прогноз и рекомендации', 'Рассчитаем биологический возраст, вероятность долголетия и дадим персональный план по снижению биологического возраста'),

              const SizedBox(height: 48),

              // Кнопка старта
              ElevatedButton.icon(
                onPressed: () {
                  final frontCamera = cameras.firstWhere(
                    (c) => c.lensDirection == CameraLensDirection.front,
                    orElse: () => cameras.first,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CameraScreen(camera: frontCamera)),
                  );
                },
                icon: const Icon(Icons.fingerprint, color: Colors.black, size: 28),
                label: const Text(
                  'Начать анализ',
                  style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4AA),
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),

              // Конфиденциальность
              const Text(
                '🔒 Все данные обрабатываются локально на вашем устройстве. Фото и анкеты не покидают телефон и не передаются третьим лицам.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                num.toString(),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 17,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}