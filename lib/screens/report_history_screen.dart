import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../models/tiket_model.dart';
import 'report_detail_screen.dart';

class ReportHistoryScreen extends StatelessWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    final userId = authProvider.userId ?? '';
    final myReports = feedProvider.reports.where((r) => r.idUser == userId).toList();

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
          'Riwayat Laporan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: myReports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.note_outlined,
                    size: 64,
                    color: Color(0xFFB2CCCE),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tidak ada laporan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF7A9BA0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myReports.length,
              itemBuilder: (context, index) {
                final report = myReports[index];
                return _buildReportCard(context, report, feedProvider);
              },
            ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    TiketModel report,
    FeedProvider feedProvider,
  ) {
    final isSarpras = report.kategori.utama == 'Sarpras';
    final color = isSarpras ? const Color(0xFF2A5256) : const Color(0xFFE69B3A);
    final statusColor = _getStatusColor(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportDetailScreen(report: report),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail Image
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      image: report.buktiVisual.isNotEmpty && report.buktiVisual.first != 'placeholder.jpg'
                        ? DecorationImage(
                            image: NetworkImage(report.buktiVisual.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                    ),
                    child: (report.buktiVisual.isEmpty || report.buktiVisual.first == 'placeholder.jpg')
                      ? Icon(isSarpras ? Icons.build_circle_outlined : Icons.clean_hands_outlined, color: color, size: 30)
                      : null,
                  ),
                  const SizedBox(width: 16),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                report.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: statusColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Text(
                              feedProvider.getTimeAgo(report.createdAt),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF7A9BA0)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report.judulSingkat,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF2A5256),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF7A9BA0)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                report.lokasiDisplay,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF7A9BA0)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildMiniStat(Icons.arrow_upward_rounded, report.jumlahVote.toString(), Colors.red.shade400),
                            const SizedBox(width: 12),
                            _buildMiniStat(Icons.chat_bubble_outline_rounded, report.comments.length.toString(), const Color(0xFF7A9BA0)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7A9BA0)),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Menunggu Verifikasi':
        return const Color(0xFFF39C12);
      case 'Approved':
        return const Color(0xFF10B981);
      case 'Rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }
}
