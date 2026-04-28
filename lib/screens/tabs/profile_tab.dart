import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    // Fallback data if user is not fully loaded or we only have email
    final String email = authProvider.email ?? 'mahasiswa@polban.ac.id';
    final String name = authProvider.displayName ?? email.split('@')[0].toUpperCase();
    
    return Container(
      color: const Color(0xFF3B696D), // Latar belakang Teal untuk Header
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header: Avatar, Name, Role, Stats
            _buildHeader(name),
            const SizedBox(height: 24),
            // Konten Bawah (Lengkungan)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F3EC), // Warna Cream
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('My Reports'),
                      _buildMyReportsCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Account'),
                      _buildMenuCard([
                        _buildMenuRow(Icons.person, 'Edit Profile', onTap: () {}),
                      ]),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Preferences'),
                      _buildMenuCard([
                        _buildMenuRow(Icons.notifications_none, 'Pengaturan Notifikasi', onTap: () {}),
                        const Divider(height: 1, indent: 48),
                        _buildMenuRow(Icons.info_outline, 'Tentang Aplikasi', onTap: () {}),
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
                                title: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold)),
                                content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext); // Tutup dialog
                                      context.read<AuthProvider>().logout(); // Lakukan logout dengan context utama
                                      // Paksa pindah ke LoginScreen dan hapus semua stack layar
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                                        (route) => false,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE2BDBA),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Ya, Keluar', style: TextStyle(color: Color(0xFF8A2E2E), fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE2BDBA), // Merah pudar
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(color: Color(0xFF8A2E2E), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80), // Padding bawah untuk Bottom Nav
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            image: const DecorationImage(
              image: AssetImage('assets/images/google_logo.png'), // Placeholder image (harus ada, atau pakai Icon)
              fit: BoxFit.cover,
            ),
          ),
          child: const Icon(Icons.person, size: 50, color: Colors.grey), // Fallback jika asset belum ada
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Gedung D • Mahasiswa',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 20),
        // Stats Box
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('12', 'Pelaporan'),
                const VerticalDivider(color: Colors.white24, thickness: 1, width: 1, indent: 12, endIndent: 12),
                _buildStatItem('54', 'Dukungan'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Column(
        children: [
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7A9E9F)),
          ),
          if (title == 'My Reports')
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildMyReportsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _buildReportRow('AC Bocor', 'Sarana Prasarana • Gedung D', const Color(0xFF3B696D)),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildReportRow('Lantai Kotor', 'Kebersihan • Gedung D', const Color(0xFFE5A77A)),
        ],
      ),
    );
  }

  Widget _buildReportRow(String title, String subtitle, Color bulletColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: bulletColor, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuRow(IconData icon, String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF3B696D)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
