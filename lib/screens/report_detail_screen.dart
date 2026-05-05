import 'package:flutter/material.dart';
import '../models/tiket_model.dart';
import '../providers/feed_provider.dart';
import 'package:provider/provider.dart';

class ReportDetailScreen extends StatelessWidget {
  final TiketModel report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.read<FeedProvider>();
    final isSarpras = report.kategori == 'Sarana Prasarana';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Header Image with Back Button
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: const Color(0xFF2A5256),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.grey, // Placeholder for real image
                child: const Center(
                  child: Icon(Icons.image, size: 80, color: Colors.white54),
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          
          // Detail Content
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0.0, -20.0, 0.0),
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Time
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
                          report.kategori,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        feedProvider.getTimeAgo(report.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    report.judul,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A5256),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          report.lokasiDetail,
                          style: const TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
                  const SizedBox(height: 24),
                  
                  // Removed Status Timeline per request
                  
                  // Description
                  const Text('Deskripsi Laporan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2A5256))),
                  const SizedBox(height: 12),
                  Text(
                    report.deskripsi,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tombol Dukungan Inline
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement Upvote Logic
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dukungan ditambahkan!')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.red.shade200)
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.local_fire_department),
                      label: Text('Berikan Dukungan (${report.jumlahUpvote})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
                  const SizedBox(height: 24),

                  // Daftar Komentar Inline
                  const Text('Komentar (3)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2A5256))),
                  const SizedBox(height: 16),
                  
                  _buildCommentItem('Siti Aminah', 'Tadi pagi saya juga hampir kepeleset di sana. Bahaya banget!', '2 jam yang lalu'),
                  _buildCommentItem('Budi Santoso', 'Harus segera diperbaiki sebelum ada korban.', '4 jam yang lalu'),
                  _buildCommentItem('Andi Pratama', 'Iya nih, licin banget.', '1 hari yang lalu'),

                  // Extra space for bottom bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Sticky Bottom Bar untuk Input Komentar
      bottomSheet: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 0, blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blueGrey.shade100,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tambahkan komentar...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              onTap: () {
                // TODO: Aksi kirim komentar
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF3B696D),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(String name, String text, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade200,
            child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
