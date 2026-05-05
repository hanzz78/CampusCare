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

  // 1. Statistik Angka
  int get totalLaporan => _reports.length;
  int get belumDireview => _reports.where((t) => t.statusTiket == 'PENDING_REVIEW' || t.statusTiket == 'SUBMITTED').length;
  int get selesai => _reports.where((t) => t.statusTiket == 'APPROVED' || t.statusTiket == 'REJECTED' || t.statusTiket == 'RESOLVED' || t.statusTiket == 'CLOSED').length;
  
  // 2. Daftar Laporan Masuk
  List<TiketModel> get laporanMasuk {
    // Menampilkan hanya yang butuh review/tindakan
    return _reports.where((t) => t.statusTiket == 'PENDING_REVIEW' || t.statusTiket == 'SUBMITTED').toList();
  }

  // 3. Statistik Kategori
  int get sarprasCount => _reports.where((t) => t.kategori == 'Sarpras').length;
  int get kebersihanCount => _reports.where((t) => t.kategori == 'Kebersihan').length;

  double get sarprasPercentage {
    if (_reports.isEmpty) return 0;
    return (sarprasCount / _reports.length) * 100;
  }
  
  double get kebersihanPercentage {
    if (_reports.isEmpty) return 0;
    return (kebersihanCount / _reports.length) * 100;
  }

  // 4. Urgensi (Berdasarkan Upvote sebagai Simulasi)
  int get urgensiHigh => _reports.where((t) => t.jumlahUpvote >= 15).length;
  int get urgensiMedium => _reports.where((t) => t.jumlahUpvote >= 5 && t.jumlahUpvote < 15).length;
  int get urgensiLow => _reports.where((t) => t.jumlahUpvote < 5).length;


  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simulasi delay jaringan
    await Future.delayed(const Duration(milliseconds: 800));

    // Data Dummy dengan upvote & lokasi untuk UI yang lebih realistis
    final List<Map<String, dynamic>> dummyJson = [
      {'_id': '1', 'local_id': 'loc1', 'user_id': 'u1', 'kategori': 'Sarpras', 'judul': 'AC Bocor Parah', 'lokasi_detail': 'Gedung D, Lt 2', 'deskripsi': 'Air menetes ke lantai', 'foto_paths': [], 'jumlah_upvote': 20, 'status_tiket': 'PENDING_REVIEW', 'created_at': DateTime.now().subtract(const Duration(days: 0)).toIso8601String()},
      {'_id': '2', 'local_id': 'loc2', 'user_id': 'u2', 'kategori': 'Kebersihan', 'judul': 'Lantai Lengket', 'lokasi_detail': 'Kantin Utama', 'deskripsi': 'Banyak tumpahan minuman', 'foto_paths': [], 'jumlah_upvote': 3, 'status_tiket': 'PENDING_REVIEW', 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
      {'_id': '3', 'local_id': 'loc3', 'user_id': 'u3', 'kategori': 'Sarpras', 'judul': 'Proyektor Mati', 'lokasi_detail': 'Lab Komputer C', 'deskripsi': 'Lampu indikator merah', 'foto_paths': [], 'jumlah_upvote': 10, 'status_tiket': 'APPROVED', 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
      {'_id': '4', 'local_id': 'loc4', 'user_id': 'u4', 'kategori': 'Kebersihan', 'judul': 'Sampah Menumpuk', 'lokasi_detail': 'Taman Depan', 'deskripsi': 'Belum diambil 3 hari', 'foto_paths': [], 'jumlah_upvote': 8, 'status_tiket': 'REJECTED', 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
      {'_id': '5', 'local_id': 'loc5', 'user_id': 'u5', 'kategori': 'Sarpras', 'judul': 'Kursi Patah', 'lokasi_detail': 'Ruang Tunggu Dosen', 'deskripsi': 'Kaki kursi patah satu', 'foto_paths': [], 'jumlah_upvote': 1, 'status_tiket': 'PENDING_REVIEW', 'created_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String()},
      {'_id': '6', 'local_id': 'loc6', 'user_id': 'u6', 'kategori': 'Sarpras', 'judul': 'Pintu Rusak', 'lokasi_detail': 'Toilet Gedung A', 'deskripsi': 'Tidak bisa dikunci', 'foto_paths': [], 'jumlah_upvote': 25, 'status_tiket': 'PENDING_REVIEW', 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
    ];

    _reports = dummyJson.map((json) => TiketModel.fromJson(json)).toList();
    _isLoading = false;
    notifyListeners();
  }
}
