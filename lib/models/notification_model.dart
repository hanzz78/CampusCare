import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

class NotificationModel {
  final String? id; // MongoDB '_id'
  final String userId;
  final String ticketId;
  final String ticketTitle;
  final String description;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    this.id,
    required this.userId,
    required this.ticketId,
    required this.ticketTitle,
    required this.description,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _parseObjectId(json['_id']),
      userId: _parseObjectId(json['user_id']) ?? json['user_id']?.toString() ?? '',
      ticketId: json['ticket_id']?.toString() ?? '',
      ticketTitle: json['ticket_title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'user_id': userId,
      'ticket_id': ticketId,
      'ticket_title': ticketTitle,
      'description': description,
      'is_read': isRead,
      'created_at': createdAt,
    };
    if (id != null) {
      map['_id'] = id;
    }
    return map;
  }

  static String? _parseObjectId(dynamic value) {
    if (value == null) return null;
    if (value is ObjectId) return value.oid;
    final str = value.toString();
    if (str.startsWith('ObjectId("') && str.endsWith('")')) {
      return str.substring(10, str.length - 2);
    }
    return str;
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }
}
