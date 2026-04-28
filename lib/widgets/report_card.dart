import 'package:flutter/material.dart';
import '../models/tiket_model.dart';
import '../providers/feed_provider.dart';
import 'package:provider/provider.dart';

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
                
                // Bottom Row (Upvote & Arrow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Upvote Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 14, color: Colors.red.shade400),
                          const SizedBox(width: 4),
                          Text(
                            '${report.jumlahUpvote} Dukungan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Arrow Icon
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
