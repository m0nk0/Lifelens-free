import 'package:flutter/material.dart';
import 'bio_age_calculator.dart';
import 'history_manager.dart';

class ResultScreen extends StatefulWidget {
  final BioAgeResult result;
  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    _saveResult();
  }

  Future<void> _saveResult() async {
    await HistoryManager.save(ScanHistory(
      date: DateTime.now(),
      bioAge: widget.result.biologicalAge,
      chronoAge: widget.result.chronologicalAge,
      riskLevel: widget.result.riskLevel,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Результат"),
        backgroundColor: const Color(0xFF0F1115),
      ),
      backgroundColor: const Color(0xFF0F1115),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "📊 ${widget.result.biologicalAge} лет",
              style: const TextStyle(
                  color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const Text("Биологический возраст",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16.0),
            Text(
              widget.result.riskLevel,
              style: const TextStyle(
                  color: Color(0xFF00D4AA),
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32.0),
            ...widget.result.recommendations.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text("• $r",
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 32.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4AA),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text("Вернуться к камере",
                    style: TextStyle(color: Colors.black, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}