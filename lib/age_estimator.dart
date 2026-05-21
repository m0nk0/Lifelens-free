import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AgeEstimator {
  static Interpreter? _interpreter;
  static bool _isLoaded = false;

  static Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model_age_nonq.tflite');
      _isLoaded = true;
      debugPrint('✅ TFLite модель загружена');
      
      // Логируем входной тензор модели для отладки
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint('📐 Shape: вход $inputShape → выход $outputShape');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки модели: $e');
      rethrow;
    }
  }

  /// Подготовка изображения: обрезка -> ресайз 224x224 -> нормализация [0, 1]
  static List<List<List<List<double>>>> _preprocessImage(File imageFile, List<double> box) {
    final original = img.decodeImage(imageFile.readAsBytesSync())!;
    
    final left = box[0].round().clamp(0, original.width - 1);
    final top = box[1].round().clamp(0, original.height - 1);
    final width = box[2].round();
    final height = box[3].round();
    
    final padding = (width * 0.2).round();
    final crop = img.copyCrop(
      original,
      x: (left - padding).clamp(0, original.width - 1),
      y: (top - padding).clamp(0, original.height - 1),
      width: (width + padding * 2).clamp(1, original.width),
      height: (height + padding * 2).clamp(1, original.height),
    );
    
    final resized = img.copyResize(crop, width: 224, height: 224);
    final bytes = resized.getBytes(); // RGBA format
    
    var input = List.generate(1, (_) =>
      List.generate(224, (_) =>
        List.generate(224, (_) =>
          List.generate(3, (c) => 0.0)
        )
      )
    );

    int pixelIdx = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        // ✅ Нормализация в [0, 1] — самый распространённый формат
        input[0][y][x][0] = bytes[pixelIdx] / 255.0;       // R
        input[0][y][x][1] = bytes[pixelIdx + 1] / 255.0;   // G
        input[0][y][x][2] = bytes[pixelIdx + 2] / 255.0;   // B
        pixelIdx += 4; // Пропускаем Alpha
      }
    }
    return input;
  }

  static Future<int> predictAge(File imageFile, List<double> box) async {
    if (!_isLoaded) await loadModel();
    if (_interpreter == null) throw Exception('Модель не загружена');

    final input = _preprocessImage(imageFile, box);
    var output = List.generate(1, (_) => List.generate(1, (i) => 0.0));
    
    _interpreter!.run(input, output);
    
    final rawAge = output[0][0] as double;
    debugPrint('🔍 Сырой вывод модели: $rawAge');

    // ✅ Защита от аномалий: если модель выдаёт < 10 или > 90 — это ошибка
    if (rawAge < 10 || rawAge > 90) {
      debugPrint('⚠️ Аномальный вывод модели ($rawAge), используем дефолт 40');
      return 40; // безопасный дефолт
    }

    final finalAge = rawAge.round().clamp(16, 95);
    debugPrint('✅ Финальный возраст из модели: $finalAge лет');
    return finalAge;
  }

  /// Расчёт яркости лица (0.0 - 1.0)
  static Future<double> getFaceBrightness(File imageFile, List<double> box) async {
    final original = img.decodeImage(imageFile.readAsBytesSync())!;
    final left = box[0].round().clamp(0, original.width - 1);
    final top = box[1].round().clamp(0, original.height - 1);
    final width = box[2].round();
    final height = box[3].round();
    final padding = (width * 0.1).round();

    final crop = img.copyCrop(
      original,
      x: (left - padding).clamp(0, original.width - 1),
      y: (top - padding).clamp(0, original.height - 1),
      width: (width + padding * 2).clamp(1, original.width),
      height: (height + padding * 2).clamp(1, original.height),
    );

    final small = img.copyResize(crop, width: 50, height: 50);
    final bytes = small.getBytes();
    double sum = 0.0;
    int count = 0;

    for (int i = 0; i < bytes.length; i += 4) {
      sum += (0.299 * bytes[i] + 0.587 * bytes[i + 1] + 0.114 * bytes[i + 2]) / 255.0;
      count++;
    }
    return (sum / count).clamp(0.0, 1.0);
  }

  static void close() {
    _interpreter?.close();
    _isLoaded = false;
  }
}