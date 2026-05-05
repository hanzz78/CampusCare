import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_dashboard_provider.dart';
import 'admin_report_review_screen.dart';

class AdminAllReportsTab extends StatelessWidget {
  const AdminAllReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminDashboardProvider>();

    return Column(
      children: [
        // Filter & Sort Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Category Filter (Chips)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(context, provider, 'Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, provider, 'Sarpras'),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, provider, 'Kebersihan'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Sort Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Urutkan:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: provider.selectedSort,
                        icon: const Icon(Icons.sort, size: 18),
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        onChanged: (String? newValue) {
                          if (newValue != null) provider.setSort(newValue);
                        },
                        items: <String>['Waktu Terbaru', 'Waktu Terlama', 'Urgensi Tertinggi']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List Laporan
        Expanded(
          child: provider.filteredAndSortedReports.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.filteredAndSortedReports.length,
                  itemBuilder: (context, index) {
                    final tiket = provider.filteredAndSortedReports[index];
                    final isSarpras = tiket.kategori.utama == 'Sarpras';
                    final color = isSarpras ? const Color(0xFF3B696D) : const Color(0xFFE5A77A);

                    final lokasiStr = tiket.lokasiDisplay;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminReportReviewScreen(report: tiket),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                    child: Icon(isSarpras ? Icons.build : Icons.cleaning_services, color: color),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(tiket.judulSingkat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(child: Text(lokasiStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Status / Urgency Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.shade200)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                                        const SizedBox(width: 4),
                                        Text('${tiket.jumlahVote} Dukungan', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  // Waktu
                                  Text(
                                    _formatDate(tiket.createdAt),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(BuildContext context, AdminDashboardProvider provider, String label) {
    final isSelected = provider.selectedCategoryFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          provider.setCategoryFilter(label);
        }
      },
      selectedColor: const Color(0xFF3B696D),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      backgroundColor: Colors.grey.shade200,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Tidak ada laporan yang sesuai kriteria.', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Sederhana, bisa pakai intl package jika ada
    final duration = DateTime.now().difference(date);
    if (duration.inDays > 0) return '${duration.inDays} hari lalu';
    if (duration.inHours > 0) return '${duration.inHours} jam lalu';
    return '${duration.inMinutes} menit lalu';
  }
}
