import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import '../../constants/api_constants.dart';
import 'super_admin_escalated_screen.dart';
import 'super_admin_ratings_screen.dart';

const kPrimary = Color(0xFF1565C0);
const kPending = Color(0xFFFFA726);
const kResolved = Color(0xFF4CAF50);
const kRejected = Color(0xFFF44336);
const kEscalated = Color(0xFF9C27B0);
const kCardBg = Color(0xFFFFFFFF);

class SuperAdminDashboard extends StatefulWidget {
  final String username;
  const SuperAdminDashboard({super.key, required this.username});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  String? _error;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.superAdminStats}'),
      );
      if (res.statusCode == 200) {
        setState(() {
          _stats = json.decode(res.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Server error ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _loading = false;
      });
    }
  }

  Map<String, dynamic> getOverall() {
    final data = _stats['overall'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  List getDeptStats() {
    final data = _stats['department_stats'];
    if (data is List) return data;
    return [];
  }

  List getTypeStats() {
    final data = _stats['complaint_type_stats'];
    if (data is List) return data;
    return [];
  }

  List getTrend() {
    final data = _stats['daily_trend'];
    if (data is List) return data;
    return [];
  }

  Map<String, dynamic> getEscStats() {
    final data = _stats['escalated_stats'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  List getRatingSum() {
    final data = _stats['admin_rating_summary'];
    if (data is List) return data;
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: kPrimary,
        title: const Text('Super Admin Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) {
              if (val == 'escalated') {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const SuperAdminEscalatedScreen()));
              } else if (val == 'ratings') {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const SuperAdminRatingsScreen()));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'escalated', child: Text('⚠️ Escalated Complaints')),
              PopupMenuItem(value: 'ratings', child: Text('⭐ Admin Ratings')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Departments'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _buildOverviewTab(),
                    _buildDepartmentsTab(),
                    _buildTrendsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    final overall = getOverall();
    final total = overall['total'] ?? 0;
    final pending = overall['pending'] ?? 0;
    final resolved = overall['resolved'] ?? 0;
    final rejected = overall['rejected'] ?? 0;
    final escStats = getEscStats();
    final totalEsc = escStats['total_escalated'] ?? 0;
    final pendEsc = escStats['pending_escalated'] ?? 0;
    final typeStats = getTypeStats();
    final ratingSum = getRatingSum();

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _statCard('Total', total.toString(), Icons.list_alt, kPrimary),
                _statCard('Pending', pending.toString(), Icons.hourglass_empty, kPending),
                _statCard('Resolved', resolved.toString(), Icons.check_circle, kResolved),
                _statCard('Rejected', rejected.toString(), Icons.cancel, kRejected),
              ],
            ),
            const SizedBox(height: 12),
            _wideStatCard(
              '⚠️ Escalated: $totalEsc  |  Pending Escalated: $pendEsc',
              kEscalated,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const SuperAdminEscalatedScreen())),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Overall Complaint Distribution'),
            const SizedBox(height: 12),
            _buildPieChart(pending, resolved, rejected),
            const SizedBox(height: 24),
            _sectionTitle('Top Complaint Types'),
            const SizedBox(height: 8),
            ...typeStats.take(8).map((t) {
              final pct = total > 0 ? (t['count'] / total) : 0.0;
              return _buildTypeRow(t['complaint_type'] ?? 'Unknown',
                  t['count'] ?? 0, pct.toDouble(), kPrimary);
            }),
            const SizedBox(height: 24),
            _sectionTitle('Admin Rating Summary'),
            const SizedBox(height: 8),
            if (ratingSum.isEmpty)
              const Text('No ratings yet.', style: TextStyle(color: Colors.grey))
            else
              ...ratingSum.map((r) => _buildRatingRow(r)),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.star),
                label: const Text('View All Ratings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const SuperAdminRatingsScreen())),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(int pending, int resolved, int rejected) {
    final total = pending + resolved + rejected;
    if (total == 0) {
      return const Center(child: Text('No data yet'));
    }
    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: pending.toDouble(),
                    color: kPending,
                    title: '${(pending / total * 100).toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(fontSize: 12, color: Colors.white,
                        fontWeight: FontWeight.bold),
                    radius: 80,
                  ),
                  PieChartSectionData(
                    value: resolved.toDouble(),
                    color: kResolved,
                    title: '${(resolved / total * 100).toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(fontSize: 12, color: Colors.white,
                        fontWeight: FontWeight.bold),
                    radius: 80,
                  ),
                  PieChartSectionData(
                    value: rejected.toDouble(),
                    color: kRejected,
                    title: '${(rejected / total * 100).toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(fontSize: 12, color: Colors.white,
                        fontWeight: FontWeight.bold),
                    radius: 80,
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legend('Pending', pending, kPending),
              const SizedBox(height: 8),
              _legend('Resolved', resolved, kResolved),
              const SizedBox(height: 8),
              _legend('Rejected', rejected, kRejected),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildDepartmentsTab() {
    final deptStats = getDeptStats();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Department-wise Complaint Breakdown'),
          const SizedBox(height: 16),
          if (deptStats.isNotEmpty) _buildStackedBarChart(deptStats),
          const SizedBox(height: 24),
          ...deptStats.map((dept) => _buildDeptCard(dept)),
        ],
      ),
    );
  }

  Widget _buildStackedBarChart(List deptStats) {
    final maxTotal = deptStats.fold<int>(0, (mx, d) {
      final t = (d['total'] as num?)?.toInt() ?? 0;
      return t > mx ? t : mx;
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Complaints per Department',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxTotal * 1.2).toDouble(),
                  barGroups: deptStats.asMap().entries.map((e) {
                    final i = e.key;
                    final dept = e.value;
                    final p = (dept['pending'] as num?)?.toDouble() ?? 0;
                    final res = (dept['resolved'] as num?)?.toDouble() ?? 0;
                    final rej = (dept['rejected'] as num?)?.toDouble() ?? 0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: p + res + rej,
                          rodStackItems: [
                            BarChartRodStackItem(0, p, kPending),
                            BarChartRodStackItem(p, p + res, kResolved),
                            BarChartRodStackItem(p + res, p + res + rej, kRejected),
                          ],
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= deptStats.length) return const SizedBox();
                          final label = (deptStats[idx]['admin_type'] as String)
                              .toUpperCase()
                              .substring(0, 3);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(label, style: const TextStyle(fontSize: 10)),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: maxTotal > 0 ? (maxTotal / 4).toDouble() : 1,
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _legend('Pending', null, kPending),
              const SizedBox(width: 12),
              _legend('Resolved', null, kResolved),
              const SizedBox(width: 12),
              _legend('Rejected', null, kRejected),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDeptCard(Map dept) {
    final types = (dept['type_breakdown'] as List?) ?? [];
    final total = dept['total'] ?? 0;
    final pending = dept['pending'] ?? 0;
    final resolved = dept['resolved'] ?? 0;
    final rejected = dept['rejected'] ?? 0;
    final avgRating = dept['avg_rating'] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: kPrimary,
          child: Text(
            (dept['admin_type'] as String? ?? 'X').substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          (dept['admin_type'] as String? ?? '').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Total: $total  |  ⭐ ${avgRating.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _chip('Pending $pending', kPending),
                  const SizedBox(width: 6),
                  _chip('Resolved $resolved', kResolved),
                  const SizedBox(width: 6),
                  _chip('Rejected $rejected', kRejected),
                ]),
                const SizedBox(height: 12),
                const Text('Complaint Types:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                ...types.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    const Icon(Icons.circle, size: 6, color: kPrimary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(t['complaint_type'] ?? '',
                        style: const TextStyle(fontSize: 13))),
                    Text(t['count'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    final trend = getTrend();
    if (trend.isEmpty) {
      return const Center(child: Text('No trend data available yet.'));
    }

    final spots = trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['total'] as num).toDouble());
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Daily Complaint Trend (Last 30 Days)'),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 260,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: kPrimary,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: kPrimary.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: (trend.length / 5).ceilToDouble(),
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx < 0 || idx >= trend.length) return const SizedBox();
                            final d = trend[idx]['date'] as String;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(d.substring(5),
                                  style: const TextStyle(fontSize: 9)),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Daily Breakdown Table'),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: DataTable(
              columnSpacing: 12,
              headingRowColor: WidgetStateProperty.all(kPrimary.withValues(alpha: 0.1)),
              columns: const [
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Pending', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Resolved', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: trend.map<DataRow>((t) => DataRow(cells: [
                DataCell(Text(t['date'] ?? '', style: const TextStyle(fontSize: 12))),
                DataCell(Text(t['total'].toString())),
                DataCell(Text(t['pending'].toString(),
                    style: const TextStyle(color: kPending))),
                DataCell(Text(t['resolved'].toString(),
                    style: const TextStyle(color: kResolved))),
              ])).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _wideStatCard(String text, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600))),
          Icon(Icons.chevron_right, color: color),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimary));

  Widget _legend(String label, int? value, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(value != null ? '$label ($value)' : label,
          style: const TextStyle(fontSize: 12)),
    ]);
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color,
          fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTypeRow(String type, int count, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(type, style: const TextStyle(fontSize: 13))),
          Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 3),
        LinearProgressIndicator(
          value: pct,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ]),
    );
  }

  Widget _buildRatingRow(Map r) {
    final avg = (r['avg_rating'] as num?)?.toDouble() ?? 0.0;
    final tot = r['total_ratings'] ?? 0;
    final role = r['admin__role'] ?? '';
    final user = r['admin__user__username'] ?? '';
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: kPrimary.withValues(alpha: 0.15),
        child: Text(role.isNotEmpty ? role[0].toUpperCase() : '?',
            style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
      ),
      title: Text('$user ($role)',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text('$tot rating(s)'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 2),
        Text(avg.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: kRejected),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: _loadStats),
      ],
    ));
  }
}