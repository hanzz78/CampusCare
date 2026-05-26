import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum MongoConnectionState { connecting, connected, offline, error }

class MongoService {
  static final MongoService _instance = MongoService._internal();
  factory MongoService() => _instance;
  MongoService._internal();

  Db? _db;

  /// Observable connection status for UI binding
  final ValueNotifier<MongoConnectionState> connectionState = 
      ValueNotifier<MongoConnectionState>(MongoConnectionState.connecting);

  /// Completer that resolves when the first connection attempt finishes
  /// (either success or failure). UI can await this to know when to proceed.
  Completer<void>? _initialConnectionCompleter;

  /// Returns a Future that completes when the initial connection attempt is done.
  Future<void> get initialConnectionDone {
    return _initialConnectionCompleter?.future ?? Future.value();
  }

  Future<void> connect({bool isInitial = false}) async {
    if (isInitial && _initialConnectionCompleter == null) {
      _initialConnectionCompleter = Completer<void>();
    }
    if (_db != null && _db!.state == State.OPEN) {
      if (_db!.isConnected) {
        try {
          // Lakukan ping untuk memastikan koneksi masih aktif
          await _db!.pingCommand();
          return;
        } catch (e) {
          if (kDebugMode) print("Stale MongoDB connection. Reconnecting...");
          try { await _db!.close(); } catch (_) {}
          _db = null;
        }
      } else {
        try { await _db!.close(); } catch (_) {}
        _db = null;
      }
    }

    int retryCount = 0;
    const int maxRetries = 2;
    connectionState.value = MongoConnectionState.connecting;

    while (retryCount <= maxRetries) {
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.isEmpty || connectivityResult.first == ConnectivityResult.none) {
          throw Exception('NO_INTERNET');
        }

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
        connectionState.value = MongoConnectionState.connected;
        _completeInitial();
        return;
      } catch (e) {
        if (e.toString().contains('NO_INTERNET')) {
          if (kDebugMode) print("⚠️ Operating in offline mode.");
          connectionState.value = MongoConnectionState.offline;
          _completeInitial();
          rethrow; // Langsung gagal tanpa retry jika tidak ada internet
        }
        retryCount++;
        if (kDebugMode) print("⚠️ Connection error: $e");
        
        if (retryCount > maxRetries) {
          connectionState.value = MongoConnectionState.error;
          _completeInitial();
          rethrow;
        }
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
    await getCollection('users').insertOne(userData);
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await connect();
    final col = getCollection('users');
    final objectId = ObjectId.fromHexString(userId);
    
    var modifier = modify;
    data.forEach((key, value) {
      modifier = modifier.set(key, value);
    });
    
    await col.updateOne(where.eq('_id', objectId), modifier);
  }

  void _completeInitial() {
    if (_initialConnectionCompleter != null && !_initialConnectionCompleter!.isCompleted) {
      _initialConnectionCompleter!.complete();
    }
  }

  Future<void> close() async {
    if (_db != null) await _db!.close();
    connectionState.value = MongoConnectionState.offline;
  }
}
