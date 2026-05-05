import 'package:flutter/material.dart';
import '../models/tiket_model.dart';
import '../services/mongo_service.dart';

class AdminDashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<TiketModel> _reports = [];
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  List<TiketModel> get reports => _reports;
  String? get errorMessage => _errorMessage;

  // Filter & Sort State
  String _selectedCategoryFilter = 'Semua'; // 'Semua', 'Sarpras', 'Kebersihan'
  String _selectedSort = 'Waktu Terbaru'; // 'Waktu Terbaru', 'Waktu Terlama', 'Urgensi Tertinggi'

  String get selectedCategoryFilter => _selectedCategoryFilter;
  String get selectedSort => _selectedSort;

  AdminDashboardProvider() {
    fetchDashboardStats();
  }

  void setCategoryFilter(String category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  void setSort(String sort) {
    _selectedSort = sort;
    notifyListeners();
  }
  int get totalLaporan => _reports.length;
  int get belumDireview => _reports.where((t) => t.status == 'Menunggu Verifikasi').length;
  int get selesai => _reports.where((t) => t.status == 'Approved' || t.status == 'Rejected' || t.status == 'Documented').length;
  
  // 2. Daftar Laporan Masuk
  List<TiketModel> get laporanMasuk {
    // Menampilkan hanya yang butuh review/tindakan
    return _reports.where((t) => t.status == 'Menunggu Verifikasi').toList();
  }

  // 2.b Daftar Filtered & Sorted untuk Tab "Semua Laporan"
  List<TiketModel> get filteredAndSortedReports {
    List<TiketModel> result = List.from(_reports);

    // Apply Filter
    if (_selectedCategoryFilter != 'Semua') {
      result = result.where((t) => t.kategori.utama == _selectedCategoryFilter).toList();
    }

    // Apply Sort
    if (_selectedSort == 'Waktu Terbaru') {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Descending
    } else if (_selectedSort == 'Waktu Terlama') {
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Ascending
    } else if (_selectedSort == 'Urgensi Tertinggi') {
      result.sort((a, b) => b.jumlahVote.compareTo(a.jumlahVote)); // High to Low based on vote
    }

    return result;
  }

  // 3. Statistik Kategori
  int get sarprasCount => _reports.where((t) => t.kategori.utama == 'Sarpras').length;
  int get kebersihanCount => _reports.where((t) => t.kategori.utama == 'Kebersihan').length;

  double get sarprasPercentage {
    if (_reports.isEmpty) return 0;
    return (sarprasCount / _reports.length) * 100;
  }
  
  double get kebersihanPercentage {
    if (_reports.isEmpty) return 0;
    return (kebersihanCount / _reports.length) * 100;
  }

  // 4. Urgensi (Berdasarkan Vote)
  int get urgensiHigh => _reports.where((t) => t.jumlahVote >= 15).length;
  int get urgensiMedium => _reports.where((t) => t.jumlahVote >= 5 && t.jumlahVote < 15).length;
  int get urgensiLow => _reports.where((t) => t.jumlahVote < 5).length;

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final collection = MongoService().getCollection('tickets');
      final data = await collection.find().toList();
      _reports = data.map((json) => TiketModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("❌ Error fetchDashboardStats: $e");
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
