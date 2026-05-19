import 'package:flutter/material.dart';
import '../models/tiket_model.dart';
import '../providers/feed_provider.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ReportDetailScreen extends StatefulWidget {
  final TiketModel report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final authProvider = context.read<AuthProvider>();

    final updatedReport = feedProvider.reports.firstWhere(
      (r) => r.idTiket == widget.report.idTiket,
      orElse: () => widget.report,
    );

    final isSarpras =
        updatedReport.kategori.utama == 'Sarpras' ||
        updatedReport.kategori.utama == 'Sarana Prasarana';
    final categoryLabel = isSarpras ? 'Sarana Prasarana' : 'Kebersihan';
    final lokasiStr = updatedReport.lokasiDisplay;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EC),
      body: CustomScrollView(
        slivers: [
          // ─── Header Image ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240.0,
            pinned: true,
            backgroundColor: const Color(0xFF2A5256),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.45),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gambar
                  updatedReport.buktiVisual.isNotEmpty &&
                          updatedReport.buktiVisual.first != 'placeholder.jpg'
                      ? Image.network(
                          updatedReport.buktiVisual.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: const Color(0xFF2A5256),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 80,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.white54,
                            ),
                          ),
                        ),

                  // Gradient gelap di bawah agar badge terbaca
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                    ),
                  ),

                  // Badge kategori — pojok kanan bawah gambar (sesuai design)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSarpras
                            ? const Color(0xFF335C67)
                            : const Color(0xFFE09F3E),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        categoryLabel,
                        style: TextStyle(
                          color: isSarpras
                              ? const Color(0xFFFFF3B0)
                              : const Color(0xFF0F2B33),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Konten Putih ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  Text(
                    updatedReport.judulSingkat,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2B33),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Info row: lokasi · waktu
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF9E2A2B),
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lokasiStr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4D7277),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Color(0xFF7A9BA0),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        feedProvider.getTimeAgo(updatedReport.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A9BA0),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFF0F0F0), thickness: 1),
                  const SizedBox(height: 20),

                  // Info Status (Approved/Rejected)
                  if (updatedReport.status != 'Menunggu Verifikasi')
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: updatedReport.status == 'Approved'
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: updatedReport.status == 'Approved'
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                updatedReport.status == 'Approved'
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: updatedReport.status == 'Approved'
                                    ? Colors.green
                                    : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                updatedReport.status == 'Approved'
                                    ? 'Laporan Disetujui'
                                    : 'Laporan Ditolak',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: updatedReport.status == 'Approved'
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            updatedReport.status == 'Approved'
                                ? 'Catatan Penanggung Jawab:'
                                : 'Alasan Penolakan:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (updatedReport.status == 'Approved'
                                    ? updatedReport.catatanPJ
                                    : updatedReport.alasanRejection) ??
                                'Tidak ada catatan.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          if (updatedReport.tanggalVerifikasi != null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 4),
                            Text(
                              'Diverifikasi pada: ${updatedReport.tanggalVerifikasi!.toLocal().toString().split('.')[0]}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Deskripsi
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF335C67),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    updatedReport.deskripsiTiket,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3D5A5E),
                      height: 1.65,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Dukungan Civitas ──────────────────────────────────
                  if (updatedReport.status == 'Menunggu Verifikasi')
                    Builder(
                      builder: (context) {
                        final isVoted = feedProvider.hasUserVoted(
                          updatedReport.idTiket,
                        );
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F3EC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${updatedReport.jumlahVote}',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2A5256),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Civitas Akademika memberi dukungan untuk laporan anda',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () async {
                                  final userId = authProvider.userId;
                                  final email = authProvider.email;
                                  if (userId == null || email == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Anda harus login untuk memberikan dukungan!',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  try {
                                    await feedProvider.upvote(
                                      updatedReport.idTiket,
                                      userId,
                                      email,
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.toString().replaceAll(
                                              'Exception: ',
                                              '',
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isVoted
                                        ? const Color(0xFF9E2A2B)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isVoted
                                          ? const Color(0xFF9E2A2B)
                                          : const Color(0xFFD0C8BE),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward_rounded,
                                        size: 15,
                                        color: isVoted
                                            ? Colors.white
                                            : const Color(0xFF2A5256),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Dukung',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isVoted
                                              ? Colors.white
                                              : const Color(0xFF2A5256),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 28),
                  const Divider(color: Color(0xFFF0F0F0), thickness: 1),
                  const SizedBox(height: 20),

                  // ── Komentar ──────────────────────────────────────────
                  Text(
                    'Komentar (${updatedReport.comments.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF335C67),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (updatedReport.comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Belum ada komentar.',
                          style: TextStyle(
                            color: Color(0xFF7A9BA0),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),

                  ...updatedReport.comments.map((comment) {
                    return _buildCommentItem(
                      comment,
                      updatedReport.idTiket,
                      feedProvider,
                      authProvider.userId,
                    );
                  }),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom bar komentar ──────────────────────────────────────────
      bottomSheet: updatedReport.status == 'Menunggu Verifikasi'
          ? Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blueGrey.shade100,
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan komentar...',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _isSubmittingComment
                        ? null
                        : () async {
                            final content = _commentController.text.trim();
                            final userId = authProvider.userId;
                            final email = authProvider.email;

                            if (content.isEmpty) return;
                            if (content.length < 5) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Komentar minimal 5 karakter!'),
                                ),
                              );
                              return;
                            }
                            if (userId == null || email == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Anda harus login!'),
                                ),
                              );
                              return;
                            }

                            setState(() => _isSubmittingComment = true);

                            try {
                              await feedProvider.addComment(
                                updatedReport.idTiket,
                                content,
                                userId,
                                email,
                              );
                              _commentController.clear();
                              if (context.mounted) {
                                FocusScope.of(context).unfocus();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Gagal: ${e.toString().replaceAll("Exception: ", "")}',
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isSubmittingComment = false);
                              }
                            }
                          },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isSubmittingComment
                            ? Colors.grey
                            : const Color(0xFF3B696D),
                        shape: BoxShape.circle,
                      ),
                      child: _isSubmittingComment
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildCommentItem(
    CommentModel comment,
    String idTiket,
    FeedProvider feedProvider,
    String? currentUserId,
  ) {
    final time = feedProvider.getTimeAgo(comment.tanggalKomentar);
    final bool isMyComment =
        currentUserId != null && comment.idUser == currentUserId;

    // Tampilkan "Saya" untuk komentar milik current user; lainnya "Pengguna".
    final displayName = isMyComment ? 'Saya' : 'Pengguna';
    // Inisial dari email user (huruf pertama sebelum @), bukan dari label displayName
    final avatarInitial = comment.emailUser.isNotEmpty
        ? comment.emailUser[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: isMyComment
              ? const Color(0xFFF0F7F7)
              : const Color(0xFFF8F3EC),
          child: InkWell(
            // Long-press untuk hapus (hanya komentar milik sendiri)
            onLongPress: isMyComment && comment.id != null
                ? () => _showDeleteDialog(
                    comment,
                    idTiket,
                    feedProvider,
                    currentUserId,
                  )
                : null,
            splashColor: isMyComment
                ? const Color(0xFF335C67).withOpacity(0.12)
                : const Color(0xFFE09F3E).withOpacity(0.12),
            highlightColor: isMyComment
                ? const Color(0xFF335C67).withOpacity(0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isMyComment
                      ? const Color(0xFFB2D4D6)
                      : const Color(0xFFEAE3D9),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: const Color(
                          0xFF335C67,
                        ).withOpacity(0.12),
                        child: Text(
                          avatarInitial,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF335C67),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF0F2B33),
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Color(0xFF7A9BA0),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment.content,
                    style: const TextStyle(
                      color: Color(0xFF3D5A5E),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  // Hint hapus — hanya untuk komentar sendiri
                  if (isMyComment) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.touch_app_outlined,
                          size: 11,
                          color: Color(0xFF7A9BA0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tahan untuk menghapus',
                          style: TextStyle(
                            fontSize: 10,
                            color: const Color(0xFF7A9BA0).withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(
    CommentModel comment,
    String idTiket,
    FeedProvider feedProvider,
    String currentUserId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hapus Komentar?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Komentar ini akan dihapus secara permanen.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await feedProvider.deleteComment(
                            idTiket,
                            comment.id!,
                            currentUserId,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Komentar berhasil dihapus'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Gagal: ${e.toString().replaceAll("Exception: ", "")}',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
