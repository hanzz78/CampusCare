import 'package:flutter/material.dart';
import '../models/tiket_model.dart';

class FeedProvider extends ChangeNotifier {
  List<TiketModel> _reports = [];

  List<TiketModel> get reports => _reports;

  FeedProvider() {
    _loadDummyData();
  }

  void _loadDummyData() {
    _reports = [
      TiketModel(
        id: '1',
        localId: '1',
        userId: 'u1',
        kategori: 'Sarana Prasarana',
        judul: 'AC Bocor',
        lokasiDetail: 'Gedung D, Lt 1 R.101',
        deskripsi: 'Ada ac bocor di deket tv, bahaya kena elektronik dan bikin lantai licin, tolong segera ditindaklanjuti',
        fotoPaths: ['dummy_ac'],
        jumlahUpvote: 20,
        statusTiket: 'SUBMITTED',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      TiketModel(
        id: '2',
        localId: '2',
        userId: 'u2',
        kategori: 'Sarana Prasarana',
        judul: 'Tembok Retak',
        lokasiDetail: 'Gedung C, Lt 2 R.204',
        deskripsi: 'Saya ingin melaporkan adanya kerusakan berupa retakan pada tembok di area Kelas. Retakan tersebut terlihat cukup jelas dan berpotensi membahayakan jika ti...',
        fotoPaths: ['dummy_tembok'],
        jumlahUpvote: 13,
        statusTiket: 'SUBMITTED',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      TiketModel(
        id: '3',
        localId: '3',
        userId: 'u3',
        kategori: 'Kebersihan',
        judul: 'Sampah Menumpuk',
        lokasiDetail: 'Gedung F, Pujasera',
        deskripsi: 'Saya ingin melaporkan adanya penumpukan sampah di area sekitar pujasera. Kondisi ini menimbulkan bau tidak sedap dan mengganggu kenyamanan pengu...',
        fotoPaths: ['dummy_sampah'],
        jumlahUpvote: 13,
        statusTiket: 'SUBMITTED',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
    ];
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
