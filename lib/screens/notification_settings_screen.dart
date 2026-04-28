import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _notifikasiBaru = true;
  bool _statusLaporan = true;
  bool _updateLaporan = true;
  bool _komentar = true;
  bool _upvote = false;
  bool _email = true;
  bool _push = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifikasiBaru = prefs.getBool('notif_baru') ?? true;
      _statusLaporan = prefs.getBool('notif_status') ?? true;
      _updateLaporan = prefs.getBool('notif_update') ?? true;
      _komentar = prefs.getBool('notif_komentar') ?? true;
      _upvote = prefs.getBool('notif_upvote') ?? false;
      _email = prefs.getBool('notif_email') ?? true;
      _push = prefs.getBool('notif_push') ?? true;
    });
  }

  Future<void> _saveNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_baru', _notifikasiBaru);
    await prefs.setBool('notif_status', _statusLaporan);
    await prefs.setBool('notif_update', _updateLaporan);
    await prefs.setBool('notif_komentar', _komentar);
    await prefs.setBool('notif_upvote', _upvote);
    await prefs.setBool('notif_email', _email);
    await prefs.setBool('notif_push', _push);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan notifikasi berhasil disimpan'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
          'Pengaturan Notifikasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Tipe Notifikasi
            _buildSectionHeader('Tipe Notifikasi'),
            const SizedBox(height: 12),
            _buildNotificationCard([
              _buildToggleItem(
                icon: Icons.note_add,
                title: 'Laporan Baru',
                subtitle: 'Notifikasi laporan baru dari pengguna lain',
                value: _notifikasiBaru,
                onChanged: (value) {
                  setState(() => _notifikasiBaru = value);
                },
              ),
              _buildDivider(),
              _buildToggleItem(
                icon: Icons.info_outline,
                title: 'Update Status Laporan',
                subtitle: 'Perubahan status laporan Anda diperbarui',
                value: _statusLaporan,
                onChanged: (value) {
                  setState(() => _statusLaporan = value);
                },
              ),
              _buildDivider(),
              _buildToggleItem(
                icon: Icons.edit_note,
                title: 'Update Laporan',
                subtitle: 'Pembaruan detail dari laporan yang sedang berlangsung',
                value: _updateLaporan,
                onChanged: (value) {
                  setState(() => _updateLaporan = value);
                },
              ),
              _buildDivider(),
              _buildToggleItem(
                icon: Icons.comment_outlined,
                title: 'Komentar Baru',
                subtitle: 'Komentar pada laporan Anda',
                value: _komentar,
                onChanged: (value) {
                  setState(() => _komentar = value);
                },
              ),
              _buildDivider(),
              _buildToggleItem(
                icon: Icons.thumb_up_outlined,
                title: 'Notifikasi Upvote',
                subtitle: 'Ketika laporan Anda mendapat upvote',
                value: _upvote,
                onChanged: (value) {
                  setState(() => _upvote = value);
                },
              ),
            ]),
            const SizedBox(height: 28),

            // Section: Saluran Notifikasi
            _buildSectionHeader('Saluran Notifikasi'),
            const SizedBox(height: 12),
            _buildNotificationCard([
              _buildToggleItem(
                icon: Icons.notifications_active,
                title: 'Notifikasi Push',
                subtitle: 'Terima notifikasi di perangkat Anda',
                value: _push,
                onChanged: (value) {
                  setState(() => _push = value);
                },
              ),
              _buildDivider(),
              _buildToggleItem(
                icon: Icons.mail_outline,
                title: 'Email',
                subtitle: 'Terima notifikasi melalui email',
                value: _email,
                onChanged: (value) {
                  setState(() => _email = value);
                },
              ),
            ]),
            const SizedBox(height: 28),

            // Info Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.shade200,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Anda tetap akan menerima notifikasi penting seperti peringatan keamanan meskipun notifikasi dimatikan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade700,
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
                onPressed: _saveNotificationSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B696D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Simpan Pengaturan',
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3B696D),
      ),
    );
  }

  Widget _buildNotificationCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF3B696D),
            activeTrackColor: const Color(0xFF3B696D).withOpacity(0.3),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 64,
      endIndent: 16,
      color: Colors.grey.shade300,
    );
  }
}
