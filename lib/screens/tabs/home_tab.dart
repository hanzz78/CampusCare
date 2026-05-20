import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/feed_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/tiket_model.dart';
import '../report_detail_screen.dart';
import '../report_history_screen.dart';
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
  final Set<String> _readNotificationKeys = <String>{};

  static const String _prefKey = 'read_notification_keys';

  @override
  void initState() {
    super.initState();
    _loadReadKeys();
  }

  Future<void> _loadReadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefKey) ?? [];
    setState(() {
      _readNotificationKeys.addAll(saved);
    });
  }

  Future<void> _saveReadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _readNotificationKeys.toList());
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

  List<_HomeNotification> _buildNotifications(
    List<TiketModel> reports, {
    String? currentUserId,
    String? currentEmail,
  }) {
    final items = <_HomeNotification>[];

    for (final report in reports) {
      final isMine =
          (currentUserId != null &&
              currentUserId.isNotEmpty &&
              report.idUser == currentUserId) ||
          (currentEmail != null &&
              currentEmail.isNotEmpty &&
              report.emailUser == currentEmail);
      if (!isMine) {
        continue;
      }

      if (report.jumlahVote > 0) {
        items.add(
          _HomeNotification(
            key:
                'dukungan-${report.idTiket}-${report.updatedAt.millisecondsSinceEpoch}',
            title: 'Laporanmu mendapat dukungan',
            subtitle: report.judulSingkat,
            report: report,
            createdAt: report.updatedAt,
          ),
        );
      }

      if (report.status == 'Approved') {
        items.add(
          _HomeNotification(
            key:
                'approved-${report.idTiket}-${(report.tanggalApproval ?? report.updatedAt).millisecondsSinceEpoch}',
            title: 'Laporan anda telah disetujui',
            subtitle: report.judulSingkat,
            report: report,
            createdAt: report.tanggalApproval ?? report.updatedAt,
          ),
        );
      }

      if (report.status == 'Rejected') {
        items.add(
          _HomeNotification(
            key:
                'rejected-${report.idTiket}-${(report.tanggalRejection ?? report.updatedAt).millisecondsSinceEpoch}',
            title: 'Laporan anda telah ditolak',
            subtitle: report.judulSingkat,
            report: report,
            createdAt: report.tanggalRejection ?? report.updatedAt,
          ),
        );
      }

      // Notifikasi komentar baru dari orang lain pada laporan milik user
      for (final comment in report.comments) {
        final isOwnComment =
            (currentUserId != null &&
                currentUserId.isNotEmpty &&
                comment.idUser == currentUserId) ||
            (currentEmail != null &&
                currentEmail.isNotEmpty &&
                comment.emailUser == currentEmail);
        if (isOwnComment || comment.isDeleted) continue;

        final commentKey =
            'komentar-${report.idTiket}-${comment.id ?? comment.tanggalKomentar.millisecondsSinceEpoch}';
        items.add(
          _HomeNotification(
            key: commentKey,
            title: 'Ada komentar baru di laporanmu',
            subtitle: report.judulSingkat,
            report: report,
            createdAt: comment.tanggalKomentar,
          ),
        );
      }
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(15).toList();
  }

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
    final notifications = _buildNotifications(
      feedProvider.reports,
      currentUserId: authProvider.userId,
      currentEmail: authProvider.email,
    );
    final hasUnreadNotifications = notifications.any(
      (n) => !_readNotificationKeys.contains(n.key),
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
                                    setState(() {
                                      _readNotificationKeys.addAll(
                                        notifications.map((n) => n.key),
                                      );
                                    });
                                    await _saveReadKeys();
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
                        constraints: const BoxConstraints(maxHeight: 175),
                        child: ListView.separated(
                          primary: false,
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final item = notifications[index];
                            final isRead = _readNotificationKeys.contains(
                              item.key,
                            );
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _readNotificationKeys.add(item.key);
                                  _showNotifications = false;
                                });
                                _saveReadKeys();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReportDetailScreen(
                                      report: item.report,
                                    ),
                                  ),
                                );
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
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0F2B33),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            item.subtitle,
                                            maxLines: 1,
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

class _HomeNotification {
  final String key;
  final String title;
  final String subtitle;
  final TiketModel report;
  final DateTime createdAt;

  _HomeNotification({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.report,
    required this.createdAt,
  });
}
