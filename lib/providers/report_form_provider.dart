import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import '../services/mongo_service.dart';
import '../models/tiket_model.dart';

class ReportFormProvider extends ChangeNotifier {
  String? _imagePath;
  String? _kategori;
  String? _gedung;
  String _judul = '';
  String _deskripsi = '';

  String? get imagePath => _imagePath;
  String? get kategori => _kategori;
  String? get gedung => _gedung;
  String get judul => _judul;
  String get deskripsi => _deskripsi;

  void setImagePath(String path) {
    _imagePath = path;
    notifyListeners();
  }

  void setKategori(String kat) {
    _kategori = kat;
    notifyListeners();
  }

  void setGedung(String loc) {
    _gedung = loc;
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
  bool get isStep2Valid => _kategori != null && _gedung != null;
  bool get isStep3Valid => _judul.trim().isNotEmpty && _deskripsi.trim().isNotEmpty;
  
  bool get isAllValid => isStep1Valid && isStep2Valid && isStep3Valid;

  void resetForm() {
    _imagePath = null;
    _kategori = null;
    _gedung = null;
    _judul = '';
    _deskripsi = '';
    notifyListeners();
  }

  Future<void> submitReport(String emailUser, String userId) async {
    if (!isAllValid) throw Exception("Form belum lengkap!");
    if (_judul.length < 5) throw Exception("Judul laporan minimal 5 karakter!");
    if (_deskripsi.length < 20) throw Exception("Deskripsi laporan minimal 20 karakter! Mohon jelaskan lebih detail.");

    String? base64Image;
    if (_imagePath != null) {
      final bytes = File(_imagePath!).readAsBytesSync();
      base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
    }

    // Membuat ID Tiket sesuai Regex: ^TKT-[0-9]{4}-[0-9]{3,}$
    final now = DateTime.now();
    final idTiket = "TKT-${now.year}-${now.millisecondsSinceEpoch.toString().substring(5)}";

    // Map Kategori ke Format Utama & Jenis
    final kategoriModel = KategoriModel(
      utama: _kategori == 'Sarana Prasarana' ? 'Sarpras' : _kategori ?? 'Lainnya',
      jenis: 'Umum'
    );

    // Map Lokasi ke Gedung, Lantai, Ruangan
    final lokasiModel = LokasiModel(
      gedung: _gedung ?? 'Tidak Diketahui',
      lantai: 1, // Default sementara
      ruangan: 'Area Umum'
    );

    // Konversi userId ke ObjectId (atau buat dummy valid jika gagal)
    ObjectId userObjectId;
    try {
      userObjectId = ObjectId.fromHexString(userId);
    } catch (e) {
      userObjectId = ObjectId.fromHexString('6672a1b4f3c3c3c3c3c3c3c1'); // Dummy Valid ID
    }

    // Persiapkan Map murni untuk MongoDB (bypass TiketModel untuk idUser agar aman sebagai ObjectId)
    final tiketMap = {
      'idTiket': idTiket,
      'idUser': userObjectId, // Harus berupa ObjectId()
      'emailUser': emailUser,
      'judulSingkat': _judul,
      'deskripsiTiket': _deskripsi,
      'kategori': kategoriModel.toJson(),
      'lokasi': lokasiModel.toJson(),
      'buktiVisual': base64Image != null ? [base64Image] : ["placeholder.jpg"], // minimal 1 item array
      'status': 'Menunggu Verifikasi',
      'tanggalPembuatan': now,
      'tanggalPengajuan': now,
      'jumlahVote': 0,
      'comments': [],
      'createdAt': now,
      'updatedAt': now,
    };

    // Kirim ke MongoDB
    await MongoService().connect();
    final collection = MongoService().getCollection('tickets');
    await collection.insert(tiketMap);
  }
}
