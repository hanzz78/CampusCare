import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tiket_model.dart';
import '../providers/feed_provider.dart';
import '../screens/report_detail_screen.dart';

class ReportCard extends StatelessWidget {
  final TiketModel report;

  const ReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final isSarpras =
        report.kategori.utama == 'Sarpras' ||
        report.kategori.utama == 'Sarana Prasarana';
    final categoryLabel = isSarpras ? 'Sarana Prasarana' : 'Kebersihan';
    final lokasiStr = report.lokasiDisplay;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDetailScreen(report: report),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image and Badge
              Stack(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child:
                          report.buktiVisual.isNotEmpty &&
                              report.buktiVisual.first != 'placeholder.jpg'
                          ? Image.network(
                              report.buktiVisual.first,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF2A5256),
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  color: Colors.white54,
                                  size: 50,
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Category Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
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

              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      report.judulSingkat,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2B33),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Location + Time
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF7A9BA0),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lokasiStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A9BA0),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.read<FeedProvider>().getTimeAgo(report.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7A9BA0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      report.deskripsiTiket,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4D7277),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 12),

                    // Bottom Action Info (Upvote & Total Comments)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: Color(0xFF9E2A2B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${report.jumlahVote} Dukungan',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9E2A2B),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${report.comments.length} Komentar',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A9BA0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
