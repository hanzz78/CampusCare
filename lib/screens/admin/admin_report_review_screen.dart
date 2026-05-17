import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../models/tiket_model.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/pdf_service.dart';

class AdminReportReviewScreen extends StatefulWidget {
  final TiketModel report;
  const AdminReportReviewScreen({super.key, required this.report});

  @override
  State<AdminReportReviewScreen> createState() => _AdminReportReviewScreenState();
}

class _AdminReportReviewScreenState extends State<AdminReportReviewScreen> {
  String _urgencyLevel = 'Prioritas Rendah';

  static const _teal = Color(0xFF2A5256);
  static const _tealMid = Color(0xFF335C67);
  static const _cream = Color(0xFFF8F3EC);

  @override
  void initState() {
    super.initState();
    if (widget.report.tingkatUrgensi != null) {
      _urgencyLevel = widget.report.tingkatUrgensi!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminDashboardProvider>();
    final feedProvider = context.watch<FeedProvider>();
    final report = provider.reports.firstWhere(
      (r) => r.idTiket == widget.report.idTiket,
      orElse: () => widget.report,
    );

    final isPending = report.status == 'Menunggu Verifikasi';
    final isApproved = report.status == 'Approved';
    final isSarpras = report.kategori.utama == 'Sarpras' || report.kategori.utama == 'Sarana Prasarana';
    final categoryLabel = isSarpras ? 'Sarana Prasarana' : 'Kebersihan';

    return Scaffold(
      backgroundColor: _cream,
      body: CustomScrollView(
        slivers: [
          // ── Hero SliverAppBar ──
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: _teal,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.45),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              if (isApproved)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.45),
                    child: IconButton(
                      icon: const Icon(Icons.print, color: Colors.white),
                      onPressed: () => _printPdf(report),
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  report.buktiVisual.isNotEmpty && report.buktiVisual.first != 'placeholder.jpg'
                      ? Image.network(report.buktiVisual.first, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image, size: 80, color: Colors.white54)))
                      : Container(color: Colors.grey.shade300, child: const Icon(Icons.image, size: 80, color: Colors.white54)),
                  // Bottom gradient
                  Positioned(bottom: 0, left: 0, right: 0, height: 80,
                    child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black54, Colors.transparent])))),
                  // Status badge
                  Positioned(bottom: 16, left: 16,
                    child: _statusBadge(report.status)),
                  // Category badge
                  Positioned(bottom: 16, right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSarpras ? _tealMid : const Color(0xFFE09F3E),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(categoryLabel, style: TextStyle(
                        color: isSarpras ? const Color(0xFFFFF3B0) : const Color(0xFF0F2B33),
                        fontSize: 12, fontWeight: FontWeight.bold)),
                    )),
                ],
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(report.judulSingkat, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F2B33), height: 1.25)),
                  const SizedBox(height: 10),
                  // Location & time
                  Row(children: [
                    const Icon(Icons.location_on_outlined, color: Color(0xFF9E2A2B), size: 15),
                    const SizedBox(width: 4),
                    Expanded(child: Text(report.lokasiDisplay, style: const TextStyle(fontSize: 13, color: Color(0xFF4D7277), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF7A9BA0)),
                    const SizedBox(width: 3),
                    Text(feedProvider.getTimeAgo(report.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFF7A9BA0))),
                  ]),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 20),

                  // Approved/Rejected result card
                  if (!isPending) ...[
                    _buildResultCard(report),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  const Text('Deskripsi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _tealMid)),
                  const SizedBox(height: 10),
                  Text(report.deskripsiTiket, style: const TextStyle(fontSize: 14, color: Color(0xFF3D5A5E), height: 1.65)),
                  const SizedBox(height: 28),

                  // Vote count (read-only)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _cream, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Icon(Icons.arrow_upward_rounded, color: Color(0xFF9E2A2B), size: 28),
                      const SizedBox(width: 12),
                      Text('${report.jumlahVote}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _teal)),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Civitas Akademika memberi dukungan untuk laporan ini', style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4))),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  // Urgency selector (only for pending)
                  if (isPending) ...[
                    const Text('Tentukan Tingkat Urgensi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _tealMid)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _urgencyCard('Prioritas Rendah', _tealMid, const Color(0xFFEBF0F0), const Color(0xFFB2CCCE))),
                      const SizedBox(width: 10),
                      Expanded(child: _urgencyCard('Prioritas Sedang', const Color(0xFFE09F3E), const Color(0xFFFFF8EC), const Color(0xFFFFE0A3))),
                      const SizedBox(width: 10),
                      Expanded(child: _urgencyCard('Prioritas Tinggi', const Color(0xFF9E2A2B), const Color(0xFFFFF0F0), const Color(0xFFFFCDD2))),
                    ]),
                    const SizedBox(height: 28),
                  ],

                  const Divider(color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 20),

                  // Comments
                  Text('Komentar (${report.comments.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _tealMid)),
                  const SizedBox(height: 16),
                  if (report.comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Belum ada komentar.', style: TextStyle(color: Color(0xFF7A9BA0), fontStyle: FontStyle.italic))),
                    ),
                  ...report.comments.map((c) => _buildCommentItem(c, feedProvider)),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Action Bar (pending only) ──
      bottomSheet: isPending
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _showRejectSheet(context),
                  icon: const Icon(Icons.close, color: Color(0xFF9E2A2B)),
                  label: const Text('Tolak', style: TextStyle(color: Color(0xFF9E2A2B), fontWeight: FontWeight.bold, fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Color(0xFF9E2A2B), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                )),
                const SizedBox(width: 14),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => _showApproveSheet(context),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Setuju', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A6B4B),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                )),
              ]),
            )
          : null,
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    if (status == 'Approved') { color = Colors.green; label = 'DISETUJUI'; }
    else if (status == 'Rejected') { color = Colors.red; label = 'DITOLAK'; }
    else { color = const Color(0xFFE09F3E); label = 'MENUNGGU REVIEW'; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }

  Widget _buildResultCard(TiketModel report) {
    final isApproved = report.status == 'Approved';
    final color = isApproved ? Colors.green : Colors.red;
    final note = isApproved ? report.catatanPJ : report.alasanRejection;
    final date = isApproved ? report.tanggalApproval : report.tanggalRejection;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isApproved ? Icons.check_circle : Icons.cancel, color: color, size: 20),
          const SizedBox(width: 8),
          Text(isApproved ? 'Laporan Disetujui' : 'Laporan Ditolak',
            style: TextStyle(fontWeight: FontWeight.bold, color: color.shade700)),
          if (date != null) ...[
            const Spacer(),
            Text(DateFormat('dd MMM yyyy').format(date), style: TextStyle(fontSize: 11, color: color.shade400)),
          ],
        ]),
        if (report.tingkatUrgensi != null && isApproved) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.priority_high, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text('Urgensi: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(report.tingkatUrgensi!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2A5256))),
          ]),
        ],
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Text(isApproved ? 'Catatan PJ:' : 'Alasan Penolakan:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(note ?? 'Tidak ada catatan.', style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
      ]),
    );
  }

  Widget _urgencyCard(String label, Color color, Color bg, Color border) {
    final selected = _urgencyLevel == label;
    final shortLabel = label.replaceAll('Prioritas ', '');
    return GestureDetector(
      onTap: () => setState(() => _urgencyLevel = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : border, width: selected ? 2 : 1),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (selected) Icon(Icons.check_circle, color: color, size: 18),
          Text(shortLabel, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? color : color.withOpacity(0.7))),
        ]),
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment, FeedProvider feedProvider) {
    final time = feedProvider.getTimeAgo(comment.tanggalKomentar);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F3EC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEAE3D9)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 14, backgroundColor: const Color(0xFF335C67).withOpacity(0.12),
              child: Text(comment.emailUser.isNotEmpty ? comment.emailUser[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF335C67)))),
            const SizedBox(width: 8),
            Expanded(child: Text('Pengguna', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF335C67)))),
            Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF7A9BA0))),
          ]),
          const SizedBox(height: 8),
          Text(comment.content, style: const TextStyle(fontSize: 13, color: Color(0xFF3D5A5E), height: 1.5)),
        ]),
      ),
    );
  }

  void _showApproveSheet(BuildContext context) {
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Catatan Persetujuan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2B33))),
            const SizedBox(height: 6),
            const Text('Tambahkan catatan untuk tim eksekusi (opsional)', style: TextStyle(fontSize: 13, color: Color(0xFF7A9BA0))),
            const SizedBox(height: 16),
            // Urgency summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFEBF0F0), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.priority_high, size: 16, color: Color(0xFF335C67)),
                const SizedBox(width: 8),
                Text('Urgensi dipilih: $_urgencyLevel', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF335C67))),
              ]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Catatan tambahan...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true, fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await context.read<AdminDashboardProvider>().processTicket(
                      widget.report.id!,
                      'Approve',
                      urgency: _urgencyLevel,
                      pjNote: noteCtrl.text,
                    );
                    if (!mounted) return;
                    _printPdf(widget.report);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil disetujui.')));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A5256),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Setujui & Cetak PDF', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showRejectSheet(BuildContext context) {
    final noteCtrl = TextEditingController();
    final reasons = ['Bukti foto tidak jelas', 'Lokasi tidak spesifik', 'Deskripsi tidak lengkap', 'Laporan duplikat', 'Di luar tanggung jawab', 'Tidak dapat diverifikasi'];
    String? selectedReason;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('Alasan Penolakan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2B33))),
                const SizedBox(height: 6),
                const Text('Pilih alasan atau tulis catatan tambahan', style: TextStyle(fontSize: 13, color: Color(0xFF7A9BA0))),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: reasons.map((r) {
                  final sel = selectedReason == r;
                  return GestureDetector(
                    onTap: () => setSheet(() => selectedReason = sel ? null : r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF9E2A2B).withOpacity(0.1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: sel ? const Color(0xFF9E2A2B) : Colors.grey.shade200, width: sel ? 1.5 : 1),
                      ),
                      child: Text(r, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? const Color(0xFF9E2A2B) : Colors.grey.shade700)),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 16),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Catatan tambahan (opsional)...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true, fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final finalReason = [if (selectedReason != null) selectedReason!, if (noteCtrl.text.trim().isNotEmpty) noteCtrl.text.trim()].join(' — ');
                      if (finalReason.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Pilih alasan atau tulis catatan penolakan!')));
                        return;
                      }
                      Navigator.pop(ctx);
                      try {
                        await context.read<AdminDashboardProvider>().processTicket(
                          widget.report.id!,
                          'Reject',
                          rejectReason: finalReason,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil ditolak.')));
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9E2A2B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Tolak Laporan', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _printPdf(TiketModel report) async {
    try {
      final bytes = await PdfService.generateReportPdf(report);
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'Laporan_${report.idTiket}.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal buat PDF: $e'), backgroundColor: Colors.red));
    }
  }
}
