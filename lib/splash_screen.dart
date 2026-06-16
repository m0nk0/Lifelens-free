import 'package:flutter/material.dart';
import 'dart:async';
import 'welcome_screen.dart';
import 'package:camera/camera.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeLogo;
  late Animation<double> _scaleLogo;
  late Animation<double> _fadeText;
  late Animation<double> _fadeSubtitle;
  late Animation<Offset> _slideSubtitle;
  late Animation<double> _fadeSlogan;
  late Animation<double> _pulseProgress;

  @override
  void initState() {
    super.initState();

    // ⏱️ Длительность 5 секунд
    _controller = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    // 🖼️ Логотип (появление 0-2с)
    _fadeLogo = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _scaleLogo = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // 📛 Название (появление 1.5с - 3с)
    _fadeText = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    // 🔤 Подзаголовок (появление 2.5с - 3.5с)
    _fadeSubtitle = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.7, curve: Curves.easeOut),
      ),
    );
    _slideSubtitle = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // 💬 Слоган (появление 3с - 4с)
    _fadeSlogan = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    // 💓 Пульсация прогресс-бара
    _pulseProgress = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // 🔄 Переход через 5 секунд
    Timer(const Duration(milliseconds: 5000), () async {
      if (mounted) {
        try {
          final cameras = await availableCameras();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => WelcomeScreen(cameras: cameras),
            ),
          );
        } catch (e) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => WelcomeScreen(cameras: [])),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115), // ✅ Тёмный фон
      body: Center(
        child: FadeTransition(
          opacity: _fadeLogo,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🖼️ Логотип
              ScaleTransition(
                scale: _scaleLogo,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4AA).withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/image/splash_logo.png',
                    width: 320,
                    height: 320,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 📛 Название
              FadeTransition(
                opacity: _fadeText,
                child: const Text(
                  'LifeLens AI',
                  style: TextStyle(
                    color: Color(0xFF00D4AA),
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4.0,
                    height: 1.1,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔤 Подзаголовок
              FadeTransition(
                opacity: _fadeSubtitle,
                child: SlideTransition(
                  position: _slideSubtitle,
                  child: const Text(
                    'Биологический сканер',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 24,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 💬 Слоган (✅ ИСПРАВЛЕНО: более мягкая формулировка)
              FadeTransition(
                opacity: _fadeSlogan,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF00D4AA).withOpacity(0.4),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Узнай свой\nбиологический возраст',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF00D4AA),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🏷️ Бейдж "БЕСПЛАТНАЯ ВЕРСИЯ" (✅ НОВЫЙ ЭЛЕМЕНТ)
              FadeTransition(
                opacity: _fadeSlogan,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00D4AA).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'БЕСПЛАТНАЯ ВЕРСИЯ',
                    style: TextStyle(
                      color: Color(0xFF00D4AA),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // 💓 Красивый прогресс-бар (пульсирующий)
              FadeTransition(
                opacity: _fadeSlogan,
                child: AnimatedBuilder(
                  animation: _pulseProgress,
                  builder: (context, child) {
                    return Container(
                      width: 200 * _pulseProgress.value,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00D4AA),
                            Color(0xFF00FFE0),
                            Color(0xFF00D4AA),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4AA).withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}