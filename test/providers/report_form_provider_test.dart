import 'package:flutter_test/flutter_test.dart';
import 'package:campuscare/providers/report_form_provider.dart';

void main() {
  group('ReportFormProvider', () {
    test('validasi setiap step mengikuti alur pembuatan laporan', () {
      final provider = ReportFormProvider();

      expect(provider.isStep1Valid, isFalse);
      expect(provider.isStep2Valid, isFalse);
      expect(provider.isStep3Valid, isFalse);
      expect(provider.isStep4Valid, isFalse);
      expect(provider.isAllValid, isFalse);

      provider.setImagePath('/tmp/foto-laporan.jpg');
      expect(provider.isStep1Valid, isTrue);
      expect(provider.isAllValid, isFalse);

      provider.setGedung('Gedung JTK');
      provider.setDeskripsiLokasi('Toilet lantai 1');
      expect(provider.isStep2Valid, isTrue);

      provider.setKategoriUtama('Sarana Prasarana');
      provider.setKategoriJenis('Kerusakan Fasilitas');
      provider.setJudul('Keran toilet rusak');
      expect(provider.isStep3Valid, isTrue);

      provider.setDeskripsi('Keran toilet lantai satu bocor dan air terus mengalir.');
      expect(provider.isStep4Valid, isTrue);
      expect(provider.isAllValid, isTrue);
    });

    test('mengganti kategori utama mereset jenis kategori dan judul', () {
      final provider = ReportFormProvider();

      provider.setKategoriUtama('Sarana Prasarana');
      provider.setKategoriJenis('Kerusakan Fasilitas');
      provider.setJudul('Lampu kelas mati');

      provider.setKategoriUtama('Kebersihan');

      expect(provider.kategoriUtama, 'Kebersihan');
      expect(provider.kategoriJenis, isNull);
      expect(provider.judul, '');
    });

    test('mengganti jenis kategori mereset judul', () {
      final provider = ReportFormProvider();

      provider.setKategoriUtama('Kebersihan');
      provider.setKategoriJenis('Sampah');
      provider.setJudul('Sampah menumpuk');

      provider.setKategoriJenis('Toilet');

      expect(provider.kategoriJenis, 'Toilet');
      expect(provider.judul, '');
    });

    test('resetForm mengosongkan seluruh data laporan', () {
      final provider = ReportFormProvider();

      provider
        ..setImagePath('/tmp/foto.jpg')
        ..setGedung('Gedung JTK')
        ..setDeskripsiLokasi('Dekat lab')
        ..setKategoriUtama('Sarpras')
        ..setKategoriJenis('Listrik')
        ..setJudul('Lampu mati')
        ..setDeskripsi('Lampu mati dan perlu segera diperbaiki.');

      provider.resetForm();

      expect(provider.imagePath, isNull);
      expect(provider.gedung, isNull);
      expect(provider.deskripsiLokasi, '');
      expect(provider.kategoriUtama, isNull);
      expect(provider.kategoriJenis, isNull);
      expect(provider.judul, '');
      expect(provider.deskripsi, '');
      expect(provider.isAllValid, isFalse);
    });

    test('submitReport menolak form yang belum lengkap sebelum akses database', () async {
      final provider = ReportFormProvider();

      expect(
        provider.submitReport('pelapor@polban.ac.id', '6672a1b4f3c3c3c3c3c3c3c1'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Form belum lengkap'))),
      );
    });

    test('submitReport menolak judul yang terlalu pendek sebelum akses database', () async {
      final provider = ReportFormProvider();

      provider
        ..setImagePath('/tmp/foto.jpg')
        ..setGedung('Gedung JTK')
        ..setDeskripsiLokasi('Toilet lantai 1')
        ..setKategoriUtama('Sarana Prasarana')
        ..setKategoriJenis('Kerusakan Fasilitas')
        ..setJudul('Air')
        ..setDeskripsi('Keran toilet lantai satu bocor dan air terus mengalir.');

      expect(
        provider.submitReport('pelapor@polban.ac.id', '6672a1b4f3c3c3c3c3c3c3c1'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Judul laporan minimal 5 karakter'))),
      );
    });

    test('submitReport menolak deskripsi yang terlalu pendek sebelum akses database', () async {
      final provider = ReportFormProvider();

      provider
        ..setImagePath('/tmp/foto.jpg')
        ..setGedung('Gedung JTK')
        ..setDeskripsiLokasi('Toilet lantai 1')
        ..setKategoriUtama('Sarana Prasarana')
        ..setKategoriJenis('Kerusakan Fasilitas')
        ..setJudul('Keran toilet rusak')
        ..setDeskripsi('Terlalu pendek');

      expect(
        provider.submitReport('pelapor@polban.ac.id', '6672a1b4f3c3c3c3c3c3c3c1'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Deskripsi laporan minimal 20 karakter'))),
      );
    });
  });
}
