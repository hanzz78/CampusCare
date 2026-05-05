import 'package:flutter/material.dart';
import '../../models/tiket_model.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_dashboard_provider.dart';

class AdminReportReviewScreen extends StatefulWidget {
  final TiketModel report;

  const AdminReportReviewScreen({super.key, required this.report});

  @override
  State<AdminReportReviewScreen> createState() => _AdminReportReviewScreenState();
}

class _AdminReportReviewScreenState extends State<AdminReportReviewScreen> {
  String _urgencyLevel = 'Low';

  @override
  Widget build(BuildContext context) {
    final isSarpras = widget.report.kategori.utama == 'Sarpras';
    final lokasiStr = widget.report.lokasiDisplay;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Review Laporan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF3B696D),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSarpras ? const Color(0xFF2A5256) : const Color(0xFFE69B3A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.report.kategori.utama,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _formatDate(widget.report.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              widget.report.judulSingkat,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2A5256)),
            ),
            const SizedBox(height: 12),
            
            // Location
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lokasiStr,
                    style: const TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Image Placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 50, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Foto Bukti: ${widget.report.buktiVisual.length} dilampirkan', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description
            const Text('Deskripsi Laporan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2A5256))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                widget.report.deskripsiTiket,
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
              ),
            ),
            const SizedBox(height: 32),

            // Urgency Setup
            const Text('Tentukan Tingkat Urgensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2A5256))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('High (Tinggi) 🔥', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    value: 'High',
                    groupValue: _urgencyLevel,
                    onChanged: (val) => setState(() => _urgencyLevel = val!),
                    activeColor: Colors.red,
                  ),
                  RadioListTile<String>(
                    title: const Text('Medium (Sedang) ⚠️', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    value: 'Medium',
                    groupValue: _urgencyLevel,
                    onChanged: (val) => setState(() => _urgencyLevel = val!),
                    activeColor: Colors.orange,
                  ),
                  RadioListTile<String>(
                    title: const Text('Low (Rendah) 🍃', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    value: 'Low',
                    groupValue: _urgencyLevel,
                    onChanged: (val) => setState(() => _urgencyLevel = val!),
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Tolak', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(context),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Setuju', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tolak Laporan', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Silakan masukkan alasan penolakan. (Wajib diisi)'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Alasan penolakan...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan penolakan tidak boleh kosong!')));
                  return;
                }
                // TODO: Eksekusi API Tolak
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(context); // Tutup layar detail
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil ditolak.')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Tolak Laporan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showApproveDialog(BuildContext context) {
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Setujui Laporan', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Laporan akan diteruskan ke tim eksekusi. Tambahkan catatan opsional jika diperlukan:'),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Catatan tambahan (Opsional)...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog approve
                _showSuccessDownloadDialog(context); // Buka dialog sukses
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Proses & Setujui', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text('Laporan Disetujui!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Dokumen instruksi kerja telah dibuat dan siap diteruskan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement Download PDF
                    Navigator.pop(context); // Tutup dialog
                    Navigator.pop(context); // Kembali ke list
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mendownload Dokumen...')));
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download Dokumen (.pdf)', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B696D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inDays > 0) return '${duration.inDays} hari lalu';
    if (duration.inHours > 0) return '${duration.inHours} jam lalu';
    return '${duration.inMinutes} menit lalu';
  }
}
