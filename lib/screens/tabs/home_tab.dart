import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/tiket_model.dart';
import '../../models/notification_model.dart';
import '../report_detail_screen.dart';
import '../../widgets/report_card.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _activeCategory = 'Semua';
  String _selectedSort = 'Terbaru';
  String _selectedMinDukungan = 'Semua';
  bool _showNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId != null) {
        context.read<FeedProvider>().fetchNotifications(authProvider.userId!);
      }
    });
  }

  List<TiketModel> _applyFilters(List<TiketModel> reports) {
    // Hanya tampilkan laporan yang masih "Menunggu Verifikasi" di halaman utama
    var result = reports
        .where((r) => r.status == 'Menunggu Verifikasi')
        .toList();

    if (_activeCategory == 'Sarana Prasarana') {
      result = result
          .where(
            (r) =>
                r.kategori.utama == 'Sarpras' ||
                r.kategori.utama == 'Sarana Prasarana',
          )
          .toList();
    } else if (_activeCategory == 'Kebersihan') {
      result = result.where((r) => r.kategori.utama == 'Kebersihan').toList();
    }

    if (_selectedMinDukungan == '10+ dukungan') {
      result = result.where((r) => r.jumlahVote >= 10).toList();
    } else if (_selectedMinDukungan == '20+ dukungan') {
      result = result.where((r) => r.jumlahVote >= 20).toList();
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_selectedSort == 'Terlama') {
      result = result.reversed.toList();
    }

    return result;
  }

  // Notifications are now fetched from the database collection.

  Future<void> _openFilterPanel() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.15),
      builder: (context) {
        String localSort = _selectedSort;
        String localMinDukungan = _selectedMinDukungan;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget optionRow({
              required String title,
              required bool selected,
              required VoidCallback onTap,
            }) {
              return InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0F2B33),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: selected
                            ? const Color(0xFF335C67)
                            : const Color(0xFFC9C2B6),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: EdgeInsets.only(
                        top: MediaQuery.paddingOf(context).top + 120,
                        right: 16,
                      ),
                      width: 210,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F2EB),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.65,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'URUTKAN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.2,
                                    color: Color(0xFF7D8E93),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                optionRow(
                                  title: 'Terbaru',
                                  selected: localSort == 'Terbaru',
                                  onTap: () {
                                    setDialogState(() {
                                      localSort = 'Terbaru';
                                    });
                                  },
                                ),
                                optionRow(
                                  title: 'Terlama',
                                  selected: localSort == 'Terlama',
                                  onTap: () {
                                    setDialogState(() {
                                      localSort = 'Terlama';
                                    });
                                  },
                                ),
                                const Divider(height: 18),
                                const Text(
                                  'MIN. DUKUNGAN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.2,
                                    color: Color(0xFF7D8E93),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                optionRow(
                                  title: 'Semua',
                                  selected: localMinDukungan == 'Semua',
                                  onTap: () {
                                    setDialogState(() {
                                      localMinDukungan = 'Semua';
                                    });
                                  },
                                ),
                                optionRow(
                                  title: '10+ dukungan',
                                  selected: localMinDukungan == '10+ dukungan',
                                  onTap: () {
                                    setDialogState(() {
                                      localMinDukungan = '10+ dukungan';
                                    });
                                  },
                                ),
                                optionRow(
                                  title: '20+ dukungan',
                                  selected: localMinDukungan == '20+ dukungan',
                                  onTap: () {
                                    setDialogState(() {
                                      localMinDukungan = '20+ dukungan';
                                    });
                                  },
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context, {
                                        'sort': localSort,
                                        'minDukungan': localMinDukungan,
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF335C67),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Terapkan'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedSort = result['sort'] ?? _selectedSort;
        _selectedMinDukungan = result['minDukungan'] ?? _selectedMinDukungan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final authProvider = context.watch<AuthProvider>();
    final reports = _applyFilters(feedProvider.reports);
    final List<NotificationModel> notifications = feedProvider.dbNotifications;
    final hasUnreadNotifications = notifications.any(
      (n) => !n.isRead,
    );

    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(hasUnreadNotifications),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Laporan Terkini',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F2B33),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openFilterPanel,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD6D0C5)),
                            foregroundColor: const Color(0xFF335C67),
                            backgroundColor: const Color(0xFFF5F2EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          icon: const Icon(Icons.filter_list, size: 16),
                          label: const Text(
                            'Filter',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTabChip('Semua'),
                          _buildTabChip('Sarana Prasarana'),
                          _buildTabChip('Kebersihan'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFF335C67),
                        onRefresh: () async {
                          await context.read<FeedProvider>().fetchReports();
                          final userId = context.read<AuthProvider>().userId;
                          if (userId != null) {
                            await context.read<FeedProvider>().fetchNotifications(userId);
                          }
                        },
                        child: reports.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.15,
                                  ),
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.assignment_turned_in_outlined,
                                          size: 64,
                                          color: const Color(0xFF6F8A90).withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Tidak ada laporan terbaru',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6F8A90),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(top: 0, bottom: 80),
                                itemCount: reports.length,
                                itemBuilder: (context, index) {
                                  return ReportCard(report: reports[index]);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_showNotifications)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _showNotifications = false;
                });
              },
              child: const SizedBox.expand(),
            ),
          ),
        if (_showNotifications)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 66,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD8DDE0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Notifikasi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6F8A90),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: notifications.isEmpty
                                ? null
                                : () async {
                                    final userId = authProvider.userId;
                                    if (userId != null) {
                                      await feedProvider.markAllNotificationsAsRead(userId);
                                    }
                                  },
                            child: Text(
                              'Mark all read',
                              style: TextStyle(
                                fontSize: 12,
                                color: notifications.isEmpty
                                    ? const Color(0xFFAAB5B9)
                                    : const Color(0xFF6F8A90),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'Belum ada notifikasi.',
                          style: TextStyle(
                            color: Color(0xFF6F8A90),
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          primary: false,
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final item = notifications[index];
                            final isRead = item.isRead;
                            
                            // Tentukan judul berdasarkan deskripsi notifikasi
                            String displayTitle = 'Notifikasi';
                            if (item.description.contains('dukungan')) {
                              displayTitle = 'Dukungan Laporan';
                            } else if (item.description.contains('komentar')) {
                              displayTitle = 'Komentar Baru';
                            } else if (item.description.contains('disetujui') || item.description.contains('ditolak')) {
                              displayTitle = 'Status Laporan';
                            }

                            return InkWell(
                              onTap: () async {
                                if (item.id != null) {
                                  await feedProvider.markNotificationAsRead(item.id!);
                                }
                                setState(() {
                                  _showNotifications = false;
                                });
                                final report = feedProvider.getReportById(item.ticketId);
                                if (report != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReportDetailScreen(
                                        report: report,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Laporan tidak ditemukan')),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  10,
                                  10,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayTitle,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0F2B33),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            item.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF6F8A90),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isRead) ...[
                                      const SizedBox(width: 10),
                                      const Icon(Icons.circle, size: 8, color: Color(0xFF4CAF50)),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(bool hasNotifications) {
    return Container(
      color: const Color(0xFF2A5256),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branding Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Campus',
                              style: TextStyle(
                                color: Color(0xFF9E2A2B),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            TextSpan(
                              text: 'Care',
                              style: TextStyle(
                                color: Color(0xFFE09F3E),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Layanan Pelaporan Terpadu',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showNotifications = !_showNotifications;
                            });
                          },
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                          ),
                        ),
                        if (hasNotifications)
                          const Positioned(
                            top: 10,
                            right: 10,
                            child: Icon(
                              Icons.circle,
                              size: 8,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String title) {
    final isActive = _activeCategory == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeCategory = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF335C67) : const Color(0xFFD5DBDE),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFFFFF3B0) : const Color(0xFF6F8A90),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// Removed _HomeNotification class as it is replaced by NotificationModel.
