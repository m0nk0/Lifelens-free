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

  @override
  void initState() {
    super.initState();

    //  Увеличили длительность до 4 секунд
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // 🖼️ Логотип (появление 0-2с)
    _fadeLogo = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _scaleLogo = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );

    // 📛 Название (появление 1.2с - 2.8с)
    _fadeText = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.7, curve: Curves.easeOut)),
    );

    // 🔤 Подзаголовок (появление 2с - 3.2с)
    _fadeSubtitle = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.8, curve: Curves.easeOut)),
    );
    _slideSubtitle = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic)),
    );

    _controller.forward();

    // 🔄 Переход через 4 секунды
    Timer(const Duration(milliseconds: 4000), () async {
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
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeLogo,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🖼️ Логотип
              ScaleTransition(
                scale: _scaleLogo,
                child: Image.asset(
                  'assets/image/logo.png',
                  width: 270,
                  height: 270,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              
              //  Название (УВЕЛИЧЕН ШРИФТ: 34 -> 48)
              FadeTransition(
                opacity: _fadeText,
                child: const Text(
                  'LifeLens',
                  style: TextStyle(
                    color: Color(0xFF0F1115),
                    fontSize: 48, // ✅ Было 34
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                    height: 1.1,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🔤 Подзаголовок (УВЕЛИЧЕН ШРИФТ: 14 -> 18)
              FadeTransition(
                opacity: _fadeSubtitle,
                child: SlideTransition(
                  position: _slideSubtitle,
                  child: const Text(
                    'AI Biological Age Scanner',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18, // ✅ Было 14
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),

              //  Индикатор
              FadeTransition(
                opacity: _fadeSubtitle,
                child: SizedBox(
                  width: 40,
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}