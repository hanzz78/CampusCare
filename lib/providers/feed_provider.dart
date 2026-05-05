import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId, modify, where;
import '../models/tiket_model.dart';
import '../services/mongo_service.dart';

class FeedProvider extends ChangeNotifier {
  List<TiketModel> _reports = [];
  bool _isLoading = false;

  List<TiketModel> get reports => _reports;
  bool get isLoading => _isLoading;

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
    } catch (e) {
      debugPrint("❌ Error fetchReports: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> upvote(String idTiket, String userId, String emailUser) async {
    try {
      await MongoService().connect();
      final votesCol = MongoService().getCollection('votes');
      final ticketsCol = MongoService().getCollection('tickets');

      // Cek apakah user sudah pernah vote tiket ini
      final existingVote = await votesCol.findOne({
        'idTiket': idTiket,
        'idUser': ObjectId.fromHexString(userId)
      });

      if (existingVote != null) {
        throw Exception('Anda sudah memberikan dukungan pada laporan ini.');
      }

      // Tambahkan ke koleksi votes
      await votesCol.insert({
        'idTiket': idTiket,
        'idUser': ObjectId.fromHexString(userId),
        'emailUser': emailUser,
        'createdAt': DateTime.now()
      });

      // Tambahkan jumlahVote di koleksi tickets
      final updateResult = await ticketsCol.updateOne(
        where.eq('idTiket', idTiket),
        modify.inc('jumlahVote', 1)
      );

      if (updateResult.hasWriteErrors) {
        throw Exception(updateResult.writeError?.errmsg ?? 'Gagal menyimpan vote');
      }

      // Refresh data lokal
      await fetchReports();
    } catch (e) {
      debugPrint("Error upvote: $e");
      rethrow;
    }
  }

  Future<void> addComment(String idTiket, String content, String userId, String emailUser) async {
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
        modify.push('comments', newComment)
      );

      if (result.hasWriteErrors) {
        throw Exception(result.writeError?.errmsg ?? 'Gagal menyimpan ke database (Validation Error)');
      }

      // Refresh data lokal
      await fetchReports();
    } catch (e) {
      debugPrint("Error addComment: $e");
      rethrow;
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
