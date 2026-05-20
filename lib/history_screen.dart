import 'package:flutter/material.dart';
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
      _history = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📜 История замеров"),
        backgroundColor: const Color(0xFF0F1115),
      ),
      backgroundColor: const Color(0xFF0F1115),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D4AA)))
          : _history.isEmpty
              ? const Center(child: Text("Замеров пока нет", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _history.length,
                  itemBuilder: (ctx, i) {
                    final item = _history[i];
                    final diff = item.bioAge - item.chronoAge;
                    final color = diff <= 0
                        ? const Color(0xFF00D4AA)
                        : (diff <= 3 ? Colors.orange : Colors.redAccent);
                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          // ✅ FIX: withValues вместо deprecated withOpacity
                          backgroundColor: color.withValues(alpha: 0.2),
                          child: Text(
                            item.bioAge.toString(),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold),
                          ),
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
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";
}