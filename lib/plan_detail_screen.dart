import 'package:flutter/material.dart';

class PlanDetailScreen extends StatelessWidget {
  final Map<String, String> data;
  const PlanDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(data['title'] ?? 'Детали плана'),
        backgroundColor: const Color(0xFF0F1115),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF0F1115),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔴 КРУПНЫЙ ДИСКЛЕЙМЕР (Если есть)
            if (data['disclaimer'] != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[900]?.withValues(alpha: 0.3), // Темно-красный фон
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent, width: 2), // Ярко-красная рамка
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 32),
                        const SizedBox(width: 10),
                        const Text(
                          'МЕДИЦИНСКОЕ ПРЕДУПРЕЖДЕНИЕ',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['disclaimer']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16, // Крупный шрифт
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            //  Блок воздействия
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00D4AA)),
              ),
              child: Column(
                children: [
                  Text(
                    data['impact'] ?? '',
                    style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text('Воздействие на долголетие', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 📝 Детальный план
            const Text('Детальный план действий:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Text(
                data['details'] ?? 'Загрузка...',
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),

            // 🔬 Научное обоснование
            const Text('Научное обоснование:', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              data['science'] ?? '',
              style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Вернуться к списку'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00D4AA)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}