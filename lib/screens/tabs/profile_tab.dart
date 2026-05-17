import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../models/tiket_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../login_screen.dart';
import '../report_history_screen.dart';
import '../edit_profile_screen.dart';
import '../notification_settings_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  void initState() {
    super.initState();
    // Fetch user stats when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.userId != null) {
        context.read<FeedProvider>().fetchUserStats(auth.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final feedProvider = context.watch<FeedProvider>();

    // Fallback data if user is not fully loaded or we only have email
    final String email = authProvider.email ?? 'mahasiswa@polban.ac.id';
    final String name =
        authProvider.displayName ?? email.split('@')[0].toUpperCase();
    final String role = authProvider.role == 'Admin'
        ? 'Administrator'
        : 'Mahasiswa';

    // Filter laporan milik user ini saja (untuk daftar laporan yang mungkin tersisa offline)
    final userId = authProvider.userId ?? '';
    final myReports = feedProvider.reports
        .where((r) => r.idUser == userId)
        .toList();

    // Gunakan userReportCount yang sudah dicache untuk mode offline
    final String pelaporanCount = feedProvider.userReportCount.toString();

    return Container(
      color: const Color(0xFF2A5256), // Gunakan brand color Teal
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header: Avatar, Name, Role, Stats
            _buildHeader(
              context,
              name,
              role,
              pelaporanCount,
              feedProvider.userVoteCount.toString(),
            ),
            const SizedBox(height: 24),
            // Konten Bawah (Lengkungan)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F3EC), // Cream background matching design
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: RefreshIndicator(
                  color: const Color(0xFF3B696D),
                  onRefresh: () async {
                    final auth = context.read<AuthProvider>();
                    if (auth.userId != null) {
                      await context.read<FeedProvider>().fetchUserStats(
                        auth.userId!,
                      );
                    }
                    await context.read<FeedProvider>().fetchReports();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: Hive.box(
                            'offline_reports',
                          ).listenable(),
                          builder: (context, Box box, _) {
                            if (box.isEmpty) return const SizedBox.shrink();

                            final offlineReports = [];
                            for (int i = 0; i < box.length; i++) {
                              final data = box.getAt(i);
                              if (data is Map) {
                                offlineReports.add(data);
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  'Laporan Offline (Menunggu Sinyal)',
                                ),
                                _buildOfflineReportsCard(offlineReports),
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ReportHistoryScreen(),
                              ),
                            );
                          },
                          child: _buildSectionTitle('My Reports'),
                        ),
                        _buildMyReportsCard(myReports),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Account'),
                        _buildMenuCard([
                          _buildMenuRow(
                            Icons.person_outline_rounded,
                            'Edit Profile',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen(),
                                ),
                              );
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Preferences'),
                        _buildMenuCard([
                          _buildMenuRow(
                            Icons.notifications_none_rounded,
                            'Pengaturan Notifikasi',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationSettingsScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, indent: 48),
                          _buildMenuRow(
                            Icons.info_outline_rounded,
                            'Tentang Aplikasi',
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text(
                                    'Tentang CampusCare',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: const Text(
                                    'CampusCare v1.0.0\n\nAplikasi untuk melaporkan dan memantau sarana prasarana kampus.\n\n© 2026 CampusCare. Hak cipta dilindungi.',
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: const Text(
                                        'Tutup',
                                        style: TextStyle(
                                          color: Color(0xFF2A5256),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ]),
                        const SizedBox(height: 48),
                        // Tombol Sign Out
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text(
                                    'Konfirmasi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: const Text(
                                    'Apakah Anda yakin ingin keluar dari aplikasi?',
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: const Text(
                                        'Batal',
                                        style: TextStyle(color: Color(0xFF7A9BA0)),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(
                                          dialogContext,
                                        ); // Tutup dialog
                                        context.read<AuthProvider>().logout();
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade50,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Ya, Keluar',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDFB6B2),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: Color(0xFFC79E9A),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(
                                color: Color(0xFF9E2A2B),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ), // SingleChildScrollView
                ), // RefreshIndicator
              ), // Container
            ), // Expanded
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String name,
    String role,
    String pelaporanCount,
    String dukunganCount,
  ) {
    final profileImageUrl = context.watch<AuthProvider>().profileImageUrl;

    return Column(
      children: [
        // Avatar
        Container(
          width: 85,
          height: 85,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 4),
            image: profileImageUrl != null && profileImageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(profileImageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: profileImageUrl == null || profileImageUrl.isEmpty
              ? const Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: Color(0xFF2A5256),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            color: Color(0xFFFFF3B0),
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Polban • $role',
          style: const TextStyle(
            color: Color(0xFFD9CFA8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        // Stats Box
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(pelaporanCount, 'Pelaporan'),
                Container(
                  width: 1,
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
                _buildStatItem(dukunganCount, 'Dukungan'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              color: Color(0xFFFFF3B0),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD9CFA8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2A5256),
            ),
          ),
          if (title == 'My Reports')
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF7A9BA0),
              size: 14,
            ),
        ],
      ),
    );
  }

  Widget _buildMyReportsCard(List<TiketModel> reports) {
    if (reports.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.note_alt_outlined,
              color: const Color(0xFFB2CCCE),
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum ada laporan',
              style: TextStyle(color: Color(0xFF7A9BA0), fontSize: 14),
            ),
          ],
        ),
      );
    }

    final displayReports = reports.take(2).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD0D7D8)),
      ),
      child: Column(
        children: displayReports.asMap().entries.map((entry) {
          final index = entry.key;
          final report = entry.value;
          final isLast = index == displayReports.length - 1;

          return Column(
            children: [
              _buildReportRow(
                report.judulSingkat,
                '${report.kategori.utama} • ${report.lokasi.gedung}',
                report.kategori.utama == 'Sarpras'
                    ? const Color(0xFF2A5256)
                    : const Color(0xFFE69B3A),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: Colors.grey.shade100,
                  indent: 20,
                  endIndent: 20,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOfflineReportsCard(List<dynamic> reports) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: reports.asMap().entries.map((entry) {
          final index = entry.key;
          final report = entry.value as Map;
          final isLast = index == reports.length - 1;

          final kategoriUtama = report['kategori']?['utama'] ?? 'Lainnya';
          final gedung = report['lokasi']?['gedung'] ?? 'Tidak Diketahui';

          return Column(
            children: [
              _buildReportRow(
                report['judulSingkat'] ?? 'Tanpa Judul',
                '$kategoriUtama • $gedung',
                Colors.orange,
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: Colors.orange.shade200,
                  indent: 20,
                  endIndent: 20,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReportRow(String title, String subtitle, Color bulletColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: bulletColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF2A5256),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7A9BA0),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Hapus ikon panah di setiap item My Reports (tetap pertahankan panah pada judul)
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD0D7D8)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuRow(
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF2A5256)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF2A5256),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF7A9BA0),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
