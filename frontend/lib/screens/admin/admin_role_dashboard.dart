import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_all_complaints.dart';
import 'admin_role_rejected_complaints.dart';  // ✅ New import
import '../shared/welcome.dart';

class AdminRoleDashboardScreen extends StatefulWidget {
  final String adminRole;
  final String adminName;
  final String adminUsername;

  const AdminRoleDashboardScreen({
    super.key,
    required this.adminRole,
    required this.adminName,
    required this.adminUsername,
  });

  @override
  State<AdminRoleDashboardScreen> createState() => _AdminRoleDashboardScreenState();
}

class _AdminRoleDashboardScreenState extends State<AdminRoleDashboardScreen> {
  int totalCount = 0;
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
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/admin/complaints/${widget.adminRole}/"),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final complaints = data['data'] as List;
        
        setState(() {
          totalCount = complaints.length;
          pendingCount = complaints.where((c) => c['status'] == 'pending').length;
          resolvedCount = complaints.where((c) => c['status'] == 'resolved').length;
          rejectedCount = complaints.where((c) => c['status'] == 'rejected').length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching counts: $e");
    }
  }

  String getRoleTitle() {
    switch (widget.adminRole) {
      case 'warden':
        return 'Warden Portal';
      case 'examination':
        return 'Examination Portal';
      default:
        return 'Administration Portal';
    }
  }

  IconData getRoleIcon() {
    switch (widget.adminRole) {
      case 'warden':
        return Icons.apartment_rounded;
      case 'examination':
        return Icons.edit_note_rounded;
      default:
        return Icons.business_center_rounded;
    }
  }

  Color getRoleColor() {
    switch (widget.adminRole) {
      case 'warden':
        return const Color(0xFF10B981);
      case 'examination':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF2B6CB0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A365D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getRoleTitle(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A365D),
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: fetchCounts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [getRoleColor(), getRoleColor().withAlpha(179)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(getRoleIcon(), color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome,",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withAlpha(179),
                                ),
                              ),
                              Text(
                                widget.adminName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "@${widget.adminUsername}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withAlpha(179),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats Cards Row - 4 cards
              Row(
                children: [
                  _buildStatCard(
                    title: "Total",
                    value: totalCount.toString(),
                    icon: Icons.format_list_numbered,
                    color: getRoleColor(),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: "Pending",
                    value: pendingCount.toString(),
                    icon: Icons.pending_actions,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: "Resolved",
                    value: resolvedCount.toString(),
                    icon: Icons.check_circle,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: "Rejected",
                    value: rejectedCount.toString(),
                    icon: Icons.cancel_outlined,
                    color: const Color(0xFFDC2626),
                  ),
                ],
              ),

              const SizedBox(height: 24),

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

              // All Complaints Card
              _buildMenuCard(
                title: "All Complaints",
                subtitle: "View and manage all complaints assigned to you",
                icon: Icons.list_alt_rounded,
                color: getRoleColor(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminRoleComplaintsScreen(
                        adminRole: widget.adminRole,
                        title: "All Complaints",
                        filter: "all",
                      ),
                    ),
                  ).then((_) => fetchCounts());
                },
              ),
              const SizedBox(height: 14),

              // Pending Complaints Card
              _buildMenuCard(
                title: "Pending Complaints",
                subtitle: "Complaints awaiting your action",
                icon: Icons.pending_actions,
                color: const Color(0xFFF59E0B),
                badgeCount: pendingCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminRoleComplaintsScreen(
                        adminRole: widget.adminRole,
                        title: "Pending Complaints",
                        filter: "pending",
                      ),
                    ),
                  ).then((_) => fetchCounts());
                },
              ),
              const SizedBox(height: 14),

              // Resolved Complaints Card
              _buildMenuCard(
                title: "Resolved Complaints",
                subtitle: "View resolved complaint history",
                icon: Icons.check_circle_outline,
                color: const Color(0xFF10B981),
                badgeCount: resolvedCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminRoleComplaintsScreen(
                        adminRole: widget.adminRole,
                        title: "Resolved Complaints",
                        filter: "resolved",
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // ✅ New: Rejected Complaints Card
              _buildMenuCard(
                title: "Rejected Complaints",
                subtitle: "View rejected complaints with reasons",
                icon: Icons.cancel_outlined,
                color: const Color(0xFFDC2626),
                badgeCount: rejectedCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminRoleRejectedComplaintsScreen(
                        adminRole: widget.adminRole,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),

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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
    required Color color,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withAlpha(26)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A365D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}