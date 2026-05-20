import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScanHistory {
  final DateTime date;
  final int bioAge;
  final int chronoAge;
  final String riskLevel;

  ScanHistory({
    required this.date,
    required this.bioAge,
    required this.chronoAge,
    required this.riskLevel,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'bioAge': bioAge,
        'chronoAge': chronoAge,
        'riskLevel': riskLevel,
      };

  factory ScanHistory.fromJson(Map<String, dynamic> json) => ScanHistory(
        date: DateTime.parse(json['date']),
        bioAge: json['bioAge'],
        chronoAge: json['chronoAge'],
        riskLevel: json['riskLevel'],
      );
}

class HistoryManager {
  static const String _key = 'lifelens_history';

  static Future<void> save(ScanHistory entry) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_key) ?? [];
    final List<ScanHistory> history =
        raw.map((e) => ScanHistory.fromJson(json.decode(e))).toList();

    history.insert(0, entry);
    if (history.length > 50) history.removeLast();

    await prefs.setStringList(
        _key, history.map((e) => json.encode(e.toJson())).toList());
  }

  static Future<List<ScanHistory>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) => ScanHistory.fromJson(json.decode(e))).toList();
  }
}