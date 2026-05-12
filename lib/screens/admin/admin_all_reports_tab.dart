import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_dashboard_provider.dart';
import 'admin_report_review_screen.dart';

class AdminAllReportsTab extends StatefulWidget {
  const AdminAllReportsTab({super.key});

  @override
  State<AdminAllReportsTab> createState() => _AdminAllReportsTabState();
}

class _AdminAllReportsTabState extends State<AdminAllReportsTab> {
  bool _isFilterExpanded = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminDashboardProvider>();

    return Column(
      children: [
        // Filter & Sort Bar
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A5256),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Filter dengan Tombol Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Laporan',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isFilterExpanded = !_isFilterExpanded;
                      });
                    },
                    icon: Icon(
                      _isFilterExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              
              // Bagian Filter yang Bisa Ditutup/Buka
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isFilterExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'Kategori Laporan',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const SizedBox(height: 12),
                          // Category Filter (Custom Chips)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildFilterChip(context, provider, 'Semua', Icons.all_inclusive_rounded),
                                const SizedBox(width: 10),
                                _buildFilterChip(context, provider, 'Sarpras', Icons.build_circle_rounded),
                                const SizedBox(width: 10),
                                _buildFilterChip(context, provider, 'Kebersihan', Icons.clean_hands_rounded),
                              ],
                            ),
                          ),
                          // Status Filter (Only show if 'Selesai Direview')
                          if (provider.adminActionTab == 'Selesai Direview') ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Status Tindakan',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildStatusFilterChip(context, provider, 'Semua', Icons.list),
                                  const SizedBox(width: 10),
                                  _buildStatusFilterChip(context, provider, 'Disetujui', Icons.check_circle_outline),
                                  const SizedBox(width: 10),
                                  _buildStatusFilterChip(context, provider, 'Ditolak', Icons.cancel_outlined),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          // Sort UI
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sort_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 12),
                                const Text('Urutkan:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                const Spacer(),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: provider.selectedSort,
                                    dropdownColor: const Color(0xFF2A5256),
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        Expanded(
          child: provider.filteredAndSortedReports.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => provider.fetchDashboardStats(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: _buildEmptyState(),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.fetchDashboardStats(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      image: tiket.buktiVisual.isNotEmpty && tiket.buktiVisual.first != 'placeholder.jpg'
                                          ? DecorationImage(
                                              image: NetworkImage(tiket.buktiVisual.first),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: (tiket.buktiVisual.isEmpty || tiket.buktiVisual.first == 'placeholder.jpg')
                                        ? Icon(isSarpras ? Icons.build : Icons.cleaning_services, color: color)
                                        : null,
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
                                  if (tiket.status == 'Menunggu Verifikasi')
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
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: tiket.status == 'Approved' ? Colors.green.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: tiket.status == 'Approved' ? Colors.green.shade200 : Colors.red.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(tiket.status == 'Approved' ? Icons.check_circle : Icons.cancel, size: 16, color: tiket.status == 'Approved' ? Colors.green : Colors.red),
                                          const SizedBox(width: 4),
                                          Text(tiket.status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: tiket.status == 'Approved' ? Colors.green : Colors.red, fontSize: 12)),
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
      ),
    ],
  );
}

  Widget _buildFilterChip(BuildContext context, AdminDashboardProvider provider, String label, IconData icon) {
    final isSelected = provider.selectedCategoryFilter == label;
    return GestureDetector(
      onTap: () => provider.setCategoryFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF39C12) : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected 
            ? [BoxShadow(color: const Color(0xFFF39C12).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
            : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(BuildContext context, AdminDashboardProvider provider, String label, IconData icon) {
    final isSelected = provider.adminStatusFilter == label;
    return GestureDetector(
      onTap: () => provider.setAdminStatusFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5A77A) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
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
