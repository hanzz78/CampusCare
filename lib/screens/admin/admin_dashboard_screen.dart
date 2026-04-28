import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final provider = context.watch<AdminDashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Keluar?'),
                  content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: provider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : provider.errorMessage != null 
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage!, 
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => provider.fetchDashboardStats(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWelcomeHeader(),
                const SizedBox(height: 24),
                const Text('Ringkasan Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildMetricCards(provider),
                const SizedBox(height: 24),
                const Text('Statistik Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildBarChart(provider),
                const SizedBox(height: 24),
                const Text('Distribusi Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildPieChart(provider),
                const SizedBox(height: 24),
                const Text('Tren Laporan (7 Hari Terakhir)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildLineChart(),
              ],
            ),
          ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.admin_panel_settings, size: 36, color: Colors.blueGrey),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, Penanggung Jawab',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Pantau dan kelola tiket pelaporan di sini.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(AdminDashboardProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _MetricCard(title: 'Total Masuk', value: provider.totalMasuk.toString(), icon: Icons.inbox, color: Colors.blue),
        _MetricCard(title: 'Pending', value: provider.pendingCount.toString(), icon: Icons.pending_actions, color: Colors.orange),
        _MetricCard(title: 'Waktu Respons', value: provider.waktuRespons, icon: Icons.timer, color: Colors.purple),
        _MetricCard(title: 'Resolusi', value: provider.resolusiPercentage, icon: Icons.check_circle, color: Colors.green),
      ],
    );
  }

  Widget _buildBarChart(AdminDashboardProvider provider) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0: return const Text('Sarpras');
                    case 1: return const Text('Kebersihan');
                    default: return const Text('');
                  }
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: provider.sarprasPercentage, color: Colors.blue, width: 20)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: provider.kebersihanPercentage, color: Colors.green, width: 20)]),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(AdminDashboardProvider provider) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            if (provider.pendingPercentage > 0)
              PieChartSectionData(value: provider.pendingPercentage, title: '${provider.pendingPercentage.toStringAsFixed(0)}%', color: Colors.orange, radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (provider.approvedPercentage > 0)
              PieChartSectionData(value: provider.approvedPercentage, title: '${provider.approvedPercentage.toStringAsFixed(0)}%', color: Colors.blue, radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (provider.rejectedPercentage > 0)
              PieChartSectionData(value: provider.rejectedPercentage, title: '${provider.rejectedPercentage.toStringAsFixed(0)}%', color: Colors.red, radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (provider.resolvedPercentage > 0)
              PieChartSectionData(value: provider.resolvedPercentage, title: '${provider.resolvedPercentage.toStringAsFixed(0)}%', color: Colors.green, radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('H${value.toInt()}');
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
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
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
