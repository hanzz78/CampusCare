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

  String _selectedCategoryFilter = 'Semua';
  String _selectedSort = 'Waktu Terbaru';

  // New States for Action Segmentation
  String _adminActionTab =
      'Menunggu Tindakan'; // 'Menunggu Tindakan' or 'Selesai Direview'
  String _adminStatusFilter = 'Semua'; // 'Semua', 'Disetujui', 'Ditolak'

  String get selectedCategoryFilter => _selectedCategoryFilter;
  String get selectedSort => _selectedSort;
  String get adminActionTab => _adminActionTab;
  String get adminStatusFilter => _adminStatusFilter;

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

  void setAdminActionTab(String tab) {
    _adminActionTab = tab;
    notifyListeners();
  }

  void setAdminStatusFilter(String status) {
    _adminStatusFilter = status;
    notifyListeners();
  }

  int get totalLaporan => _reports.length;
  int get belumDireview =>
      _reports.where((t) => t.status == 'Menunggu Verifikasi').length;
  int get selesai => _reports
      .where(
        (t) =>
            t.status == 'Approved' ||
            t.status == 'Rejected' ||
            t.status == 'Documented',
      )
      .length;

  List<TiketModel> get laporanMasuk {
    return _reports.where((t) => t.status == 'Menunggu Verifikasi').toList();
  }

  List<TiketModel> get filteredAndSortedReports {
    List<TiketModel> result = List.from(_reports);

    // 1. Filter by Action Tab (Pending vs Reviewed)
    if (_adminActionTab == 'Menunggu Tindakan') {
      result = result.where((t) => t.status == 'Menunggu Verifikasi').toList();
    } else if (_adminActionTab == 'Selesai Direview') {
      result = result.where((t) => t.status != 'Menunggu Verifikasi').toList();

      // 2. Filter by Status (Approve vs Reject) ONLY if in Reviewed tab
      if (_adminStatusFilter == 'Disetujui') {
        result = result.where((t) => t.status == 'Approved').toList();
      } else if (_adminStatusFilter == 'Ditolak') {
        result = result.where((t) => t.status == 'Rejected').toList();
      }
    }

    // 3. Filter by Category
    if (_selectedCategoryFilter != 'Semua') {
      result = result
          .where((t) => t.kategori.utama == _selectedCategoryFilter)
          .toList();
    }

    if (_selectedSort == 'Waktu Terbaru') {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_selectedSort == 'Waktu Terlama') {
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_selectedSort == 'Urgensi Tertinggi') {
      result.sort((a, b) {
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

  int get sarprasCount =>
      _reports.where((t) => t.kategori.utama == 'Sarpras').length;
  int get kebersihanCount =>
      _reports.where((t) => t.kategori.utama == 'Kebersihan').length;

  double get sarprasPercentage =>
      _reports.isEmpty ? 0 : (sarprasCount / _reports.length) * 100;
  double get kebersihanPercentage =>
      _reports.isEmpty ? 0 : (kebersihanCount / _reports.length) * 100;

  int get urgensiHigh => _reports
      .where(
        (t) =>
            t.tingkatUrgensi == 'Prioritas Tinggi' ||
            (t.tingkatUrgensi == null && t.jumlahVote >= 15),
      )
      .length;
  int get urgensiMedium => _reports
      .where(
        (t) =>
            t.tingkatUrgensi == 'Prioritas Sedang' ||
            (t.tingkatUrgensi == null &&
                t.jumlahVote >= 5 &&
                t.jumlahVote < 15),
      )
      .length;
  int get urgensiLow => _reports
      .where(
        (t) =>
            t.tingkatUrgensi == 'Prioritas Rendah' ||
            (t.tingkatUrgensi == null && t.jumlahVote < 5),
      )
      .length;

  // Data laporan 7 hari terakhir untuk chart (X = hari, Y = jumlah laporan)
  List<DateTime> get chartLast7Days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List<DateTime>.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );
  }

  List<int> get chartLast7DaysCounts {
    final days = chartLast7Days;
    final counts = List<int>.filled(days.length, 0);

    for (final report in _reports) {
      final created = report.createdAt.toLocal();
      final reportDay = DateTime(created.year, created.month, created.day);
      final idx = days.indexOf(reportDay);
      if (idx != -1) {
        counts[idx] += 1;
      }
    }

    return counts;
  }

  int get chartMaxCount {
    final counts = chartLast7DaysCounts;
    final maxValue = counts.isEmpty
        ? 0
        : counts.reduce((a, b) => a > b ? a : b);
    return maxValue < 4 ? 4 : maxValue;
  }

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final collection = MongoService().getCollection('tickets');
      final data = await collection.find().toList();
      _reports = data.map((json) => TiketModel.fromJson(json)).toList();
      debugPrint("✅ Fetched ${_reports.length} reports");
    } catch (e) {
      debugPrint("❌ Error fetchDashboardStats: $e");
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // 5. Fungsi untuk Memproses Tiket (Approve/Reject)
  Future<void> processTicket(
    String mongoIdStr,
    String action, {
    required String adminId,
    String? urgency,
    String? rejectReason,
    String? pjNote,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final collection = MongoService().getCollection('tickets');
      final now = DateTime.now();

      final setMap = <String, dynamic>{
        'updatedAt': now,
        'tanggalVerifikasi': now,
        'status': action == 'Approve' ? 'Approved' : 'Rejected',
        'idPenanggungJawab': ObjectId.fromHexString(adminId),
      };

      if (urgency != null) {
        setMap['tingkatUrgensi'] = urgency;
      }

      if (action == 'Approve') {
        setMap['tanggalApproval'] = now;
        setMap['catatanPJ'] = (pjNote != null && pjNote.trim().isNotEmpty)
            ? pjNote.trim()
            : null;
      } else {
        setMap['tanggalRejection'] = now;
        setMap['alasanRejection'] =
            (rejectReason != null && rejectReason.trim().isNotEmpty)
            ? rejectReason.trim()
            : null;
      }

      final modifier = {'\$set': setMap};

      debugPrint("🚀 MODERN UPDATE for _id: $mongoIdStr with action: $action");

      // Gunakan modernUpdate() dengan positional arguments sesuai versi mongo_dart terbaru
      final result = await collection.modernUpdate(
        where.id(ObjectId.fromHexString(mongoIdStr)),
        modifier,
      );

      debugPrint(
        "📊 Modern Update Result OK: ${result['ok'] == 1.0 || result['ok'] == 1}",
      );

      if (result['ok'] != 1.0 && result['ok'] != 1) {
        debugPrint("❌ Update Failed: ${result['errmsg']}");
      } else {
        debugPrint("✅ Database Successfully Updated!");
        
        // ----------------------------------------------------
        // NOTIFICATION LOGIC (STATUS UPDATE)
        // ----------------------------------------------------
        final ticket = await collection.findOne(where.id(ObjectId.fromHexString(mongoIdStr)));
        if (ticket != null) {
          final notificationsCol = MongoService().getCollection('notifications');
          final statusStr = action == 'Approve' ? 'disetujui' : 'ditolak';
          try {
            final ticketOwnerId = ticket['idUser'];
            final cleanOwnerId = ticketOwnerId is ObjectId
                ? ticketOwnerId
                : ObjectId.fromHexString(
                    ticketOwnerId.toString().replaceAll('ObjectId("', '').replaceAll('")', ''),
                  );

            await notificationsCol.insertOne({
              'user_id': cleanOwnerId, // Pemilik tiket (ObjectId)
              'ticket_id': ticket['idTiket'], // ID tiket (String)
              'ticket_title': ticket['judulSingkat'] ?? '',
              'description': 'Laporan Anda "${ticket['judulSingkat']}" telah $statusStr oleh Penanggung Jawab.',
              'is_read': false,
              'created_at': DateTime.now(),
            });
            debugPrint("✅ Notifikasi status_update berhasil disimpan.");
          } catch (e) {
            debugPrint("❌ Error menyimpan notifikasi status_update: $e");
          }
        }
      }

      await fetchDashboardStats();
    } catch (e) {
      debugPrint("❌ Exception in processTicket: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
