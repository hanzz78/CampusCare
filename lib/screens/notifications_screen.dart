import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification_model.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import 'report_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const double _notificationCardHeight = 118;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNotifications();
    });
  }

  Future<void> _refreshNotifications() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null || userId.isEmpty) return;
    await context.read<FeedProvider>().fetchNotifications(userId);
  }

  String _resolveTitle(NotificationModel item) {
    if (item.description.contains('dukungan')) return 'Dukungan Laporan';
    if (item.description.contains('komentar')) return 'Komentar Baru';
    if (item.description.contains('disetujui') || item.description.contains('ditolak')) {
      return 'Status Laporan';
    }
    return 'Notifikasi';
  }

  IconData _resolveIcon(NotificationModel item) {
    if (item.description.contains('dukungan')) return Icons.thumb_up_alt_rounded;
    if (item.description.contains('komentar')) return Icons.chat_bubble_rounded;
    if (item.description.contains('disetujui')) return Icons.verified_rounded;
    if (item.description.contains('ditolak')) return Icons.cancel_rounded;
    return Icons.notifications_active_rounded;
  }

  Color _resolveIconBg(NotificationModel item) {
    if (item.description.contains('dukungan')) return const Color(0xFFE8F4F8);
    if (item.description.contains('komentar')) return const Color(0xFFEFF4EA);
    if (item.description.contains('disetujui')) return const Color(0xFFE8F6ED);
    if (item.description.contains('ditolak')) return const Color(0xFFFBE9E9);
    return const Color(0xFFEEF1F3);
  }

  Color _resolveIconColor(NotificationModel item) {
    if (item.description.contains('dukungan')) return const Color(0xFF335C67);
    if (item.description.contains('komentar')) return const Color(0xFF4A6B2C);
    if (item.description.contains('disetujui')) return const Color(0xFF2E7D32);
    if (item.description.contains('ditolak')) return const Color(0xFFC62828);
    return const Color(0xFF546E7A);
  }

  Future<void> _openNotificationDetail(
    BuildContext context,
    FeedProvider feedProvider,
    NotificationModel item,
  ) async {
    if (item.id != null && !item.isRead) {
      await feedProvider.markNotificationAsRead(item.id!);
    }

    final report = feedProvider.getReportById(item.ticketId);
    if (!context.mounted) return;

    if (report != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportDetailScreen(report: report),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Laporan tidak ditemukan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final authProvider = context.watch<AuthProvider>();
    final notifications = feedProvider.dbNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A5256),
        elevation: 0,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: notifications.isEmpty
                ? null
                : () async {
                    final userId = authProvider.userId;
                    if (userId == null || userId.isEmpty) return;
                    await feedProvider.markAllNotificationsAsRead(userId);
                  },
            child: Text(
              'Tandai semua dibaca',
              style: TextStyle(
                color: notifications.isEmpty
                    ? Colors.white38
                    : const Color(0xFFFFF3B0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF335C67),
        onRefresh: _refreshNotifications,
        child: notifications.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Icon(
                      Icons.notifications_off_rounded,
                      size: 72,
                      color: Color(0xFFB0BEC5),
                    ),
                  ),
                  SizedBox(height: 14),
                  Center(
                    child: Text(
                      'Belum ada notifikasi.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6F8A90),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Notifikasi terbaru akan muncul di sini.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF90A4AE),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  final title = _resolveTitle(item);
                  final icon = _resolveIcon(item);
                  final iconBg = _resolveIconBg(item);
                  final iconColor = _resolveIconColor(item);

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openNotificationDetail(
                        context,
                        feedProvider,
                        item,
                      ),
                      child: SizedBox(
                        height: _notificationCardHeight,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isRead
                                  ? const Color(0xFFE1E8EA)
                                  : const Color(0xFFD6C88A),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: iconBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, size: 20, color: iconColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: item.isRead
                                                  ? const Color(0xFF35505A)
                                                  : const Color(0xFF17323B),
                                            ),
                                          ),
                                        ),
                                        if (!item.isRead)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Icon(
                                              Icons.circle,
                                              size: 10,
                                              color: Color(0xFFD32F2F),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF5D747B),
                                        height: 1.45,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      feedProvider.getTimeAgo(item.createdAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF90A4AE),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
