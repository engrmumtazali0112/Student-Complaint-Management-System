import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_all_complaints.dart';
import '../shared/welcome.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int newComplaintCount = 0;
  int pendingCount = 0;
  int resolvedCount = 0;
  int rejectedCount = 0;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    try {
      // Fetch new complaints count
      final newResponse = await http.get(
        Uri.parse("http://localhost:8000/api/admin/new-count/"),
      );
      
      // Fetch pending complaints count
      final pendingResponse = await http.get(
        Uri.parse("http://localhost:8000/api/admin/complaint/pending/"),
      );
      
      // Fetch resolved complaints count
      final resolvedResponse = await http.get(
        Uri.parse("http://localhost:8000/api/admin/complaint/solved/"),
      );
      
      // Fetch rejected complaints count
      final rejectedResponse = await http.get(
        Uri.parse("http://localhost:8000/api/admin/complaint/rejected/"),
      );

      if (newResponse.statusCode == 200 && mounted) {
        final newData = jsonDecode(newResponse.body);
        setState(() {
          newComplaintCount = newData['new_count'];
        });
      }
      
      if (pendingResponse.statusCode == 200 && mounted) {
        final pendingData = jsonDecode(pendingResponse.body);
        setState(() {
          pendingCount = pendingData['data']?.length ?? 0;
        });
      }
      
      if (resolvedResponse.statusCode == 200 && mounted) {
        final resolvedData = jsonDecode(resolvedResponse.body);
        setState(() {
          resolvedCount = resolvedData['data']?.length ?? 0;
        });
      }
      
      if (rejectedResponse.statusCode == 200 && mounted) {
        final rejectedData = jsonDecode(rejectedResponse.body);
        setState(() {
          rejectedCount = rejectedData['data']?.length ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Error fetching counts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 28,
                        color: Color(0xFF1A365D),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A365D),
                          ),
                        ),
                        Text(
                          'Manage and resolve complaints efficiently',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8B9DC3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Stats Cards Row
                Row(
                  children: [
                    _buildStatCard(
                      title: "New",
                      count: newComplaintCount,
                      icon: Icons.notifications_active,
                      color: const Color(0xFFDC2626),
                      gradientColors: [const Color(0xFFDC2626), const Color(0xFFEF4444)],
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      title: "Pending",
                      count: pendingCount,
                      icon: Icons.pending_actions,
                      color: const Color(0xFFF59E0B),
                      gradientColors: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      title: "Resolved",
                      count: resolvedCount,
                      icon: Icons.check_circle,
                      color: const Color(0xFF10B981),
                      gradientColors: [const Color(0xFF10B981), const Color(0xFF34D399)],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                      title: "Rejected",
                      count: rejectedCount,
                      icon: Icons.cancel,
                      color: const Color(0xFFDC2626),
                      gradientColors: [const Color(0xFFDC2626), const Color(0xFFEF4444)],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Menu Section Title
                const Text(
                  'MANAGE COMPLAINTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: Color(0xFF8B9DC3),
                  ),
                ),
                const SizedBox(height: 16),

                // New Complaints Card
                _buildMenuCard(
                  title: "New Complaints",
                  subtitle: "Review and process incoming complaints",
                  icon: Icons.notifications_none,
                  badgeCount: newComplaintCount,
                  gradientColors: [const Color(0xFF1A365D), const Color(0xFF2B6CB0)],
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminRoleComplaintsScreen(adminRole: 'administration', title: 'New Complaints', filter: 'all'),
                      ),
                    );
                    fetchCounts();
                  },
                ),
                const SizedBox(height: 14),

                // Pending Complaints Card
                _buildMenuCard(
                  title: "Pending Complaints",
                  subtitle: "Complaints awaiting resolution",
                  icon: Icons.pending_actions,
                  badgeCount: pendingCount,
                  gradientColors: [const Color(0xFFE67E22), const Color(0xFFF39C12)],
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminRoleComplaintsScreen(adminRole: 'administration', title: 'Pending Complaints', filter: 'pending'),
                      ),
                    );
                    fetchCounts();
                  },
                ),
                const SizedBox(height: 14),

                // Solved Complaints Card
                _buildMenuCard(
                  title: "Solved Complaints",
                  subtitle: "View resolved complaint history",
                  icon: Icons.check_circle_outline,
                  badgeCount: resolvedCount,
                  gradientColors: [const Color(0xFF059669), const Color(0xFF10B981)],
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminRoleComplaintsScreen(adminRole: 'administration', title: 'Solved Complaints', filter: 'resolved'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Rejected Complaints Card
                _buildMenuCard(
                  title: "Rejected Complaints",
                  subtitle: "View rejected complaints with reasons",
                  icon: Icons.cancel_outlined,
                  badgeCount: rejectedCount,
                  gradientColors: [const Color(0xFFDC2626), const Color(0xFFEF4444)],
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminRoleComplaintsScreen(adminRole: 'administration', title: 'Rejected Complaints', filter: 'rejected'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Divider
                Divider(color: Colors.grey.shade200, height: 1),

                const SizedBox(height: 20),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WelcomeScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(40),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withAlpha(179),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required int badgeCount,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Badge Count
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: gradientColors.first,
                    ),
                  ),
                ),
              
              const SizedBox(width: 8),
              
              // Arrow Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}