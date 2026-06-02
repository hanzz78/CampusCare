import 'package:flutter_test/flutter_test.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:campuscare/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('fromJson memetakan notifikasi dari database', () {
      final notificationId = ObjectId.fromHexString('6672a1b4f3c3c3c3c3c3c3c1');
      final userId = ObjectId.fromHexString('6672a1b4f3c3c3c3c3c3c3c2');
      final createdAt = DateTime(2026, 6, 2, 10, 30);

      final notification = NotificationModel.fromJson({
        '_id': notificationId,
        'user_id': userId,
        'ticket_id': 'TKT-2026-0001',
        'ticket_title': 'Lampu koridor mati',
        'description': 'Laporan Anda disetujui.',
        'is_read': false,
        'created_at': createdAt.toIso8601String(),
      });

      expect(notification.id, notificationId.oid);
      expect(notification.userId, userId.oid);
      expect(notification.ticketId, 'TKT-2026-0001');
      expect(notification.ticketTitle, 'Lampu koridor mati');
      expect(notification.description, 'Laporan Anda disetujui.');
      expect(notification.isRead, isFalse);
      expect(notification.createdAt, createdAt);
    });

    test('toJson menjaga format field sesuai koleksi notifications', () {
      final createdAt = DateTime(2026, 6, 2, 11, 0);
      final notification = NotificationModel(
        id: '6672a1b4f3c3c3c3c3c3c3c1',
        userId: '6672a1b4f3c3c3c3c3c3c3c2',
        ticketId: 'TKT-2026-0002',
        ticketTitle: 'Toilet kotor',
        description: 'Laporan mendapatkan komentar baru.',
        isRead: true,
        createdAt: createdAt,
      );

      final json = notification.toJson();

      expect(json['_id'], '6672a1b4f3c3c3c3c3c3c3c1');
      expect(json['user_id'], '6672a1b4f3c3c3c3c3c3c3c2');
      expect(json['ticket_id'], 'TKT-2026-0002');
      expect(json['ticket_title'], 'Toilet kotor');
      expect(json['description'], 'Laporan mendapatkan komentar baru.');
      expect(json['is_read'], isTrue);
      expect(json['created_at'], createdAt);
    });

    test('fromJson menggunakan default aman untuk data kosong', () {
      final notification = NotificationModel.fromJson({});

      expect(notification.id, isNull);
      expect(notification.userId, '');
      expect(notification.ticketId, '');
      expect(notification.ticketTitle, '');
      expect(notification.description, '');
      expect(notification.isRead, isFalse);
      expect(notification.createdAt, isA<DateTime>());
    });
  });
}
