import 'package:flutter/material.dart';
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
      final collection = MongoService().getCollection('tickets');
      final data = await collection.find().toList();
      _reports = data.map((json) => TiketModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("❌ Error fetchReports: $e");
    }

    _isLoading = false;
    notifyListeners();
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
