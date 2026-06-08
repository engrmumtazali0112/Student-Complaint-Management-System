import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'student_submit_complaint.dart';
import 'student_track_complaints.dart';
import 'student_rejected_complaints.dart';
import 'student_login.dart';

class StudentDashboard extends StatefulWidget {
  final String studentId;

  const StudentDashboard({super.key, required this.studentId});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  Map<String, dynamic>? studentData;
  Map<String, dynamic>? stats;
  List notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/api/student/dashboard/${widget.studentId}/'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          studentData = data['student'];
          stats = data['stats'];
          notifications = data['notifications'] ?? [];
          isLoading = false;
        });
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A365D),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Dashboard',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            if (studentData != null)
              Text(
                studentData!['student_id'] ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchDashboard,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome Card
                  _buildWelcomeCard(),
                  const SizedBox(height: 20),

                  // Stats Row
                  _buildStatsRow(),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A365D)),
                  ),
                  const SizedBox(height: 12),
                  _buildActionGrid(),
                  const SizedBox(height: 24),

                  // Notifications
                  const Text(
                    'Recent Notifications',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A365D)),
                  ),
                  const SizedBox(height: 12),
                  _buildNotifications(),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    final name = studentData?['name'] ?? 'Student';
    final dept = studentData?['department'] ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A365D), Color(0xFF2B6CB0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A365D).withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.school_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $name',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dept,
                  style: TextStyle(
                      fontSize: 13, color: Colors.white.withAlpha(200)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = stats?['total'] ?? 0;
    final pending = stats?['pending'] ?? 0;
    final resolved = stats?['resolved'] ?? 0;

    return Row(
      children: [
        _statCard('Total', total.toString(), Icons.list_alt_rounded,
            const Color(0xFF2B6CB0)),
        const SizedBox(width: 12),
        _statCard('Pending', pending.toString(), Icons.hourglass_empty_rounded,
            const Color(0xFFF59E0B)),
        const SizedBox(width: 12),
        _statCard('Resolved', resolved.toString(),
            Icons.check_circle_outline_rounded, const Color(0xFF10B981)),
      ],
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withAlpha(15),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid() {
    final actions = [
      {
        'label': 'Submit Complaint',
        'icon': Icons.add_circle_outline_rounded,
        'color': const Color(0xFF2B6CB0),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SubmitComplaintScreen(studentId: widget.studentId),
              ),
            ),
      },
      {
        'label': 'Track Complaints',
        'icon': Icons.track_changes_rounded,
        'color': const Color(0xFF10B981),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TrackComplaintsScreen(studentId: widget.studentId),
              ),
            ),
      },
      {
        'label': 'Rejected',
        'icon': Icons.cancel_outlined,
        'color': const Color(0xFFDC2626),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentRejectedComplaintsScreen(
                    studentId: widget.studentId),
              ),
            ),
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: actions.map((a) {
        final color = a['color'] as Color;
        return GestureDetector(
          onTap: a['onTap'] as VoidCallback,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(a['icon'] as IconData, color: color, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  a['label'] as String,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A365D)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotifications() {
    if (notifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No notifications yet',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: notifications.map<Widget>((n) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withAlpha(10),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B6CB0).withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Color(0xFF2B6CB0), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n['message'] ?? '',
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A365D),
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n['date'] ?? '',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}