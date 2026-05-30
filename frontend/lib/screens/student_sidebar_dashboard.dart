import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'submit_complaint.dart';
import 'track_complains.dart';
import 'student_rejected_complaints.dart';
import 'student_login.dart';
import 'student_profile_screen.dart';

class StudentSidebarDashboard extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentSidebarDashboard({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentSidebarDashboard> createState() => _StudentSidebarDashboardState();
}

class _StudentSidebarDashboardState extends State<StudentSidebarDashboard> {
  int selectedIndex = 0;
  int totalCount = 0;
  int pendingCount = 0;
  int resolvedCount = 0;
  int rejectedCount = 0;

  final List<Map<String, dynamic>> menuItems = [
    {'title': 'Profile', 'icon': Icons.person_outline, 'filter': 'profile'},
    {'title': 'Submit Complaint', 'icon': Icons.add_circle_outline, 'filter': 'submit'},
    {'title': 'Track Complaints', 'icon': Icons.track_changes, 'filter': 'track'},
    {'title': 'Rejected Complaints', 'icon': Icons.cancel_outlined, 'filter': 'rejected'},
    {'title': 'Logout', 'icon': Icons.logout, 'filter': 'logout'},
  ];

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/student/dashboard/${widget.studentId}/"),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final stats = data['stats'];
        
        setState(() {
          totalCount = stats['total'] ?? 0;
          pendingCount = stats['pending'] ?? 0;
          resolvedCount = stats['resolved'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }
  }

  Future<void> fetchRejectedCount() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/student/complaint/track/${widget.studentId}/"),
      );
      
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final complaints = data['data'] as List;
        
        setState(() {
          rejectedCount = complaints.where((c) => c['status'] == 'rejected').length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching rejected count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Sidebar Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A365D), Color(0xFF2B6CB0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.studentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.studentId,
                        style: TextStyle(
                          color: Colors.white.withAlpha(179),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stats Cards in Sidebar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _sidebarStat('Total', totalCount.toString(), Icons.format_list_numbered, const Color(0xFF2B6CB0)),
                      const SizedBox(height: 8),
                      _sidebarStat('Pending', pendingCount.toString(), Icons.pending_actions, const Color(0xFFF59E0B)),
                      const SizedBox(height: 8),
                      _sidebarStat('Resolved', resolvedCount.toString(), Icons.check_circle, const Color(0xFF10B981)),
                      const SizedBox(height: 8),
                      _sidebarStat('Rejected', rejectedCount.toString(), Icons.cancel, const Color(0xFFDC2626)),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // Menu Items
                Expanded(
                  child: ListView.builder(
                    itemCount: menuItems.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final isSelected = selectedIndex == index;
                      return ListTile(
                        leading: Icon(
                          item['icon'] as IconData,
                          color: isSelected ? const Color(0xFF2B6CB0) : Colors.grey.shade500,
                          size: 22,
                        ),
                        title: Text(
                          item['title'] as String,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF2B6CB0) : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        tileColor: isSelected ? const Color(0xFF2B6CB0).withAlpha(26) : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onTap: () {
                          if (item['filter'] == 'logout') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const StudentLoginScreen()),
                            );
                          } else {
                            setState(() {
                              selectedIndex = index;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _sidebarStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (selectedIndex) {
      case 0:
        return StudentProfileScreen(
          studentId: widget.studentId,
          studentName: widget.studentName,
          studentUsername: widget.studentId,
        );
      case 1:
        return SubmitComplaintScreen(studentId: widget.studentId);
      case 2:
        return TrackComplaintsScreen(studentId: widget.studentId);
      case 3:
        return StudentRejectedComplaintsScreen(studentId: widget.studentId);
      default:
        return const Center(child: Text('Select an option'));
    }
  }
}