import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_dashboard_provider.dart';

class AdminHomeTab extends StatelessWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminDashboardProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B696D)));
    }

    if (provider.errorMessage != null) {
      return _buildErrorState(provider);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 24),
          
          // 1. Statistik Angka
          const Text('Statistik Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2A5256))),
          const SizedBox(height: 12),
          _buildTopMetrics(provider),
          const SizedBox(height: 24),

          // 2. Tingkat Urgensi
          const Text('Tingkat Urgensi Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2A5256))),
          const SizedBox(height: 12),
          _buildUrgencyStats(provider),
          const SizedBox(height: 24),

          // 3. Statistik Kategori
          const Text('Kategori Masuk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2A5256))),
          const SizedBox(height: 12),
          _buildCategoryStats(provider),
          const SizedBox(height: 24),

          // 4. Grafik Waktu & Frekuensi
          const Text('Tren Laporan (7 Hari)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2A5256))),
          const SizedBox(height: 12),
          _buildLineChart(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildErrorState(AdminDashboardProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(provider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.fetchDashboardStats(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3B696D),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFF39C12), // Oranye aksen
            child: Icon(Icons.shield, size: 30, color: Colors.white),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, Penanggung Jawab', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Siap mengelola tiket hari ini?', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMetrics(AdminDashboardProvider provider) {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Belum Direview', provider.belumDireview.toString(), Icons.pending_actions, Colors.orange.shade700)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Selesai', provider.selesai.toString(), Icons.check_circle, Colors.green.shade600)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Total Masuk', provider.totalLaporan.toString(), Icons.inbox, Colors.blue.shade700)),
      ],
    );
  }

  Widget _buildUrgencyStats(AdminDashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildUrgencyItem('High', provider.urgensiHigh.toString(), Colors.red.shade600, Icons.whatshot),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildUrgencyItem('Medium', provider.urgensiMedium.toString(), Colors.orange.shade500, Icons.warning_amber_rounded),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildUrgencyItem('Low', provider.urgensiLow.toString(), Colors.green.shade500, Icons.low_priority),
        ],
      ),
    );
  }

  Widget _buildCategoryStats(AdminDashboardProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              children: [
                const Icon(Icons.build, color: Color(0xFF3B696D), size: 32),
                const SizedBox(height: 8),
                Text(provider.sarprasCount.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3B696D))),
                const Text('Sarana Prasarana', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              children: [
                const Icon(Icons.cleaning_services, color: Color(0xFFE5A77A), size: 32),
                const SizedBox(height: 8),
                Text(provider.kebersihanCount.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE5A77A))),
                const Text('Kebersihan', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildUrgencyItem(String label, String count, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildLineChart() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('H${value.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 1,
          maxX: 7,
          minY: 0,
          maxY: 20,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(1, 3), FlSpot(2, 5), FlSpot(3, 10), FlSpot(4, 7),
                FlSpot(5, 12), FlSpot(6, 15), FlSpot(7, 8),
              ],
              isCurved: true,
              color: const Color(0xFF3B696D),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: const Color(0xFF3B696D).withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }
}
