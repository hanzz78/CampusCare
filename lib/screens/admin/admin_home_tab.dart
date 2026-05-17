import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../models/tiket_model.dart';
import 'admin_report_review_screen.dart';

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  static const Color _teal = Color(0xFF2A5256);
  static const Color _tealMid = Color(0xFF335C67);
  static const Color _yellow = Color(0xFFE09F3E);
  static const Color _red = Color(0xFF9E2A2B);
  static const Color _vanilla = Color(0xFFFFF3B0);
  static const Color _surface = Color(0xFFF8F3EC);

  bool _showNotifications = false;
  final Set<String> _readKeys = {};
  static const String _prefKey = 'admin_read_notif_keys';

  @override
  void initState() {
    super.initState();
    _loadReadKeys();
  }

  Future<void> _loadReadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefKey) ?? [];
    setState(() => _readKeys.addAll(saved));
  }

  Future<void> _saveReadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _readKeys.toList());
  }

  List<_AdminNotif> _buildNotifications(List<TiketModel> reports) {
    final items = <_AdminNotif>[];

    // Laporan baru (Menunggu Verifikasi), maks 5 terbaru
    final pending = reports
        .where((r) => r.status == 'Menunggu Verifikasi')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final r in pending.take(5)) {
      items.add(_AdminNotif(
        key: 'baru-${r.idTiket}',
        title: 'Laporan baru masuk',
        subtitle: '${r.judulSingkat} · ${r.lokasi.gedung}',
        icon: Icons.note_add_rounded,
        iconColor: _tealMid,
        report: r,
        createdAt: r.createdAt,
      ));
    }

    // Laporan trending (10+ dukungan, masih pending)
    final trending = reports
        .where((r) => r.jumlahVote >= 10 && r.status == 'Menunggu Verifikasi')
        .toList()
      ..sort((a, b) => b.jumlahVote.compareTo(a.jumlahVote));

    for (final r in trending.take(5)) {
      items.add(_AdminNotif(
        key: 'trending-${r.idTiket}-${r.jumlahVote}',
        title: 'Banyak dikeluhkan warga',
        subtitle: '${r.judulSingkat} · ${r.jumlahVote} dukungan',
        icon: Icons.arrow_upward_rounded,
        iconColor: _red,
        report: r,
        createdAt: r.updatedAt,
      ));
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminDashboardProvider>();
    final notifs = _buildNotifications(provider.reports);
    final hasUnread = notifs.any((n) => !_readKeys.contains(n.key));

    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(hasUnread, notifs),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B696D)))
                  : provider.errorMessage != null
                      ? _buildError(provider)
                      : RefreshIndicator(
                          color: _tealMid,
                          onRefresh: () => provider.fetchDashboardStats(),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _sectionLabel('Statistik Laporan'),
                                const SizedBox(height: 10),
                                _buildTopMetrics(provider),
                                const SizedBox(height: 20),
                                _sectionLabel('Tingkat Urgensi'),
                                const SizedBox(height: 10),
                                _buildUrgencyStats(provider),
                                const SizedBox(height: 20),
                                _sectionLabel('Kategori Masuk'),
                                const SizedBox(height: 10),
                                _buildCategoryStats(provider),
                                const SizedBox(height: 20),
                                _sectionLabel('Laporan Per Hari (7 Hari)'),
                                const SizedBox(height: 10),
                                _buildReportsChart(provider),
                                const SizedBox(height: 20),
                                _buildDailySummaryTable(provider),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
        // Backdrop untuk tutup notif
        if (_showNotifications)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _showNotifications = false),
              child: const SizedBox.expand(),
            ),
          ),
        // Panel notifikasi
        if (_showNotifications)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 74,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD8DDE0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Notifikasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6F8A90))),
                          ),
                          GestureDetector(
                            onTap: notifs.isEmpty ? null : () async {
                              setState(() => _readKeys.addAll(notifs.map((n) => n.key)));
                              await _saveReadKeys();
                            },
                            child: Text(
                              'Tandai semua dibaca',
                              style: TextStyle(fontSize: 12, color: notifs.isEmpty ? const Color(0xFFAAB5B9) : const Color(0xFF6F8A90)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (notifs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('Belum ada notifikasi.', style: TextStyle(color: Color(0xFF6F8A90), fontSize: 12)),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.separated(
                          primary: false,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: notifs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final item = notifs[i];
                            final isRead = _readKeys.contains(item.key);
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _readKeys.add(item.key);
                                  _showNotifications = false;
                                });
                                _saveReadKeys();
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => AdminReportReviewScreen(report: item.report),
                                ));
                              },
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34, height: 34,
                                      decoration: BoxDecoration(
                                        color: item.iconColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Icon(item.icon, size: 17, color: item.iconColor),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F2B33))),
                                          const SizedBox(height: 2),
                                          Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF6F8A90))),
                                        ],
                                      ),
                                    ),
                                    if (!isRead) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.circle, size: 8, color: Color(0xFF4CAF50)),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(bool hasUnread, List<_AdminNotif> notifs) {
    return Container(
      color: _teal,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SELAMAT DATANG',
                      style: TextStyle(color: Color(0xFFD9CFA8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: const TextSpan(children: [
                        TextSpan(text: 'Penanggung ', style: TextStyle(color: Color(0xFFFFF3B0), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        TextSpan(text: 'Jawab', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      ]),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Pantau dan tindak lanjut laporan masuk',
                      style: TextStyle(color: Color(0xFFD9CFA8), fontSize: 11, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showNotifications = !_showNotifications;
                        });
                      },
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                    ),
                    if (hasUnread)
                      const Positioned(
                        top: 10, right: 10,
                        child: Icon(Icons.circle, size: 8, color: Color(0xFFD32F2F)),
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

  Widget _sectionLabel(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF335C67))),
  );

  Widget _buildError(AdminDashboardProvider provider) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(provider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: () => provider.fetchDashboardStats(), icon: const Icon(Icons.refresh), label: const Text('Coba Lagi')),
      ]),
    ),
  );

  Widget _buildTopMetrics(AdminDashboardProvider provider) {
    final accepted = provider.reports.where((t) => t.status == 'Approved' || t.status == 'Documented').length;
    final rejected = provider.reports.where((t) => t.status == 'Rejected').length;
    return Column(children: [
      Row(children: [
        Expanded(child: _metricCard('Open', provider.belumDireview.toString(), Icons.radio_button_checked_rounded, _red)),
        const SizedBox(width: 10),
        Expanded(child: _metricCard('Diterima', accepted.toString(), Icons.check_box_rounded, const Color(0xFF4CBF88))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _metricCard('Ditolak', rejected.toString(), Icons.close_rounded, const Color(0xFFE85A7A))),
        const SizedBox(width: 10),
        Expanded(child: _metricCard('Total', provider.totalLaporan.toString(), Icons.assignment_rounded, _tealMid)),
      ]),
    ]);
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 9, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF7E8A93), fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      ]),
    );
  }

  Widget _buildUrgencyStats(AdminDashboardProvider provider) {
    final high = provider.urgensiHigh;
    final med = provider.urgensiMedium;
    final low = provider.urgensiLow;
    final total = (high + med + low).toDouble();
    return Row(children: [
      Expanded(child: _urgencyCard('Tinggi', high, total, _red, const Color(0xFFFFF0F0), const Color(0xFFFFCDD2), Icons.priority_high_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _urgencyCard('Sedang', med, total, _yellow, const Color(0xFFFFF8EC), const Color(0xFFFFE0A3), Icons.remove_circle_outline_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _urgencyCard('Rendah', low, total, _tealMid, const Color(0xFFEBF0F0), const Color(0xFFB2CCCE), Icons.arrow_downward_rounded)),
    ]);
  }

  Widget _urgencyCard(String label, int count, double total, Color color, Color bg, Color border, IconData icon) {
    final pct = total <= 0 ? 0.0 : count / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color, height: 1)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: pct, minHeight: 5, backgroundColor: color.withOpacity(0.15), valueColor: AlwaysStoppedAnimation<Color>(color)),
        ),
        const SizedBox(height: 4),
        Text('${(pct * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildCategoryStats(AdminDashboardProvider provider) {
    return Row(children: [
      Expanded(child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFEBEFF0), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD2DCDE))),
        child: Column(children: [
          const Icon(Icons.build_rounded, color: Color(0xFF335C67), size: 30),
          const SizedBox(height: 8),
          Text(provider.sarprasCount.toString(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF335C67))),
          Text('Sarana Prasarana\n${provider.sarprasPercentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: Color(0xFF486B74)), textAlign: TextAlign.center),
        ]),
      )),
      const SizedBox(width: 12),
      Expanded(child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFFCF5EC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF0E1CC))),
        child: Column(children: [
          const Icon(Icons.cleaning_services_rounded, color: Color(0xFFE09F3E), size: 30),
          const SizedBox(height: 8),
          Text(provider.kebersihanCount.toString(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFFCA8F38))),
          Text('Kebersihan\n${provider.kebersihanPercentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: Color(0xFF906731)), textAlign: TextAlign.center),
        ]),
      )),
    ]);
  }

  Widget _buildReportsChart(AdminDashboardProvider provider) {
    final counts = provider.chartLast7DaysCounts;
    final days = provider.chartLast7Days;
    final maxY = provider.chartMaxCount.toDouble() + 1;
    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE6E1D7))),
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY, minY: 0,
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFF0ECE4), strokeWidth: 1)),
        borderData: FlBorderData(show: true, border: const Border(left: BorderSide(color: Color(0xFFDCD5C9), width: 1), bottom: BorderSide(color: Color(0xFFDCD5C9), width: 1), top: BorderSide.none, right: BorderSide.none)),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1, getTitlesWidget: (v, _) {
            if (v % 1 != 0) return const SizedBox.shrink();
            return Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: Color(0xFF7B858B)));
          })),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= days.length) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(top: 4), child: Text(_dayLabel(days[i]), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF5F6E76))));
          })),
        ),
        barGroups: List.generate(counts.length, (i) {
          final isToday = i == counts.length - 1;
          return BarChartGroupData(x: i, barRods: [BarChartRodData(toY: counts[i].toDouble(), width: 18, color: isToday ? _red : _tealMid, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]);
        }),
      )),
    );
  }

  Widget _buildDailySummaryTable(AdminDashboardProvider provider) {
    final days = provider.chartLast7Days;
    final counts = provider.chartLast7DaysCounts;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE3DCCE))),
      child: Column(children: [
        const Row(children: [
          Expanded(child: Text('Hari', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF607078)))),
          Text('Jumlah Laporan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF607078))),
        ]),
        const SizedBox(height: 8),
        ...List.generate(days.length, (i) {
          final isLast = i == days.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFE8E1D4), width: 1))),
            child: Row(children: [
              Expanded(child: Text('${_dayLabel(days[i])}, ${days[i].day}/${days[i].month}', style: const TextStyle(color: Color(0xFF304A52), fontWeight: FontWeight.w600, fontSize: 12))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: counts[i] == 0 ? const Color(0xFFEBEFF0) : _vanilla,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${counts[i]}', style: TextStyle(color: counts[i] == 0 ? const Color(0xFF6D7A81) : _red, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  String _dayLabel(DateTime date) {
    const labels = {1: 'Sen', 2: 'Sel', 3: 'Rab', 4: 'Kam', 5: 'Jum', 6: 'Sab', 7: 'Min'};
    return labels[date.weekday] ?? '-';
  }
}

class _AdminNotif {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final TiketModel report;
  final DateTime createdAt;

  _AdminNotif({required this.key, required this.title, required this.subtitle, required this.icon, required this.iconColor, required this.report, required this.createdAt});
}
