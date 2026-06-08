import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'history_manager.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await HistoryManager.load();
    setState(() {
      _history = data.reversed.toList();
      _isLoading = false;
    });
  }

  List<FlSpot> _getChartSpots() {
    if (_history.isEmpty) return [];
    final spots = <FlSpot>[];
    final recent = _history.length > 10 ? _history.sublist(_history.length - 10) : _history;
    for (int i = 0; i < recent.length; i++) {
      spots.add(FlSpot(i.toDouble(), recent[i].bioAge.toDouble()));
    }
    return spots;
  }

  Color _getLineColor() {
    if (_history.length < 2) return const Color(0xFF00D4AA);
    final first = _history.first.bioAge;
    final last = _history.last.bioAge;
    return last < first ? const Color(0xFF00D4AA) : Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final chartSpots = _getChartSpots();
    final lineColor = _getLineColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text("📜 История замеров"),
        backgroundColor: const Color(0xFF0F1115),
      ),
      backgroundColor: const Color(0xFF0F1115),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D4AA)))
          : _history.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          "Замеров пока нет",
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Сделайте первый анализ в камере",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 📈 Блок с графиком
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📊 Динамика биовозраста',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 200,
                              child: chartSpots.length < 2
                                  ? Container(
                                      width: double.infinity, // ✅ Растягиваем на всю ширину
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.grey[500], size: 32),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Замеры сохраняются раз в 2 недели.\nСледующая точка появится через 14 дней.\nПродолжайте следить за трекером! 📈',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.4),
                                          ),
                                        ],
                                      ),
                                    )
                                  : LineChart(
                                      LineChartData(
                                        gridData: const FlGridData(show: false),
                                        titlesData: FlTitlesData(
                                          leftTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 20,
                                              getTitlesWidget: (value, meta) {
                                                final idx = value.toInt();
                                                if (idx >= 0 && idx < _history.length) {
                                                  final date = _history[idx].date;
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 8),
                                                    child: Text(
                                                      '${date.day}.${date.month}',
                                                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                                                    ),
                                                  );
                                                }
                                                return const SizedBox();
                                              },
                                            ),
                                          ),
                                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: chartSpots,
                                            isCurved: true,
                                            color: lineColor,
                                            barWidth: 3,
                                            dotData: const FlDotData(show: true),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: lineColor.withValues(alpha: 0.1),
                                            ),
                                          ),
                                        ],
                                        minY: chartSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2,
                                        maxY: chartSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2,
                                      ),
                                    ),
                            ),
                            if (chartSpots.length >= 2)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(width: 12, height: 3, color: lineColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      lineColor == const Color(0xFF00D4AA) 
                                          ? '✅ Тренд на улучшение' 
                                          : '⚠️ Требуется внимание',
                                      style: TextStyle(color: lineColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 📋 Список записей
                      const Text(
                        'Подробная история',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._history.reversed.map((item) {
                        final diff = item.bioAge - item.chronoAge;
                        final color = diff <= 0
                            ? const Color(0xFF00D4AA)
                            : (diff <= 3 ? Colors.orange : Colors.redAccent);
                        
                        return Card(
                          color: Colors.grey[850],
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            leading: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                CircleAvatar(
                                  backgroundColor: color.withValues(alpha: 0.2),
                                  child: Text(
                                    item.bioAge.toString(),
                                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (item.hasLoyaltyBonus)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00D4AA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.star, color: Colors.black, size: 12),
                                  ),
                              ],
                            ),
                            title: Text(
                              "Биовозраст: ${item.bioAge} лет",
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              item.riskLevel,
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            trailing: Text(
                              _formatDate(item.date),
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                            onTap: () {
                              if (item.hasLoyaltyBonus) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: const Color(0xFF1A1C21),
                                    title: const Text('🎉 Бонус лояльности!', 
                                      style: TextStyle(color: Colors.white)),
                                    content: const Text(
                                      'Вы были дисциплинированы в трекере: −2 месяца к биовозрасту! Продолжайте в том же духе.',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Понял', style: TextStyle(color: Color(0xFF00D4AA))),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";
}