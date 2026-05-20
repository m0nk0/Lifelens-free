import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(LifeLensApp(cameras: cameras));
}

class LifeLensApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const LifeLensApp({super.key, required this.cameras});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(primaryColor: const Color(0xFF00D4AA), scaffoldBackgroundColor: const Color(0xFF0F1115)),
      home: WelcomeScreen(cameras: cameras),
    );
  }
}