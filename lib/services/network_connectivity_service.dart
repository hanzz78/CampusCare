import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard_screen.dart';
import '../main.dart';
import 'hive_service.dart';
import 'mongo_service.dart';

class NetworkConnectivityService {
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  bool _isSyncing = false;

  void startListening() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        if (kDebugMode) {
          print('🌐 Network connected. Starting background sync...');
        }
        _syncOfflineReports();
      }
    });
    
    // Check initial connectivity and sync if online
    _connectivity.checkConnectivity().then((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        _syncOfflineReports();
      }
    });
  }

  Future<void> _syncOfflineReports() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final hiveService = HiveService();
      final offlineReports = hiveService.getOfflineReports();

      if (offlineReports.isEmpty) {
        _isSyncing = false;
        return;
      }

      if (kDebugMode) {
        print('🔄 Found ${offlineReports.length} offline reports. Syncing...');
      }

      bool hasSyncedAny = false;

      // Loop backwards so we can safely delete by index without shifting issues
      for (int i = offlineReports.length - 1; i >= 0; i--) {
        final reportData = offlineReports[i];
        try {
          await _processAndSubmitReport(reportData);
          await hiveService.deleteOfflineReport(i);
          hasSyncedAny = true;
          if (kDebugMode) {
            print('✅ Synced report $i successfully.');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error syncing report $i: $e');
          }
          // Do not delete, try again next time
        }
      }

      if (hasSyncedAny && navigatorKey.currentContext != null) {
        final context = navigatorKey.currentContext!;
        
        // Segarkan feed
        context.read<FeedProvider>().fetchReports();

        // Tampilkan SnackBar sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan offline berhasil disinkronkan ke server!'),
            backgroundColor: Color(0xFF3B696D), // Warna teal
          ),
        );

        // Pindah ke halaman Home dengan mereset DashboardScreen
        final auth = context.read<AuthProvider>();
        if (auth.isLoggedIn) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => DashboardScreen(role: auth.role)),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during background sync: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processAndSubmitReport(Map<String, dynamic> data) async {
    final int timestamp = data['timestamp'];
    final now = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final idTiket =
        "TKT-${now.year}-${now.millisecondsSinceEpoch.toString().substring(5)}";

    String? imageUrl;
    final String? localImagePath = data['localImagePath'];

    if (localImagePath != null) {
      final file = File(localImagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final fileName = '$idTiket-${now.millisecondsSinceEpoch}.jpg';

        try {
          final supabase = Supabase.instance.client;
          await supabase.storage.from('tiket_images').uploadBinary(
                fileName,
                bytes,
                fileOptions: const FileOptions(contentType: 'image/jpeg'),
              );
          imageUrl =
              supabase.storage.from('tiket_images').getPublicUrl(fileName);
        } catch (e) {
          throw Exception("Supabase Storage Error: $e");
        }
      }
    }

    ObjectId userObjectId;
    try {
      userObjectId = ObjectId.fromHexString(data['userIdHex']);
    } catch (e) {
      userObjectId = ObjectId.fromHexString('6672a1b4f3c3c3c3c3c3c3c1');
    }

    final tiketMap = {
      'idTiket': idTiket,
      'idUser': userObjectId,
      'emailUser': data['emailUser'],
      'judulSingkat': data['judulSingkat'],
      'deskripsiTiket': data['deskripsiTiket'],
      'deskripsiLokasi': data['deskripsiLokasi'],
      'kategori': data['kategori'],
      'lokasi': data['lokasi'],
      'buktiVisual': imageUrl != null ? [imageUrl] : ["placeholder.jpg"],
      'status': 'Menunggu Verifikasi',
      'tanggalPembuatan': now,
      'tanggalPengajuan': now,
      'jumlahVote': 0,
      'comments': [],
      'createdAt': now,
      'updatedAt': now,
    };

    // Ensure MongoService is connected
    await MongoService().connect();
    final collection = MongoService().getCollection('tickets');
    await collection.insertOne(tiketMap);
  }
}
