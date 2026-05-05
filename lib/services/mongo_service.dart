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
      try {
        // Ping database untuk memastikan koneksi socket benar-benar masih hidup
        await _db!.serverStatus();
        return; // Sudah terkoneksi dan sehat
      } catch (e) {
        if (kDebugMode) {
          print("Koneksi MongoDB terputus (idle). Mencoba menyambung ulang...");
        }
        // Force cleanup
        try { await _db!.close(); } catch (_) {}
        _db = null;
      }
    }

    try {
      if (kDebugMode) {
        print("Mencoba menyambungkan ke MongoDB Atlas...");
      }
      
      final connStr = dotenv.env['MONGO_URI'];
      if (connStr == null || connStr.isEmpty) {
        throw Exception("MONGO_URI tidak ditemukan di file .env");
      }

      _db = await Db.create(connStr);
      await _db!.open();
      
      if (kDebugMode) {
        print("✅ Berhasil terhubung ke database MongoDB: aplikasi_pelaporan_terpadu");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Gagal terhubung ke MongoDB: $e");
      }
      rethrow;
    }
  }

  // Mengambil koleksi secara dinamis
  DbCollection getCollection(String collectionName) {
    if (_db == null || _db!.state != State.OPEN) {
      throw Exception('Database tidak terkoneksi. Panggil connect() terlebih dahulu.');
    }
    return _db!.collection(collectionName);
  }

  // Fungsi khusus untuk mengecek user
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      await connect();
      final usersCollection = getCollection('users');
      final user = await usersCollection.findOne(where.eq('email', email));
      return user;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error findUserByEmail: $e");
      }
      return null;
    }
  }

  // Fungsi untuk mendaftarkan user baru
  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      await connect();
      final usersCollection = getCollection('users');
      await usersCollection.insert(userData);
      if (kDebugMode) {
        print("✅ User berhasil ditambahkan ke MongoDB.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error createUser: $e");
      }
      rethrow;
    }
  }

  // Menutup koneksi (opsional dipanggil saat aplikasi mati)
  Future<void> close() async {
    if (_db != null && _db!.state == State.OPEN) {
      await _db!.close();
    }
  }
}
