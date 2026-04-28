import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import 'login_screen.dart';


class DashboardScreen extends StatelessWidget {
  final String role;
  
  const DashboardScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusCare Polban'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Dialog konfirmasi sebelum keluar
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Keluar?'),
                  content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: user == null 
        ? const Center(child: Text('Tidak ada sesi.')) 
        : RefreshIndicator(
            onRefresh: () async {
              // Tarik ke bawah untuk refresh data (sementara dummy)
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. KARTU PROFIL REAL-TIME (Mengambil dari Firestore)
                  _buildProfileCard(user.uid),
                  
                  const SizedBox(height: 24),

                  // 2. MENU BERDASARKAN ROLE
                  Text(
                    'Menu Utama',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Menu Civitas (Mahasiswa/Dosen)
                  _buildMenuGrid([
                    _MenuData(icon: Icons.add_comment, title: 'Buat Laporan', color: Colors.blue),
                    _MenuData(icon: Icons.history, title: 'Riwayat Saya', color: Colors.orange),
                    _MenuData(icon: Icons.notifications, title: 'Pengumuman', color: Colors.purple),
                  ]),
                ],
              ),
            ),
          ),
    );
  }

  // --- WIDGET HELPER: KARTU PROFIL ---
  Widget _buildProfileCard(String uid) {
    return FutureBuilder<DocumentSnapshot>(
      // Kita gunakan FutureBuilder untuk mengambil data 1x saat halaman dibuka
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Card(
            child: ListTile(title: Text('Gagal memuat profil')),
          );
        }

        // Ekstrak data dari Firestore
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final nama = data['displayName'] ?? 'Pengguna';
        final idKampus = data['id_kampus'] ?? '-';
        final prodi = data['prodi'] ?? '-';

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 36, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role == 'Mahasiswa' ? 'NIM: $idKampus' : 'NIP: $idKampus',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (role == 'Mahasiswa')
                        Text(
                          prodi,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Lencana Role
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET HELPER: GRID MENU ---
  Widget _buildMenuGrid(List<_MenuData> menus) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return InkWell(
          onTap: () {
            // Nanti dihubungkan ke halaman masing-masing
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Membuka ${menu.title}...')));
          },
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade100,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(menu.icon, size: 40, color: menu.color),
                const SizedBox(height: 12),
                Text(
                  menu.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Class kecil untuk mempermudah pembuatan menu
class _MenuData {
  final IconData icon;
  final String title;
  final Color color;

  _MenuData({required this.icon, required this.title, required this.color});
}