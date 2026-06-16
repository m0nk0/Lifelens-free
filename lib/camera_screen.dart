import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'health_form.dart';
import 'age_estimator.dart';
import 'bio_age_calculator.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  late FaceDetector _detector;
  late AnimationController _scanController;
  
  bool _isProcessing = false;
  bool _isScanning = false;
  String _status = "Поместите лицо в рамку и нажмите кнопку";
  XFile? _capturedPhoto;
  double get _scanProgress => _scanController.value;
  
  String _trainingStatus = "";

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(vsync: this, duration: const Duration(seconds: 6));
    _detector = FaceDetector(options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate, enableClassification: true));
    _initCamera();
    _loadModel();
    _loadTrainingStatus();
  }

  Future<void> _initCamera() async {
    _controller = CameraController(widget.camera, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadModel() async {
    try { await AgeEstimator.loadModel(); } 
    catch (e) { debugPrint('⚠️ Ошибка загрузки TFLite: $e'); }
  }

  Future<void> _loadTrainingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final totalScanDays = prefs.getInt('total_scan_days') ?? 0;
    
    if (totalScanDays == 0) {
      _trainingStatus = "🔬 Первичная калибровка модели";
    } else if (totalScanDays == 1) {
      _trainingStatus = "🧠 Обучение на ваших данных";
    } else if (totalScanDays == 2) {
      _trainingStatus = "🎯 Уточнение биометрического профиля";
    } else {
      _trainingStatus = "✅ Модель обучена. Точное определение";
    }
    
    if (mounted) setState(() {});
  }

  // ✅ Динамический лимит сканов: 3 для дней 1-4, 1 для дня 5+
  Future<int> _getMaxScans() async {
    final prefs = await SharedPreferences.getInstance();
    final totalScanDays = prefs.getInt('total_scan_days') ?? 0;
    return (totalScanDays >= 4) ? 1 : 3;
  }

  Future<void> _skipScan() async {
    if (_isProcessing) return;
    
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final scansToday = prefs.getInt('scans_today_$today') ?? 0;
    final maxScans = await _getMaxScans();

    if (scansToday >= maxScans) {
      final resultJson = prefs.getString('last_final_result_json');
      if (resultJson != null && mounted) {
        final Map<String, dynamic> data = jsonDecode(resultJson);
        final savedResult = BioAgeResult(
          biologicalAge: data['biologicalAge'],
          chronologicalAge: data['chronologicalAge'],
          ageDifference: data['ageDifference'],
          riskLevel: data['riskLevel'],
          recommendations: List<String>.from(data['recommendations']),
          disclaimer: data['disclaimer'],
          smokes: false, bmi: 0, activity: '', sleepHours: 0,
          calibratedFaceAge: data['calibratedFaceAge'],
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(result: savedResult, isFinalResult: true)),
        );
      }
    } else {
      final lastFaceAge = prefs.getInt('last_face_age') ?? 35;
      final lastBrightness = prefs.getDouble('last_face_brightness') ?? 0.5;
      final lastRaw = prefs.getDouble('last_raw_output') ?? 0.35;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HealthForm(
            faceAgeEstimate: lastFaceAge,
            faceBrightness: lastBrightness,
            rawModelOutput: lastRaw,
          ),
        ),
      ).then((_) => _resetCameraState());
    }
  }

  Future<void> _analyzeFace() async {
    if (_isProcessing) return;
    
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final scansToday = prefs.getInt('scans_today_$today') ?? 0;
    final maxScans = await _getMaxScans();

    if (scansToday >= maxScans) {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1C21),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('🔒 Дневной лимит исчерпан', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Вы использовали все сканирования на сегодня.\n\n'
              'Модель стабилизирована и запомнила ваш биологический возраст.\n'
              'Вернитесь завтра!',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Хорошо', style: TextStyle(color: Color(0xFF00D4AA))),
              ),
            ],
          ),
        );
      }
      return;
    }
    
    HapticFeedback.mediumImpact();
    _isProcessing = true;
    _status = "📸 Делаю снимок...";
    setState(() {});

    try {
      final photo = await _controller!.takePicture();
      _capturedPhoto = photo;
      
      _isScanning = true;
      _status = "🔍 Анализирую...";
      setState(() {});

      await _scanController.forward(from: 0.0);

      final inputImage = InputImage.fromFilePath(photo.path);
      final faces = await _detector.processImage(inputImage);

      if (!mounted) return;
      if (faces.isEmpty) {
        _status = "🔍 Лицо не найдено. Попробуйте ещё раз.";
        _isScanning = false; _capturedPhoto = null; _scanController.reset(); setState(() {});
        return;
      }

      final face = faces.first;
      final boundingBox = [face.boundingBox.left.toDouble(), face.boundingBox.top.toDouble(), face.boundingBox.width.toDouble(), face.boundingBox.height.toDouble()];
      
      _status = "🧮 Вычисляю возраст и освещение...";
      setState(() {});
      
      double rawModelOutput = 0.5;
      double brightness = 0.5;
      
      try {
        rawModelOutput = await AgeEstimator.predictAgeRaw(File(photo.path), boundingBox);
        brightness = await AgeEstimator.getFaceBrightness(File(photo.path), boundingBox);
        
        await prefs.setInt('last_face_age', (rawModelOutput * 100).round());
        await prefs.setDouble('last_face_brightness', brightness);
        await prefs.setDouble('last_raw_output', rawModelOutput);
        
      } catch (e) {
        debugPrint('️ Ошибка инференса: $e');
      }

      HapticFeedback.lightImpact();
      _status = "✅ Анализ завершён";
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      _isScanning = false; _capturedPhoto = null; _scanController.reset();
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HealthForm(
            faceAgeEstimate: (rawModelOutput * 100).round(), 
            faceBrightness: brightness,
            rawModelOutput: rawModelOutput,
          ),
        ),
      ).then((_) => _resetCameraState());
      
    } catch (e) {
      debugPrint("⚠️ Ошибка: $e");
      if (mounted) { 
        _status = "❌ Ошибка анализа"; _isProcessing = false; _isScanning = false; _capturedPhoto = null; _scanController.reset(); setState(() {}); 
      }
    } finally { 
      _isProcessing = false; 
    }
  }

  void _resetCameraState() async {
    if (!mounted) return;
    try { await _controller?.stopImageStream(); } catch (e) {}
    await _controller?.dispose();
    _controller = null;
    await _initCamera();
    await _loadTrainingStatus();
    if (mounted) {
      setState(() {
        _isProcessing = false; _isScanning = false; _status = "Поместите лицо в рамку и нажмите кнопку"; _capturedPhoto = null; _scanController.reset();
      });
    }
  }

  @override
  void dispose() {
    _scanController.dispose(); _controller?.dispose(); _detector.close(); AgeEstimator.close(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Color(0xFF0F1115), body: Center(child: CircularProgressIndicator(color: Color(0xFF00D4AA))));
    }

    final size = MediaQuery.of(context).size;
    final isPhone = size.shortestSide < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F1115), Color(0xFF1A1D24), Color(0x1A00D4AA)])),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _capturedPhoto != null && _isScanning
                ? Center(child: Transform(alignment: Alignment.center, transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0), child: AspectRatio(aspectRatio: 3 / 4, child: Image.file(File(_capturedPhoto!.path), fit: BoxFit.cover))))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final previewWidth = _controller!.value.previewSize!.height;
                      final previewHeight = _controller!.value.previewSize!.width;
                      final previewRatio = previewWidth / previewHeight;
                      final boxRatio = constraints.maxWidth / constraints.maxHeight;
                      double renderWidth, renderHeight;
                      if (boxRatio > previewRatio) { renderWidth = constraints.maxWidth; renderHeight = constraints.maxWidth / previewRatio; } 
                      else { renderHeight = constraints.maxHeight; renderWidth = constraints.maxHeight * previewRatio; }
                      final maxAspectWidth = renderHeight * (3 / 4);
                      if (renderWidth > maxAspectWidth) renderWidth = maxAspectWidth;
                      return Center(child: SizedBox(width: renderWidth, height: renderHeight, child: CameraPreview(_controller!)));
                    },
                  ),
            
            if (!_isScanning) Positioned.fill(child: Center(child: CustomPaint(size: isPhone ? Size(size.width * 0.85, size.height * 0.45) : const Size(450, 560), painter: CenteredScannerPainter(isScanning: false, scanProgress: 0)))),
            
            if (_isScanning) AnimatedBuilder(
                animation: _scanController,
                builder: (ctx, child) {
                  return Stack(children: [
                    Positioned.fill(child: Center(child: CustomPaint(size: isPhone ? Size(size.width * 0.85, size.height * 0.45) : const Size(450, 560), painter: CenteredScannerPainter(isScanning: true, scanProgress: _scanProgress)))),
                    _TermLog(isScanning: _isScanning, terms: const ["Анализ микрорельефа", "Оценка тургора кожи", "Картирование морщин", "Сканирование радужки", "Анализ сосудистой сетки", "Измерение пигментации", "Детекция маркеров усталости", "Оценка симметрии лица"], side: 'left'),
                    _TermLog(isScanning: _isScanning, terms: const ["Анализ тонуса мышц", "Расчет индекса гидратации", "Анализ периорбитальной зоны", "Оценка коллагеновой сетки", "Термография тканей", "Анализ микроциркуляции", "Детекция акне-маркеров", "Расчет биометрических точек"], side: 'right'),
                    Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.4))),
                    
                    if (_trainingStatus.isNotEmpty)
                      Positioned(
                        bottom: isPhone ? 120 : 150,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4AA).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.5), width: 1.5),
                          ),
                          child: Text(
                            _trainingStatus,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF00D4AA),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ]);
                },
              ),
            
            Positioned(top: 60, left: 20, right: 20, child: Container(padding: const EdgeInsets.all(12.0), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12.0)), child: Text(_status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)))),
            
            if (!_isProcessing && !_isScanning)
              Positioned(
                bottom: isPhone ? 24 : 50, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _skipScan,
                      label: const Text("Пропустить", style: TextStyle(color: Color(0xFF00D4AA))),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF00D4AA)), padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _analyzeFace,
                      icon: const Icon(Icons.skip_next, color: Colors.black),
                      label: const Text("Оценить", style: TextStyle(color: Colors.black)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4AA), padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CenteredScannerPainter extends CustomPainter {
  final bool isScanning; final double scanProgress;
  const CenteredScannerPainter({required this.isScanning, required this.scanProgress});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const cornerSize = 36.0;
    final borderColor = isScanning ? const Color(0xFF00D4AA) : const Color(0x9900D4AA);
    final cornerPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(rect.left, rect.top + cornerSize)..lineTo(rect.left, rect.top)..lineTo(rect.left + cornerSize, rect.top)..moveTo(rect.right - cornerSize, rect.top)..lineTo(rect.right, rect.top)..lineTo(rect.right, rect.top + cornerSize)..moveTo(rect.right, rect.bottom - cornerSize)..lineTo(rect.right, rect.bottom)..lineTo(rect.right - cornerSize, rect.bottom)..moveTo(rect.left + cornerSize, rect.bottom)..lineTo(rect.left, rect.bottom)..lineTo(rect.left, rect.bottom - cornerSize);
    canvas.drawPath(path, cornerPaint);
    if (isScanning) {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20.0)), Paint()..color = const Color(0x2600D4AA)..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
      final scanY = rect.top + (size.height * scanProgress);
      canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), Paint()..shader = const LinearGradient(colors: [Color(0x0000D4AA), Color(0xFF00D4AA), Color(0x0000D4AA)], begin: Alignment.centerLeft, end: Alignment.centerRight).createShader(Rect.fromLTWH(0, scanY - 4, size.width, 8))..strokeWidth = 8);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TermLog extends StatefulWidget {
  final bool isScanning; final List<String> terms; final String side;
  const _TermLog({required this.isScanning, required this.terms, required this.side});
  @override State<_TermLog> createState() => _TermLogState();
}
class _TermLogState extends State<_TermLog> {
  final List<String> _visible = []; Timer? _timer; int _idx = 0;
  @override void initState() { super.initState(); if (widget.isScanning) _start(); }
  @override void didUpdateWidget(covariant _TermLog oldWidget) { super.didUpdateWidget(oldWidget); if (widget.isScanning && !oldWidget.isScanning) _start(); if (!widget.isScanning) _stop(); }
  @override void dispose() { _stop(); super.dispose(); }
  void _start() {
    _visible.clear(); _idx = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted) { setState(() { _visible.insert(0, widget.terms[_idx % widget.terms.length]); if (_visible.length > 3) _visible.removeLast(); _idx++; }); }
    });
  }
  void _stop() { _timer?.cancel(); _visible.clear(); _idx = 0; }
  @override Widget build(BuildContext context) {
    if (!widget.isScanning || _visible.isEmpty) return const SizedBox.shrink();
    final items = _visible.take(3).toList(); final isLeft = widget.side == 'left';
    return Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        height: 130, width: 240, margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.4), width: 1.5)),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: AnimatedOpacity(opacity: i == 0 ? 1.0 : 0.4, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut,
                child: Text(items[i], textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: const Color(0xFF00D4AA), fontSize: i == 0 ? 18.0 : 14.0, fontWeight: FontWeight.w600, shadows: const [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1))]),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}