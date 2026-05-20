import 'dart:io';
import 'dart:typed_data';
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
    } catch (e) {
      debugPrint('❌ Ошибка загрузки модели: $e');
      rethrow;
    }
  }

  static Float32List _preprocessImage(File imageFile, List<double> box) {
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
      width: width + padding * 2,
      height: height + padding * 2,
    );
    
    final resized = img.copyResize(crop, width: 224, height: 224);
    final bytes = resized.getBytes();
    
    final input = Float32List(224 * 224 * 3);
    int ptr = 0;
    for (int i = 0; i < bytes.length; i += 4) {
      input[ptr++] = bytes[i] / 255.0;
      input[ptr++] = bytes[i + 1] / 255.0;
      input[ptr++] = bytes[i + 2] / 255.0;
    }
    return input;
  }

  static Future<int> predictAge(File imageFile, List<double> box) async {
    if (!_isLoaded) await loadModel();
    if (_interpreter == null) throw Exception('Модель не загружена');

    final input1d = _preprocessImage(imageFile, box);
    
    final input4d = List.generate(1, (_) =>
      List.generate(224, (_) =>
        List.generate(224, (_) =>
          List.generate(3, (c) => 0.0)
        )
      )
    );
    
    int p = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        input4d[0][y][x][0] = input1d[p++];
        input4d[0][y][x][1] = input1d[p++];
        input4d[0][y][x][2] = input1d[p++];
      }
    }
    
    final output = List.generate(1, (_) => [0.0]);
    _interpreter!.run(input4d, output);
    
    final rawAge = output[0][0];
    return rawAge.round().clamp(0, 100);
  }

  static void close() {
    _interpreter?.close();
    _isLoaded = false;
  }
}