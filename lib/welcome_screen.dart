import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  const WelcomeScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // 📐 Четкое разделение: Телефон или Планшет
    final isTablet = size.width > 600;
    
    // Настройка размеров в зависимости от устройства
    final titleSize = isTablet ? 48.0 : 28.0;
    final subtitleSize = isTablet ? 20.0 : 14.0;
    final stepTitleSize = isTablet ? 24.0 : 16.0;
    final stepDescSize = isTablet ? 16.0 : 12.0;
    final buttonSize = isTablet ? 20.0 : 16.0;
    final iconSize = isTablet ? 64.0 : 40.0;
    
    final padding = isTablet ? 40.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // 🟢 Иконка
                Container(
                  width: double.infinity,
                  height: isTablet ? 120.0 : 80.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4AA).withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.biotech,
                    size: iconSize,
                    color: const Color(0xFF00D4AA),
                  ),
                ),

                SizedBox(height: isTablet ? 30 : 20),

                //  Заголовок
                Text(
                  'LifeLens',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                // 🏷️ Бейдж "Бесплатная версия"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00D4AA).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'FREE VERSION',
                    style: TextStyle(
                      color: Color(0xFF00D4AA),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 📝 Подзаголовок
                Text(
                  'Узнайте свой истинный\nбиологический возраст за 2 минуты',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: subtitleSize,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: isTablet ? 40 : 28),

                // ✅ Шаг 1 (доступен)
                _buildStep(
                  '1', 
                  'Сканирование лица', 
                  'ИИ-камера анализирует микрорельеф кожи, тонус мышц и маркеры усталости', 
                  stepTitleSize, 
                  stepDescSize, 
                  isTablet,
                  isLocked: false,
                ),
                SizedBox(height: isTablet ? 20 : 14),

                // ✅ Шаг 2 (доступен)
                _buildStep(
                  '2', 
                  'Анкета здоровья', 
                  'Учтём ваш образ жизни, качество сна, вес и уровень физической активности', 
                  stepTitleSize, 
                  stepDescSize, 
                  isTablet,
                  isLocked: false,
                ),
                SizedBox(height: isTablet ? 20 : 14),

                // 🔒 Шаг 3 (Главный крючок - Долголетие)
                _buildStep(
                  '3', 
                  'Прогноз долголетия', 
                  'Узнайте вашу ожидаемую продолжительность жизни с точностью до года', 
                  stepTitleSize, 
                  stepDescSize, 
                  isTablet,
                  isLocked: true,
                ),
                SizedBox(height: isTablet ? 20 : 14),

                // 🔒 Шаг 4 (Главный крючок - Омоложение)
                _buildStep(
                  '4', 
                  'План продления жизни', 
                  'Персональные рекомендации от ИИ: как вернуть биологическую молодость', 
                  stepTitleSize, 
                  stepDescSize, 
                  isTablet,
                  isLocked: true,
                ),

                SizedBox(height: isTablet ? 40 : 28),

                // 🚀 Кнопка "Начать анализ"
                SizedBox(
                  width: double.infinity,
                  height: isTablet ? 65.0 : 50.0,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final selectedCamera = cameras.firstWhere(
                        (c) => c.lensDirection == CameraLensDirection.front,
                        orElse: () => cameras.first,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CameraScreen(camera: selectedCamera)),
                      );
                    },
                    icon: Icon(Icons.arrow_forward, color: Colors.black, size: isTablet ? 24.0 : 18.0),
                    label: Text(
                      'Начать анализ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: buttonSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String num, String title, String desc, double titleSize, double descSize, bool isTablet, {bool isLocked = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isTablet ? 50.0 : 36.0,
          height: isTablet ? 50.0 : 36.0,
          decoration: BoxDecoration(
            color: isLocked ? Colors.grey[800] : const Color(0xFF00D4AA),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: isLocked
              ? Icon(Icons.lock_outline, color: Colors.grey[500], size: isTablet ? 24.0 : 16.0)
              : Text(
                  num,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: isTablet ? 24.0 : 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        SizedBox(width: isTablet ? 20 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isLocked ? Colors.grey[600] : Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isLocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'СКОРО',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: TextStyle(
                  color: isLocked ? Colors.grey[700] : Colors.grey[500],
                  fontSize: descSize,
                  height: 1.3,
                ),
              ),
              if (isLocked)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '🔒 В следующем обновлении',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: descSize * 0.9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}