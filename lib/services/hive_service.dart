import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String _boxName = 'offline_reports';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
    if (kDebugMode) {
      print('✅ Hive initialized and $_boxName box opened.');
    }
  }

  Box get _box => Hive.box(_boxName);

  Future<void> saveOfflineReport(Map<String, dynamic> report) async {
    await _box.add(report);
    if (kDebugMode) {
      print('✅ Offline report saved to Hive. Total reports: ${_box.length}');
    }
  }

  List<Map<String, dynamic>> getOfflineReports() {
    final reports = <Map<String, dynamic>>[];
    for (var i = 0; i < _box.length; i++) {
      final report = _box.getAt(i);
      if (report is Map) {
        // Ensure it's a Map<String, dynamic>
        reports.add(Map<String, dynamic>.from(report));
      }
    }
    return reports;
  }

  Future<void> deleteOfflineReport(int index) async {
    await _box.deleteAt(index);
    if (kDebugMode) {
      print('✅ Offline report at index $index deleted from Hive.');
    }
  }
}
