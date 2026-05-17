import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId, modify, where;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/tiket_model.dart';
import '../services/mongo_service.dart';

class FeedProvider extends ChangeNotifier {
  List<TiketModel> _reports = [];
  bool _isLoading = false;
  int _userVoteCount = 0;
  int _userReportCount = 0;

  List<TiketModel> get reports => _reports;
  bool get isLoading => _isLoading;
  int get userVoteCount => _userVoteCount;
  int get userReportCount => _userReportCount;

  // Set berisi idTiket yang sudah di-vote oleh user saat ini
  final Set<String> _votedTicketIds = {};
  bool hasUserVoted(String idTiket) => _votedTicketIds.contains(idTiket);

  FeedProvider() {
    fetchReports();
  }

  Future<void> fetchReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      await MongoService().connect();
      final collection = MongoService().getCollection('tickets');
      final data = await collection.find().toList();
      _reports = data.map((json) => TiketModel.fromJson(json)).toList();

      // Simpan ke cache untuk offline mode
      try {
        final prefs = await SharedPreferences.getInstance();
        final String encodedData = jsonEncode(
          _reports.map((r) => r.toJson()).toList(),
        );
        await prefs.setString('cached_feed_reports', encodedData);
      } catch (e) {
        debugPrint("Error caching reports: $e");
      }
    } catch (e) {
      debugPrint("❌ Error fetchReports (loading from cache): $e");
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? cachedData = prefs.getString('cached_feed_reports');
        if (cachedData != null && cachedData.isNotEmpty) {
          final List<dynamic> decodedList = jsonDecode(cachedData);
          _reports = decodedList
              .map((json) => TiketModel.fromJson(json))
              .toList();
        }
      } catch (cacheError) {
        debugPrint("Error loading cached reports: $cacheError");
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Mengembalikan true jika upvote ditambahkan, false jika di-unvote
  Future<bool> upvote(String idTiket, String userId, String emailUser) async {
    try {
      await MongoService().connect();
      final votesCol = MongoService().getCollection('votes');
      final ticketsCol = MongoService().getCollection('tickets');

      // Cek apakah user sudah pernah vote tiket ini
      final existingVote = await votesCol.findOne({
        'idTiket': idTiket,
        'idUser': ObjectId.fromHexString(userId),
      });

      if (existingVote != null) {
        // UNVOTE LOGIC
        // Hapus dari koleksi votes
        await votesCol.deleteOne({'_id': existingVote['_id']});

        // Kurangi jumlahVote di koleksi tickets
        final updateResult = await ticketsCol.updateOne(
          where.eq('idTiket', idTiket),
          modify.inc('jumlahVote', -1),
        );

        if (updateResult.hasWriteErrors) {
          throw Exception(
            updateResult.writeError?.errmsg ?? 'Gagal menghapus vote',
          );
        }

        // Update local state
        _votedTicketIds.remove(idTiket);

        // Refresh data lokal
        await fetchReports();
        await fetchUserStats(userId);
        return false; // false = di-unvote
      }

      // UPVOTE LOGIC
      // Tambahkan ke koleksi votes
      await votesCol.insert({
        'idTiket': idTiket,
        'idUser': ObjectId.fromHexString(userId),
        'emailUser': emailUser,
        'createdAt': DateTime.now(),
      });

      // Tambahkan jumlahVote di koleksi tickets
      final updateResult = await ticketsCol.updateOne(
        where.eq('idTiket', idTiket),
        modify.inc('jumlahVote', 1),
      );

      if (updateResult.hasWriteErrors) {
        throw Exception(
          updateResult.writeError?.errmsg ?? 'Gagal menyimpan vote',
        );
      }

      // Update local state
      _votedTicketIds.add(idTiket);

      // Refresh data lokal
      await fetchReports();
      await fetchUserStats(userId);
      return true; // true = di-upvote
    } catch (e) {
      debugPrint("Error upvote: $e");
      rethrow;
    }
  }

  Future<void> addComment(
    String idTiket,
    String content,
    String userId,
    String emailUser,
  ) async {
    try {
      await MongoService().connect();
      final ticketsCol = MongoService().getCollection('tickets');

      final newComment = {
        '_id': ObjectId(),
        'idUser': ObjectId.fromHexString(userId),
        'emailUser': emailUser,
        'content': content,
        'tanggalKomentar': DateTime.now(),
        'isDeleted': false,
      };

      // Push komentar ke array comments di dalam dokumen tiket
      final result = await ticketsCol.updateOne(
        where.eq('idTiket', idTiket),
        modify.push('comments', newComment),
      );

      if (result.hasWriteErrors) {
        throw Exception(
          result.writeError?.errmsg ??
              'Gagal menyimpan ke database (Validation Error)',
        );
      }

      // Refresh data lokal
      await fetchReports();
    } catch (e) {
      debugPrint("Error addComment: $e");
      rethrow;
    }
  }

  Future<void> deleteComment(
    String idTiket,
    String commentId,
    String userId,
  ) async {
    try {
      await MongoService().connect();
      final ticketsCol = MongoService().getCollection('tickets');

      // Menggunakan pull untuk menghapus komentar spesifik berdasarkan id komentar dan id user
      final result = await ticketsCol.updateOne(
        where.eq('idTiket', idTiket),
        modify.pull('comments', {
          '_id': ObjectId.fromHexString(commentId),
          'idUser': ObjectId.fromHexString(userId),
        }),
      );

      if (result.hasWriteErrors) {
        throw Exception(
          result.writeError?.errmsg ?? 'Gagal menghapus komentar',
        );
      }

      // Refresh data lokal
      await fetchReports();
    } catch (e) {
      debugPrint("Error deleteComment: $e");
      rethrow;
    }
  }

  Future<void> fetchUserStats(String userId) async {
    if (userId.isEmpty) return;

    // Ambil data dari cache terlebih dahulu (untuk mode offline)
    final prefs = await SharedPreferences.getInstance();
    _userVoteCount = prefs.getInt('cached_vote_count_$userId') ?? 0;
    _userReportCount = prefs.getInt('cached_report_count_$userId') ?? 0;
    notifyListeners();

    try {
      await MongoService().connect();
      final votesCol = MongoService().getCollection('votes');
      final ticketsCol = MongoService().getCollection('tickets');

      _userVoteCount = await votesCol.count(
        where.eq('idUser', ObjectId.fromHexString(userId)),
      );
      _userReportCount = await ticketsCol.count(
        where.eq('idUser', ObjectId.fromHexString(userId)),
      );

      // Load semua idTiket yang sudah di-vote user ini
      final myVotes = await votesCol
          .find(where.eq('idUser', ObjectId.fromHexString(userId)))
          .toList();
      _votedTicketIds.clear();
      for (final v in myVotes) {
        if (v['idTiket'] != null) _votedTicketIds.add(v['idTiket'].toString());
      }

      // Simpan ke cache agar bisa dibaca saat offline nanti
      await prefs.setInt('cached_vote_count_$userId', _userVoteCount);
      await prefs.setInt('cached_report_count_$userId', _userReportCount);

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error fetchUserStats (Using cached data): $e");
    }
  }

  String getTimeAgo(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return '${difference.inDays} hari yang lalu';
    }
  }
}
