import 'package:flutter/material.dart';
import '../models/tiket_model.dart';
import '../services/mongo_service.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId, where;

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
    return _reports.where((t) => t.status == 'Menunggu Verifikasi').toList();
  }

  // 2.b Daftar Filtered & Sorted untuk Tab "Semua Laporan"
  List<TiketModel> get filteredAndSortedReports {
    List<TiketModel> result = List.from(_reports);

    if (_selectedCategoryFilter != 'Semua') {
      result = result.where((t) => t.kategori.utama == _selectedCategoryFilter).toList();
    }

    if (_selectedSort == 'Waktu Terbaru') {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_selectedSort == 'Waktu Terlama') {
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_selectedSort == 'Urgensi Tertinggi') {
      result.sort((a, b) {
        // Prioritas manual lebih tinggi dari vote
        int getPriorityValue(TiketModel t) {
          if (t.tingkatUrgensi == 'Prioritas Tinggi') return 1000;
          if (t.tingkatUrgensi == 'Prioritas Sedang') return 500;
          if (t.tingkatUrgensi == 'Prioritas Rendah') return 100;
          return t.jumlahVote;
        }
        return getPriorityValue(b).compareTo(getPriorityValue(a));
      });
    }

    return result;
  }

  // 3. Statistik Kategori
  int get sarprasCount => _reports.where((t) => t.kategori.utama == 'Sarpras').length;
  int get kebersihanCount => _reports.where((t) => t.kategori.utama == 'Kebersihan').length;

  double get sarprasPercentage => _reports.isEmpty ? 0 : (sarprasCount / _reports.length) * 100;
  double get kebersihanPercentage => _reports.isEmpty ? 0 : (kebersihanCount / _reports.length) * 100;

  // 4. Urgensi (Berdasarkan Nilai Admin atau Vote)
  int get urgensiHigh => _reports.where((t) => t.tingkatUrgensi == 'Prioritas Tinggi' || (t.tingkatUrgensi == null && t.jumlahVote >= 15)).length;
  int get urgensiMedium => _reports.where((t) => t.tingkatUrgensi == 'Prioritas Sedang' || (t.tingkatUrgensi == null && t.jumlahVote >= 5 && t.jumlahVote < 15)).length;
  int get urgensiLow => _reports.where((t) => t.tingkatUrgensi == 'Prioritas Rendah' || (t.tingkatUrgensi == null && t.jumlahVote < 5)).length;

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

  // 5. Fungsi untuk Memproses Tiket (Approve/Reject)
  Future<void> processTicket(
      ObjectId ticketId, String action,
      {String? urgency, String? rejectReason, String? pjNote}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final collection = MongoService().getCollection('tickets');
      final now = DateTime.now();
      
      final setMap = <String, dynamic>{
        'updatedAt': now.toIso8601String(),
      };
      
      final modifier = <String, dynamic>{
        '\$set': setMap,
      };

      if (action == 'Approve') {
        setMap['status'] = 'Approved';
        setMap['tingkatUrgensi'] = urgency; // "Prioritas Tinggi", etc.
        setMap['tanggalVerifikasi'] = now.toIso8601String();
        setMap['tanggalApproval'] = now.toIso8601String();
        if (pjNote != null && pjNote.trim().isNotEmpty) {
          setMap['catatanPJ'] = pjNote.trim();
        }
      } else if (action == 'Reject') {
        setMap['status'] = 'Rejected';
        setMap['tanggalRejection'] = now.toIso8601String();
        if (rejectReason != null && rejectReason.trim().isNotEmpty) {
          setMap['alasanRejection'] = rejectReason.trim();
        }
      }

      await collection.updateOne(
        where.id(ticketId),
        modifier,
      );

      // Refresh list
      await fetchDashboardStats();
    } catch (e) {
      debugPrint("❌ Error processTicket: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
