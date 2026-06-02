import 'package:flutter_test/flutter_test.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:campuscare/models/tiket_model.dart';

void main() {
  group('TiketModel', () {
    test('fromJson memetakan data MongoDB lengkap ke model aplikasi', () {
      final ticketObjectId = ObjectId.fromHexString('6672a1b4f3c3c3c3c3c3c3c1');
      final userObjectId = ObjectId.fromHexString('6672a1b4f3c3c3c3c3c3c3c2');
      final adminObjectId = ObjectId.fromHexString('6672a1b4f3c3c3c3c3c3c3c3');
      final commentObjectId = ObjectId.fromHexString('6672a1b4f3c3c3c3c3c3c3c4');
      final createdAt = DateTime(2026, 6, 1, 8, 30);

      final ticket = TiketModel.fromJson({
        '_id': ticketObjectId,
        'idTiket': 'TKT-2026-12345',
        'idUser': userObjectId,
        'emailUser': 'mahasiswa@polban.ac.id',
        'judulSingkat': 'Lampu koridor mati',
        'deskripsiTiket': 'Lampu koridor gedung JTK lantai dua mati sejak pagi.',
        'deskripsiLokasi': 'Dekat ruang dosen',
        'kategori': {'utama': 'Sarpras', 'jenis': 'Listrik'},
        'lokasi': {'gedung': 'Gedung JTK', 'lantai': 2, 'ruangan': 'Koridor'},
        'buktiVisual': ['https://example.com/lampu.jpg'],
        'status': 'Approved',
        'tingkatUrgensi': 'Prioritas Tinggi',
        'tanggalPembuatan': createdAt.toIso8601String(),
        'tanggalPengajuan': createdAt,
        'tanggalVerifikasi': DateTime(2026, 6, 1, 9, 0).toIso8601String(),
        'tanggalApproval': DateTime(2026, 6, 1, 9, 10),
        'catatanPJ': 'Segera ditindaklanjuti teknisi.',
        'idPenanggungJawab': adminObjectId,
        'jumlahVote': 12,
        'comments': [
          {
            '_id': commentObjectId,
            'idUser': userObjectId,
            'emailUser': 'komentator@polban.ac.id',
            'content': 'Saya juga melihat lampunya mati.',
            'tanggalKomentar': DateTime(2026, 6, 1, 8, 45).toIso8601String(),
            'isDeleted': false,
            'profileImageUrl': 'https://example.com/profile.jpg',
          }
        ],
        'createdAt': createdAt,
        'updatedAt': DateTime(2026, 6, 1, 9, 10),
      });

      expect(ticket.id, ticketObjectId.toHexString());
      expect(ticket.idTiket, 'TKT-2026-12345');
      expect(ticket.idUser, userObjectId.toHexString());
      expect(ticket.emailUser, 'mahasiswa@polban.ac.id');
      expect(ticket.kategori.utama, 'Sarpras');
      expect(ticket.lokasi.gedung, 'Gedung JTK');
      expect(ticket.lokasi.lantai, 2);
      expect(ticket.status, 'Approved');
      expect(ticket.tingkatUrgensi, 'Prioritas Tinggi');
      expect(ticket.idPenanggungJawab, adminObjectId.toHexString());
      expect(ticket.jumlahVote, 12);
      expect(ticket.comments, hasLength(1));
      expect(ticket.comments.first.id, commentObjectId.toHexString());
      expect(ticket.lokasiDisplay, 'Gedung JTK, Lt 2 · Dekat ruang dosen');
    });

    test('fromJson memakai nilai default saat data opsional tidak tersedia', () {
      final ticket = TiketModel.fromJson({});

      expect(ticket.id, isNull);
      expect(ticket.idTiket, 'UNKNOWN');
      expect(ticket.idUser, '');
      expect(ticket.emailUser, '');
      expect(ticket.judulSingkat, 'Tanpa Judul');
      expect(ticket.status, 'Menunggu Verifikasi');
      expect(ticket.jumlahVote, 0);
      expect(ticket.comments, isEmpty);
      expect(ticket.kategori.utama, '');
      expect(ticket.lokasi.gedung, '');
      expect(ticket.lokasi.lantai, 0);
      expect(ticket.lokasiDisplay, '');
    });

    test('toJson menghasilkan struktur data yang siap disimpan atau dicache', () {
      final ticket = TiketModel(
        id: '6672a1b4f3c3c3c3c3c3c3c1',
        idTiket: 'TKT-2026-0001',
        idUser: '6672a1b4f3c3c3c3c3c3c3c2',
        emailUser: 'pelapor@polban.ac.id',
        judulSingkat: 'Sampah menumpuk',
        deskripsiTiket: 'Tempat sampah dekat kantin penuh dan perlu diangkut.',
        deskripsiLokasi: 'Dekat kantin',
        kategori: KategoriModel(utama: 'Kebersihan', jenis: 'Sampah'),
        lokasi: LokasiModel(gedung: 'Gedung JTK', lantai: 0, ruangan: 'Kantin'),
        buktiVisual: const ['foto.jpg'],
        status: 'Rejected',
        tingkatUrgensi: 'Prioritas Rendah',
        tanggalPembuatan: DateTime(2026, 6, 2, 8),
        tanggalPengajuan: DateTime(2026, 6, 2, 8, 5),
        tanggalRejection: DateTime(2026, 6, 2, 9),
        alasanRejection: 'Foto kurang jelas.',
        jumlahVote: 3,
        comments: const [],
        createdAt: DateTime(2026, 6, 2, 8),
        updatedAt: DateTime(2026, 6, 2, 9),
      );

      final json = ticket.toJson();

      expect(json['_id'], '6672a1b4f3c3c3c3c3c3c3c1');
      expect(json['idTiket'], 'TKT-2026-0001');
      expect(json['kategori'], {'utama': 'Kebersihan', 'jenis': 'Sampah'});
      expect(json['lokasi'], {'gedung': 'Gedung JTK', 'lantai': 0, 'ruangan': 'Kantin'});
      expect(json['buktiVisual'], ['foto.jpg']);
      expect(json['status'], 'Rejected');
      expect(json['tanggalRejection'], DateTime(2026, 6, 2, 9).toIso8601String());
      expect(json['alasanRejection'], 'Foto kurang jelas.');
    });
  });
}
