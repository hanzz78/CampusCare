import 'package:flutter/material.dart';
import '../models/tiket_model.dart';
import '../providers/feed_provider.dart';
import 'package:provider/provider.dart';
import '../screens/report_detail_screen.dart';

class ReportCard extends StatelessWidget {
  final TiketModel report;

  const ReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.read<FeedProvider>();
    final isSarpras = report.kategori == 'Sarana Prasarana';

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
              // Dummy Image Placeholder
              Container(
                height: 150,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  // Jika ada URL foto asli:
                  // image: DecorationImage(image: NetworkImage(report.fotoPaths.first), fit: BoxFit.cover),
                ),
                child: const Center(
                  child: Icon(Icons.image, color: Colors.white54, size: 50),
                ),
              ),
              // Category Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSarpras ? const Color(0xFF2A5256) : const Color(0xFFE69B3A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.kategori,
                    style: const TextStyle(
                      color: Colors.white,
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
                // Location and Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          report.lokasiDetail,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    Text(
                      feedProvider.getTimeAgo(report.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Title
                Text(
                  report.judul,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A5256),
                  ),
                ),
                const SizedBox(height: 4),
                
                // Description
                Text(
                  report.deskripsi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey,
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
                        Icon(Icons.local_fire_department, size: 16, color: Colors.red.shade400),
                        const SizedBox(width: 4),
                        Text('${report.jumlahUpvote} Dukungan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade400)),
                      ],
                    ),
                    const Text('3 Komentar', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 12),
                
                // Top Comment
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 12, backgroundColor: Colors.blueGrey.shade100, child: const Text('S', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: const TextSpan(
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                          children: [
                            TextSpan(text: 'Siti Aminah ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: 'Tadi pagi saya juga hampir kepeleset di sana. Bahaya banget!'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Inline Comment Input
                Row(
                  children: [
                    CircleAvatar(radius: 14, backgroundColor: Colors.grey.shade300, child: const Icon(Icons.person, size: 16, color: Colors.white)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Tambahkan komentar...', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
