import 'package:flutter/material.dart';
import '../../models/tiket_model.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_dashboard_provider.dart';
import 'package:intl/intl.dart';

class AdminReportReviewScreen extends StatefulWidget {
  final TiketModel report;

  const AdminReportReviewScreen({super.key, required this.report});

  @override
  State<AdminReportReviewScreen> createState() => _AdminReportReviewScreenState();
}

class _AdminReportReviewScreenState extends State<AdminReportReviewScreen> {
  String _urgencyLevel = 'Prioritas Rendah';

  @override
  void initState() {
    super.initState();
    // Inisialisasi urgency level jika sudah ada di laporan
    if (widget.report.tingkatUrgensi != null) {
      _urgencyLevel = widget.report.tingkatUrgensi!;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data terbaru dari provider agar UI sinkron jika ada perubahan
    final provider = context.watch<AdminDashboardProvider>();
    final currentReport = provider.reports.firstWhere(
      (r) => r.idTiket == widget.report.idTiket,
      orElse: () => widget.report,
    );

    final isProcessed = currentReport.status != 'Menunggu Verifikasi';
    final isApproved = currentReport.status == 'Approved';
    final isRejected = currentReport.status == 'Rejected';

    final isSarpras = currentReport.kategori.utama == 'Sarpras';
    final lokasiStr = currentReport.lokasiDisplay;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Review Laporan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF3B696D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Badge
            if (isProcessed) _buildStatusHeader(currentReport),

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
                    currentReport.kategori.utama,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _formatDate(currentReport.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              currentReport.judulSingkat,
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
            
            // Image Evidence
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: currentReport.buktiVisual.isNotEmpty && currentReport.buktiVisual.first != 'placeholder.jpg'
                  ? Image.network(
                      currentReport.buktiVisual.first,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(Icons.broken_image, 'Gagal memuat gambar'),
                    )
                  : _buildImagePlaceholder(Icons.image_outlined, 'Tidak ada foto bukti'),
            ),
            const SizedBox(height: 24),

            // Description Section
            _buildSectionTitle('Deskripsi Laporan'),
            const SizedBox(height: 12),
            _buildContentCard(currentReport.deskripsiTiket),
            const SizedBox(height: 24),

            // CONDITIONAL UI: IF PROCESSED
            if (isProcessed) ...[
              const Divider(height: 40),
              _buildSectionTitle(isApproved ? 'Hasil Review (Setuju)' : 'Hasil Review (Ditolak)'),
              const SizedBox(height: 16),
              _buildProcessedResult(currentReport),
            ] 
            // CONDITIONAL UI: IF NOT PROCESSED
            else ...[
              _buildSectionTitle('Tentukan Tingkat Urgensi'),
              const SizedBox(height: 16),
              _buildPriorityButton('Prioritas Tinggi', Colors.red, Icons.whatshot),
              const SizedBox(height: 12),
              _buildPriorityButton('Prioritas Sedang', Colors.orange, Icons.warning_amber_rounded),
              const SizedBox(height: 12),
              _buildPriorityButton('Prioritas Rendah', Colors.green, Icons.low_priority),
              
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
                        side: const BorderSide(color: Colors.red, width: 2),
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
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(TiketModel report) {
    final bool isApproved = report.status == 'Approved';
    final Color color = isApproved ? Colors.green : Colors.red;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isApproved ? Icons.check_circle : Icons.cancel, color: color),
          const SizedBox(width: 12),
          Text(
            'Laporan ini telah ${isApproved ? "DISETUJUI" : "DITOLAK"}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessedResult(TiketModel report) {
    final bool isApproved = report.status == 'Approved';
    final date = isApproved ? report.tanggalApproval : report.tanggalRejection;
    final note = isApproved ? report.catatanPJ : report.alasanRejection;
    final String dateStr = date != null ? DateFormat('dd MMM yyyy, HH:mm').format(date) : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Waktu Eksekusi', dateStr, Icons.access_time),
          if (isApproved && report.tingkatUrgensi != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Tingkat Urgensi', report.tingkatUrgensi!, Icons.priority_high),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            isApproved ? 'Catatan Penanggung Jawab:' : 'Alasan Penolakan:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
          ),
          const SizedBox(height: 8),
          Text(
            note ?? (isApproved ? 'Tidak ada catatan' : 'Tidak ada alasan'),
            style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2A5256))),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2A5256)));
  }

  Widget _buildContentCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6)),
    );
  }

  Widget _buildImagePlaceholder(IconData icon, String label) {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.grey),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityButton(String label, Color color, IconData icon) {
    bool isSelected = _urgencyLevel == label;
    return InkWell(
      onTap: () => setState(() => _urgencyLevel = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)] : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: isSelected ? color : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tolak Laporan', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan alasan penolakan (minimal 10 karakter):'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Contoh: Laporan tidak valid atau sudah diperbaiki...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan penolakan minimal 10 karakter!')));
                  return;
                }
                
                try {
                  await context.read<AdminDashboardProvider>().processTicket(
                    widget.report.id!,
                    'Reject',
                    rejectReason: reason,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context); // Tutup dialog
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil ditolak.')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Setujui Laporan', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Laporan akan diteruskan. Tambahkan catatan untuk tim eksekusi (Opsional):'),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Catatan tambahan...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
              onPressed: () async {
                try {
                  await context.read<AdminDashboardProvider>().processTicket(
                    widget.report.id!,
                    'Approve',
                    urgency: _urgencyLevel,
                    pjNote: noteController.text,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context); // Tutup dialog approve
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Proses & Setujui', style: TextStyle(color: Colors.white)),
            ),
          ],
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
