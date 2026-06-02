import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/mongo_service.dart';
import '../models/tiket_model.dart';

class ReportFormProvider extends ChangeNotifier {
  String? _imagePath;
  String? _kategoriUtama;
  String? _kategoriJenis;
  String? _gedung;
  String _deskripsiLokasi = '';
  String _judul = '';
  String _deskripsi = '';

  String? get imagePath => _imagePath;
  String? get kategoriUtama => _kategoriUtama;
  String? get kategoriJenis => _kategoriJenis;
  String? get gedung => _gedung;
  String get deskripsiLokasi => _deskripsiLokasi;
  String get judul => _judul;
  String get deskripsi => _deskripsi;

  void setImagePath(String path) {
    _imagePath = path;
    notifyListeners();
  }

  void setKategoriUtama(String kat) {
    if (_kategoriUtama != kat) {
      _kategoriUtama = kat;
      _kategoriJenis = null;
      _judul = '';
      notifyListeners();
    }
  }

  void setKategoriJenis(String jenis) {
    if (_kategoriJenis != jenis) {
      _kategoriJenis = jenis;
      _judul = '';
      notifyListeners();
    }
  }

  void setGedung(String loc) {
    _gedung = loc;
    notifyListeners();
  }

  void setDeskripsiLokasi(String text) {
    _deskripsiLokasi = text;
    notifyListeners();
  }

  void setJudul(String text) {
    _judul = text;
    notifyListeners();
  }

  void setDeskripsi(String text) {
    _deskripsi = text;
    notifyListeners();
  }

  bool get isStep1Valid => _imagePath != null;
  bool get isStep2Valid => _gedung != null && _deskripsiLokasi.trim().isNotEmpty;
  bool get isStep3Valid =>
      _kategoriUtama != null &&
      _kategoriJenis != null &&
      _judul.trim().isNotEmpty;
  bool get isStep4Valid => _deskripsi.trim().isNotEmpty;
  bool get isAllValid =>
      isStep1Valid && isStep2Valid && isStep3Valid && isStep4Valid;

  void resetForm() {
    _imagePath = null;
    _kategoriUtama = null;
    _kategoriJenis = null;
    _gedung = null;
    _deskripsiLokasi = '';
    _judul = '';
    _deskripsi = '';
    notifyListeners();
  }

  Future<void> submitReport(String emailUser, String userId) async {
    if (!isAllValid) throw Exception("Form belum lengkap!");
    if (_judul.length < 5) throw Exception("Judul laporan minimal 5 karakter!");
    if (_deskripsi.length < 20)
      throw Exception(
        "Deskripsi laporan minimal 20 karakter! Mohon jelaskan lebih detail.",
      );

    final now = DateTime.now();

    final kategoriModel = KategoriModel(
      utama: _kategoriUtama == 'Sarana Prasarana'
          ? 'Sarpras'
          : _kategoriUtama ?? 'Lainnya',
      jenis: _kategoriJenis ?? 'Umum',
    );

    final lokasiModel = LokasiModel(
      gedung: _gedung ?? 'Tidak Diketahui',
      lantai: 0,
      ruangan: _deskripsiLokasi.isNotEmpty ? _deskripsiLokasi : 'Area Umum',
    );

    // Cek koneksi internet
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult.isNotEmpty && !connectivityResult.contains(ConnectivityResult.none);

    if (!isOnline) {
      final offlineData = {
        'localImagePath': _imagePath,
        'emailUser': emailUser,
        'userIdHex': userId,
        'judulSingkat': _judul,
        'deskripsiTiket': _deskripsi,
        'deskripsiLokasi': _deskripsiLokasi.isNotEmpty ? _deskripsiLokasi : null,
        'kategori': kategoriModel.toJson(),
        'lokasi': lokasiModel.toJson(),
        'timestamp': now.millisecondsSinceEpoch,
      };

      await HiveService().saveOfflineReport(offlineData);
      debugPrint("📴 Koneksi terputus. Laporan disimpan secara offline!");
      
      // Lemparkan exception khusus agar UI tahu bahwa ini offline
      throw Exception("OFFLINE_SAVED");
    }

    final idTiket =
        "TKT-${now.year}-${now.millisecondsSinceEpoch.toString().substring(5)}";

    String? imageUrl;
    if (_imagePath != null) {
      final bytes = File(_imagePath!).readAsBytesSync();
      final fileName = '$idTiket-${now.millisecondsSinceEpoch}.jpg';
          
      try {
        final supabase = Supabase.instance.client;
        
        // Upload gambar ke bucket 'tiket_images'
        await supabase.storage
            .from('tiket_images')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
            
        // Ambil Public URL agar bisa diakses oleh aplikasi
        imageUrl = supabase.storage
            .from('tiket_images')
            .getPublicUrl(fileName);
            
      } catch (e) {
        throw Exception("Supabase Storage Error: $e");
      }
    }

    ObjectId userObjectId;
    try {
      userObjectId = ObjectId.fromHexString(userId);
    } catch (e) {
      userObjectId = ObjectId.fromHexString('6672a1b4f3c3c3c3c3c3c3c1');
    }

    final tiketMap = {
      'idTiket': idTiket,
      'idUser': userObjectId,
      'emailUser': emailUser,
      'judulSingkat': _judul,
      'deskripsiTiket': _deskripsi,
      'deskripsiLokasi': _deskripsiLokasi.isNotEmpty ? _deskripsiLokasi : null,
      'kategori': kategoriModel.toJson(),
      'lokasi': lokasiModel.toJson(),
      'buktiVisual': imageUrl != null ? [imageUrl] : ["placeholder.jpg"],
      'status': 'Menunggu Verifikasi',
      'tanggalPembuatan': now,
      'tanggalPengajuan': now,
      'jumlahVote': 0,
      'comments': [],
      'createdAt': now,
      'updatedAt': now,
    };

    await MongoService().connect();
    final collection = MongoService().getCollection('tickets');
    await collection.insertOne(tiketMap);
    debugPrint("🚀 Tiket berhasil dikirim ke MongoDB: $idTiket");

    await NotificationService.notifyTicketCreatedToPenanggungJawab(
      ticketId: idTiket,
      ticketTitle: _judul,
      gedung: lokasiModel.gedung,
      createdAt: now,
    );
  }
}
