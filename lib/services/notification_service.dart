import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId, where;

import 'mongo_service.dart';

class NotificationService {
  static Future<void> notifyTicketCreatedToPenanggungJawab({
    required String ticketId,
    required String ticketTitle,
    required String gedung,
    required DateTime createdAt,
  }) async {
    try {
      await MongoService().connect();
      final usersCol = MongoService().getCollection('users');
      final notificationsCol = MongoService().getCollection('notifications');

      final pjUsers = await usersCol.find(
        where.eq('role', 'Penanggung Jawab'),
      ).toList();

      if (pjUsers.isEmpty) {
        debugPrint('ℹ️ Tidak ada akun Penanggung Jawab yang ditemukan untuk notifikasi ticket baru.');
        return;
      }

      final description = 'Laporan baru masuk: $ticketTitle di $gedung';

      // Multi-document mode: 1 dokumen per PJ
      for (final pjUser in pjUsers) {
        final rawId = pjUser['_id'];
        final recipientId = rawId is ObjectId
            ? rawId
            : ObjectId.fromHexString(
                rawId.toString().replaceAll('ObjectId("', '').replaceAll('")', ''),
              );

        await notificationsCol.insertOne({
          'user_id': recipientId,
          'ticket_id': ticketId,
          'ticket_title': ticketTitle,
          'description': description,
          'is_read': false,
          'created_at': createdAt,
        });
      }

      debugPrint('✅ Notifikasi ticket baru berhasil dibuat dalam ${pjUsers.length} dokumen untuk ${pjUsers.length} akun Penanggung Jawab.');
    } catch (e) {
      debugPrint('❌ Error mengirim notifikasi ticket baru ke Penanggung Jawab: $e');
    }
  }
}