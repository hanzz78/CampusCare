import 'package:flutter/material.dart';

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
}
