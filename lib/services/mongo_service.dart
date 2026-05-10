import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();
  factory MongoService() => _instance;
  MongoService._internal();

  Db? _db;

  Future<void> connect() async {
    if (_db != null && _db!.state == State.OPEN) {
      return;
    }

    int retryCount = 0;
    const int maxRetries = 2;

    while (retryCount <= maxRetries) {
      try {
        final connStr = dotenv.env['MONGO_URI'];
        if (connStr == null) throw Exception("MONGO_URI missing");

        if (kDebugMode) print("Connecting to MongoDB (Attempt ${retryCount + 1})...");

        // Tutup koneksi lama jika ada yang menggantung
        if (_db != null) {
          try { await _db!.close(); } catch (_) {}
        }

        _db = await Db.create(connStr);
        
        // Atlas connection often requires a longer connection timeout
        await _db!.open(secure: true).timeout(const Duration(seconds: 15));
        
        if (kDebugMode) print("✅ Connected to MongoDB");
        return;
      } catch (e) {
        retryCount++;
        if (kDebugMode) print("⚠️ Connection error: $e");
        
        if (retryCount > maxRetries) rethrow;
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
  }

  DbCollection getCollection(String collectionName) {
    if (_db == null || _db!.state != State.OPEN) {
      throw Exception('Database not connected');
    }
    return _db!.collection(collectionName);
  }

  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      await connect();
      return await getCollection('users').findOne(where.eq('email', email));
    } catch (e) {
      return null;
    }
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    await connect();
    await getCollection('users').insert(userData);
  }

  Future<void> close() async {
    if (_db != null) await _db!.close();
  }
}
