import 'package:flutter_test/flutter_test.dart';
import 'package:campuscare/providers/admin_dashboard_provider.dart';
import '../helpers/ticket_fixture.dart';

void main() {
  group('AdminDashboardProvider', () {
    AdminDashboardProvider makeProviderWithReports() {
      final provider = AdminDashboardProvider(autoFetch: false);
      final now = DateTime.now();

      provider.setReportsForTesting([
        makeTicket(
          idTiket: 'TKT-PENDING-SARPRAS',
          judulSingkat: 'Keran rusak',
          status: 'Menunggu Verifikasi',
          kategoriUtama: 'Sarpras',
          jumlahVote: 2,
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        makeTicket(
          idTiket: 'TKT-APPROVED-KEBERSIHAN',
          judulSingkat: 'Toilet kotor',
          status: 'Approved',
          kategoriUtama: 'Kebersihan',
          tingkatUrgensi: 'Prioritas Tinggi',
          jumlahVote: 4,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        makeTicket(
          idTiket: 'TKT-REJECTED-SARPRAS',
          judulSingkat: 'AC terlalu dingin',
          status: 'Rejected',
          kategoriUtama: 'Sarpras',
          tingkatUrgensi: 'Prioritas Rendah',
          jumlahVote: 20,
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        makeTicket(
          idTiket: 'TKT-DOCUMENTED-KEBERSIHAN',
          judulSingkat: 'Sampah menumpuk',
          status: 'Documented',
          kategoriUtama: 'Kebersihan',
          jumlahVote: 8,
          createdAt: now,
        ),
      ]);

      return provider;
    }

    test('menghitung ringkasan laporan untuk dashboard admin', () {
      final provider = makeProviderWithReports();

      expect(provider.totalLaporan, 4);
      expect(provider.belumDireview, 1);
      expect(provider.selesai, 3);
      expect(
        provider.laporanMasuk.map((ticket) => ticket.idTiket),
        ['TKT-PENDING-SARPRAS'],
      );
      expect(provider.sarprasCount, 2);
      expect(provider.kebersihanCount, 2);
      expect(provider.sarprasPercentage, 50);
      expect(provider.kebersihanPercentage, 50);
      expect(provider.urgensiHigh, 1);
      expect(provider.urgensiMedium, 1);
      expect(provider.urgensiLow, 2);
      expect(provider.chartMaxCount, greaterThanOrEqualTo(4));
    });

    test('filter default hanya menampilkan laporan menunggu verifikasi', () {
      final provider = makeProviderWithReports();

      final result = provider.filteredAndSortedReports;

      expect(result, hasLength(1));
      expect(result.single.status, 'Menunggu Verifikasi');
      expect(result.single.idTiket, 'TKT-PENDING-SARPRAS');
    });

    test('filter tab selesai dan status disetujui menampilkan laporan approved', () {
      final provider = makeProviderWithReports();

      provider
        ..setAdminActionTab('Selesai Direview')
        ..setAdminStatusFilter('Disetujui');

      final result = provider.filteredAndSortedReports;

      expect(result, hasLength(1));
      expect(result.single.idTiket, 'TKT-APPROVED-KEBERSIHAN');
      expect(result.single.status, 'Approved');
    });

    test('filter kategori bekerja setelah tab admin dipilih', () {
      final provider = makeProviderWithReports();

      provider
        ..setAdminActionTab('Selesai Direview')
        ..setCategoryFilter('Sarpras');

      final result = provider.filteredAndSortedReports;

      expect(result.map((ticket) => ticket.idTiket), ['TKT-REJECTED-SARPRAS']);
      expect(result.every((ticket) => ticket.kategori.utama == 'Sarpras'), isTrue);
    });

    test('sort waktu terbaru dan terlama mengurutkan laporan dengan benar', () {
      final provider = makeProviderWithReports();

      provider.setAdminActionTab('Semua');
      provider.setSort('Waktu Terbaru');

      expect(
        provider.filteredAndSortedReports.first.idTiket,
        'TKT-DOCUMENTED-KEBERSIHAN',
      );

      provider.setSort('Waktu Terlama');

      expect(
        provider.filteredAndSortedReports.first.idTiket,
        'TKT-PENDING-SARPRAS',
      );
    });

    test('sort urgensi tertinggi mengurutkan berdasarkan nilai prioritas provider', () {
      final provider = makeProviderWithReports();

      provider
        ..setAdminActionTab('Semua')
        ..setSort('Urgensi Tertinggi');

      final result = provider.filteredAndSortedReports
          .map((ticket) => ticket.idTiket)
          .toList();

      expect(result, [
        'TKT-APPROVED-KEBERSIHAN',
        'TKT-REJECTED-SARPRAS',
        'TKT-DOCUMENTED-KEBERSIHAN',
        'TKT-PENDING-SARPRAS',
      ]);
    });
  });
}