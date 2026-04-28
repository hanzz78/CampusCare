import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController = TextEditingController(text: authProvider.displayName ?? '');
    _emailController = TextEditingController(text: authProvider.email ?? '');
    _locationController = TextEditingController(text: 'Gedung D');
    _phoneController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B696D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Avatar Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3B696D),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFF3B696D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur ubah foto akan segera tersedia'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Ubah Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B696D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildFormSection(
              label: 'Nama Lengkap',
              controller: _nameController,
              icon: Icons.person,
              hint: 'Masukkan nama lengkap Anda',
            ),
            const SizedBox(height: 16),

            _buildFormSection(
              label: 'Email',
              controller: _emailController,
              icon: Icons.email,
              hint: 'Email tidak dapat diubah',
              enabled: false,
            ),
            const SizedBox(height: 16),

            _buildFormSection(
              label: 'Lokasi Kampus',
              controller: _locationController,
              icon: Icons.location_on,
              hint: 'Pilih lokasi kampus',
            ),
            const SizedBox(height: 16),

            _buildFormSection(
              label: 'Nomor Telepon',
              controller: _phoneController,
              icon: Icons.phone,
              hint: 'Masukkan nomor telepon Anda',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),

            // Info Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Beberapa informasi tidak dapat diubah karena terhubung dengan akun akademik Anda.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  _handleSaveProfile();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B696D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3B696D),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF3B696D),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _handleSaveProfile() {
    // Validasi
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama lengkap tidak boleh kosong'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show success dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Berhasil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Profil Anda telah berhasil diperbarui.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context); // Kembali ke profile tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B696D),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
