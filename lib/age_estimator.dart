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
      
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint('📐 Shape: вход $inputShape → выход $outputShape');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки модели: $e');
      rethrow;
    }
  }

  /// Подготовка изображения: обрезка -> ресайз 200x200 -> ImageNet нормализация
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
    
    final resized = img.copyResize(crop, width: 200, height: 200);
    final bytes = resized.getBytes(order: img.ChannelOrder.rgb);
    
    debugPrint('🖼️ Изображение: ${resized.width}x${resized.height}, bytes.length=${bytes.length}');
    
    var input = List.generate(1, (_) =>
      List.generate(200, (_) =>
        List.generate(200, (_) =>
          List.generate(3, (c) => 0.0)
        )
      )
    );

    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];

    int pixelIdx = 0;
    for (int y = 0; y < 200; y++) {
      for (int x = 0; x < 200; x++) {
        input[0][y][x][0] = (bytes[pixelIdx] / 255.0 - mean[0]) / std[0];
        input[0][y][x][1] = (bytes[pixelIdx + 1] / 255.0 - mean[1]) / std[1];
        input[0][y][x][2] = (bytes[pixelIdx + 2] / 255.0 - mean[2]) / std[2];
        pixelIdx += 3;
      }
    }
    return input;
  }

  /// Возвращает СЫРОЙ вывод модели (для дальнейшей калибровки в калькуляторе)
  static Future<double> predictAgeRaw(File imageFile, List<double> box) async {
    if (!_isLoaded) await loadModel();
    if (_interpreter == null) throw Exception('Модель не загружена');

    final input = _preprocessImage(imageFile, box);
    var output = List.generate(1, (_) => List.generate(1, (i) => 0.0));
    
    try {
      _interpreter!.run(input, output);
    } catch (e) {
      debugPrint('❌ Ошибка инференса TFLite: $e');
      return 0.5; // дефолт
    }
    
    final rawOutput = output[0][0] as double;
    debugPrint('🔍 Сырой вывод модели: $rawOutput');
    return rawOutput;
  }

  /// ✅ Калибровка вывода модели с ограничением ±5 лет от паспорта
  static int calibrateAge(double rawModelOutput, int userAge) {
    // Эмпирический центр для нашей модели, при котором возраст = паспортному
    const double center = 0.225;
    
    // Растягиваем узкий диапазон сырого вывода (0.20 - 0.25) 
    // в диапазон корректировки ±5 лет от паспортного возраста.
    double deviation = rawModelOutput - center;
    int rawAdjustment = (deviation * 200).round();
    
    // ✅ ОГРАНИЧЕНИЕ ±5 ЛЕТ ОТ ПАСПОРТА
    // Это предотвращает экстремальные значения, которые модель не может точно определить
    int ageAdjustment = rawAdjustment.clamp(-5, 5);
    
    if (rawAdjustment != ageAdjustment) {
      debugPrint('🔒 [LIMIT] Корректировка ограничена: $rawAdjustment → $ageAdjustment лет (предел ±5)');
    }
    
    int calibratedAge = userAge + ageAdjustment;
    
    debugPrint('🔧 Декодирование: сырой=$rawModelOutput | Отклонение: ${deviation.toStringAsFixed(4)} | Корректировка: $ageAdjustment лет');
    debugPrint('✅ Итоговый возраст: $calibratedAge лет (паспорт: $userAge)');
    
    return calibratedAge;
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
    final bytes = small.getBytes(order: img.ChannelOrder.rgb);
    double sum = 0.0;
    int count = 0;

    for (int i = 0; i < bytes.length; i += 3) {
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