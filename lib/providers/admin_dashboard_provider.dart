import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/tiket_model.dart';

class AdminDashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<TiketModel> _reports = [];
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  List<TiketModel> get reports => _reports;
  String? get errorMessage => _errorMessage;

  // TODO: Sesuaikan URL ini dengan endpoint REST API MongoDB Anda nantinya
  final String apiUrl = 'http://10.0.2.2:3000/api/tickets';

  AdminDashboardProvider() {
    fetchDashboardStats();
  }

  int get totalMasuk => _reports.length;
  int get pendingCount => _reports.where((t) => t.statusTiket == 'PENDING_REVIEW' || t.statusTiket == 'SUBMITTED').length;
  
  // Asumsi dummy waktu respons, bisa diganti perhitungan dinamis nantinya
  String get waktuRespons => '0 Jam';

  String get resolusiPercentage {
    if (_reports.isEmpty) return '0%';
    int resolved = _reports.where((t) => t.statusTiket == 'RESOLVED' || t.statusTiket == 'CLOSED').length;
    return '${((resolved / _reports.length) * 100).toStringAsFixed(0)}%';
  }

  // Statistik Kategori
  double get sarprasPercentage {
    if (_reports.isEmpty) return 0;
    return (_reports.where((t) => t.kategori == 'Sarpras').length / _reports.length) * 100;
  }
  
  double get kebersihanPercentage {
    if (_reports.isEmpty) return 0;
    return (_reports.where((t) => t.kategori == 'Kebersihan').length / _reports.length) * 100;
  }

  // Statistik Status untuk Pie Chart
  double get pendingPercentage {
    if (_reports.isEmpty) return 0;
    return (pendingCount / _reports.length) * 100;
  }

  double get approvedPercentage {
    if (_reports.isEmpty) return 0;
    int count = _reports.where((t) => t.statusTiket == 'APPROVED' || t.statusTiket == 'IN_PROGRESS').length;
    return (count / _reports.length) * 100;
  }

  double get rejectedPercentage {
    if (_reports.isEmpty) return 0;
    int count = _reports.where((t) => t.statusTiket == 'REJECTED').length;
    return (count / _reports.length) * 100;
  }

  double get resolvedPercentage {
    if (_reports.isEmpty) return 0;
    int count = _reports.where((t) => t.statusTiket == 'RESOLVED' || t.statusTiket == 'CLOSED').length;
    return (count / _reports.length) * 100;
  }

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simulasi delay ringan
    await Future.delayed(const Duration(milliseconds: 800));

    // Data Dummy simulasi JSON agar grafik bisa tampil (seperti dashboard user yang statis)
    final List<Map<String, dynamic>> dummyJson = [
      {'_id': '1', 'local_id': 'loc1', 'user_id': 'u1', 'kategori': 'Sarpras', 'lokasi_detail': 'Gedung A', 'deskripsi': 'AC Rusak', 'foto_paths': [], 'status_tiket': 'PENDING_REVIEW', 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
      {'_id': '2', 'local_id': 'loc2', 'user_id': 'u2', 'kategori': 'Kebersihan', 'lokasi_detail': 'Toilet B', 'deskripsi': 'Kotor', 'foto_paths': [], 'status_tiket': 'RESOLVED', 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
      {'_id': '3', 'local_id': 'loc3', 'user_id': 'u3', 'kategori': 'Sarpras', 'lokasi_detail': 'Lab C', 'deskripsi': 'Proyektor mati', 'foto_paths': [], 'status_tiket': 'APPROVED', 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
      {'_id': '4', 'local_id': 'loc4', 'user_id': 'u4', 'kategori': 'Kebersihan', 'lokasi_detail': 'Taman', 'deskripsi': 'Sampah', 'foto_paths': [], 'status_tiket': 'REJECTED', 'created_at': DateTime.now().toIso8601String()},
      {'_id': '5', 'local_id': 'loc5', 'user_id': 'u5', 'kategori': 'Sarpras', 'lokasi_detail': 'Gedung D', 'deskripsi': 'Kursi patah', 'foto_paths': [], 'status_tiket': 'PENDING_REVIEW', 'created_at': DateTime.now().toIso8601String()},
    ];

    _reports = dummyJson.map((json) => TiketModel.fromJson(json)).toList();
    _isLoading = false;
    notifyListeners();
  }
}
