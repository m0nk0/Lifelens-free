import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ScanHistory {
  final DateTime date;
  final int bioAge;
  final int chronoAge;
  final String riskLevel;
  final bool hasLoyaltyBonus; // ✅ Новое поле

  ScanHistory({
    required this.date,
    required this.bioAge,
    required this.chronoAge,
    required this.riskLevel,
    this.hasLoyaltyBonus = false,
  });

  factory ScanHistory.fromJson(Map<String, dynamic> json) {
    return ScanHistory(
      date: DateTime.parse(json['date']),
      bioAge: json['bioAge'],
      chronoAge: json['chronoAge'],
      riskLevel: json['riskLevel'],
      hasLoyaltyBonus: json['hasLoyaltyBonus'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'bioAge': bioAge,
      'chronoAge': chronoAge,
      'riskLevel': riskLevel,
      'hasLoyaltyBonus': hasLoyaltyBonus,
    };
  }
}

class HistoryManager {
  static const String _key = 'scan_history';

  static Future<void> save(ScanHistory item) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];
    
    // Добавляем новую запись в начало
    history.insert(0, jsonEncode(item.toJson()));
    
    // Храним максимум 50 записей (экономия памяти)
    if (history.length > 50) history.removeLast();
    
    await prefs.setStringList(_key, history);
  }

  static Future<List<ScanHistory>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];
    
    return history.map((json) => ScanHistory.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}