import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  String _selectedRole = 'Mahasiswa'; // Default role
  final _idController = TextEditingController(); // Bisa untuk NIM atau NIP
  
  // Variabel untuk menampung hasil deteksi otomatis
  String? _detectedAngkatan;
  String? _detectedProdi;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  // --- FUNGSI MAGIC: AUTO DETEKSI NIM ---
  void _analyzeNIM(String input) {
    if (_selectedRole != 'Mahasiswa') return;

    if (input.length >= 9) {
      // Ambil 2 digit pertama untuk Angkatan
      String kodeAngkatan = input.substring(0, 2);
      // Ambil 4 digit setelahnya untuk Prodi (contoh: 1511)
      String kodeProdi = input.substring(2, 6);

      setState(() {
        _detectedAngkatan = "20$kodeAngkatan"; // 24 jadi 2024

        // Kamus Kode Prodi Polban (Kamu bisa tambahkan kode prodi lain di sini)
        switch (kodeProdi) {
          case '1511':
            _detectedProdi = 'D3 Teknik Informatika';
            break;
          case '1514':
            _detectedProdi = 'D4 Teknik Informatika';
            break;
          // Tambahkan case lain sesuai kode jurusan Polban
          default:
            _detectedProdi = 'Prodi Kode: $kodeProdi';
        }
      });
    } else {
      // Bersihkan jika NIM kurang dari 9 digit
      setState(() {
        _detectedAngkatan = null;
        _detectedProdi = null;
      });
    }
  }

  Future<void> _saveProfile() async {
    // Validasi input
    if (_idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor Induk tidak boleh kosong!')),
      );
      return;
    }

    if (_selectedRole == 'Mahasiswa' && _idController.text.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NIM tidak valid (minimal 9 digit)!')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    try {
      // Panggil fungsi simpan (kita akan sedikit update parameternya di provider nanti)
      await authProvider.completeProfile(
        role: _selectedRole,
        identitas: _idController.text, // NIM atau NIP
        prodi: _detectedProdi ?? '-', // Kalau Dosen isinya '-'
        angkatan: _detectedAngkatan ?? '-', // Kalau Dosen isinya '-'
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(role: authProvider.role)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Lengkapi Profil'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Satu langkah lagi!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Pilih peran dan lengkapi datamu.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            // 1. Pilih Peran (Mahasiswa / Dosen)
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Mahasiswa', label: Text('Mahasiswa'), icon: Icon(Icons.face)),
                ButtonSegment(value: 'Dosen', label: Text('Dosen/Staf'), icon: Icon(Icons.work)),
              ],
              selected: {_selectedRole},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedRole = newSelection.first;
                  _idController.clear();
                  _detectedAngkatan = null;
                  _detectedProdi = null;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // 2. Input NIM atau NIP
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              onChanged: _analyzeNIM, // Memanggil fungsi auto-deteksi setiap ada ketikan
              decoration: InputDecoration(
                labelText: _selectedRole == 'Mahasiswa' ? 'Nomor Induk Mahasiswa (NIM)' : 'NIP / Nomor Pegawai',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.badge),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: 24),

            // 3. Tampilan Hasil Deteksi (Hanya muncul untuk Mahasiswa)
            if (_selectedRole == 'Mahasiswa' && _detectedAngkatan != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data Ditemukan:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 8),
                    Text('🎓 Program Studi: $_detectedProdi'),
                    Text('📅 Tahun Angkatan: $_detectedAngkatan'),
                  ],
                ),
              ),
            
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan & Lanjutkan', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}