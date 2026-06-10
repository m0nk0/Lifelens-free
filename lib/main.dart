import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ ДОБАВЛЕНО: для блокировки поворота
import 'splash_screen.dart'; // ✅ Импортируем экран заставки

// 🚀 Точка входа в приложение
void main() async {
  // Обязательная инициализация Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Блокируем поворот экрана — только портретная ориентация
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Запускаем приложение
  runApp(const LifeLensApp());
}

class LifeLensApp extends StatelessWidget {
  const LifeLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeLens',
      debugShowCheckedModeBanner: false,
      
      // 🎨 Твоя тема (тёмный фон + бирюзовый акцент)
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF00D4AA),
        scaffoldBackgroundColor: const Color(0xFF0F1115),
      ),

      // 🖼️ Главный экран — теперь это Splash Screen
      home: const SplashScreen(), 
    );
  }
}