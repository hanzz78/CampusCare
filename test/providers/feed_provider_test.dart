import 'package:flutter_test/flutter_test.dart';
import 'package:campuscare/providers/feed_provider.dart';
import '../helpers/ticket_fixture.dart';

void main() {
  group('FeedProvider', () {
    test('getReportById mengembalikan laporan yang sesuai dari state lokal', () {
      final provider = FeedProvider(autoFetch: false);
      provider.setReportsForTesting([
        makeTicket(idTiket: 'TKT-2026-001', judulSingkat: 'Lampu mati'),
        makeTicket(idTiket: 'TKT-2026-002', judulSingkat: 'Sampah menumpuk'),
      ]);

      final report = provider.getReportById('TKT-2026-002');

      expect(report, isNotNull);
      expect(report!.judulSingkat, 'Sampah menumpuk');
      expect(provider.getReportById('TKT-TIDAK-ADA'), isNull);
    });

    test('hasUserVoted membaca daftar tiket yang sudah divote user', () {
      final provider = FeedProvider(autoFetch: false);
      provider.setVotedTicketIdsForTesting({'TKT-2026-001', 'TKT-2026-003'});

      expect(provider.hasUserVoted('TKT-2026-001'), isTrue);
      expect(provider.hasUserVoted('TKT-2026-002'), isFalse);
      expect(provider.hasUserVoted('TKT-2026-003'), isTrue);
    });

    test('getTimeAgo menampilkan selisih waktu dalam format feed', () {
      final provider = FeedProvider(autoFetch: false);

      expect(provider.getTimeAgo(DateTime.now().subtract(const Duration(minutes: 10))), '10 menit yang lalu');
      expect(provider.getTimeAgo(DateTime.now().subtract(const Duration(hours: 3))), '3 jam yang lalu');
      expect(provider.getTimeAgo(DateTime.now().subtract(const Duration(days: 2))), '2 hari yang lalu');
    });
  });
}
