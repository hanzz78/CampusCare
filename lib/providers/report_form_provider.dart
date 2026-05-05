import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
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
  bool get isStep2Valid => _gedung != null;
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

    String? base64Image;
    if (_imagePath != null) {
      final bytes = File(_imagePath!).readAsBytesSync();
      base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
    }

    final now = DateTime.now();
    final idTiket =
        "TKT-${now.year}-${now.millisecondsSinceEpoch.toString().substring(5)}";

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
      'buktiVisual': base64Image != null ? [base64Image] : ["placeholder.jpg"],
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
    await collection.insert(tiketMap);
  }
}
