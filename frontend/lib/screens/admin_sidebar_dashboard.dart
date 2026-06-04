import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_role_complaints.dart';
import 'admin_role_rejected_complaints.dart';
import 'welcome.dart';
import 'admin_profile_screen.dart';

class AdminSidebarDashboard extends StatefulWidget {
  final String adminRole;
  final String adminName;
  final String adminUsername;

  const AdminSidebarDashboard({
    super.key,
    required this.adminRole,
    required this.adminName,
    required this.adminUsername,
  });

  @override
  State<AdminSidebarDashboard> createState() => _AdminSidebarDashboardState();
}

class _AdminSidebarDashboardState extends State<AdminSidebarDashboard> {
  int selectedIndex = 0;
  int totalCount = 0;
  int pendingCount = 0;
  int resolvedCount = 0;
  int rejectedCount = 0;

  Map<String, dynamic>? adminProfile;
  bool isLoadingProfile = true;

  final List<Map<String, dynamic>> menuItems = [
    {'title': 'Profile',             'icon': Icons.person_outline,       'filter': 'profile'},
    {'title': 'All Complaints',      'icon': Icons.list_alt,             'filter': 'all'},
    {'title': 'Pending Complaints',  'icon': Icons.pending_actions,      'filter': 'pending'},
    {'title': 'Resolved Complaints', 'icon': Icons.check_circle_outline, 'filter': 'resolved'},
    {'title': 'Rejected Complaints', 'icon': Icons.cancel_outlined,      'filter': 'rejected'},
    {'title': 'Logout',              'icon': Icons.logout,               'filter': 'logout'},
  ];

  @override
  void initState() {
    super.initState();
    fetchCounts();
    fetchAdminProfile();
  }

  Future<void> fetchCounts() async {
    try {
      final response = await http.get(
        Uri.parse(
            "http://localhost:8000/api/admin/complaints/${widget.adminRole}/"),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final complaints = data['data'] as List;

        setState(() {
          totalCount    = complaints.length;
          pendingCount  = complaints.where((c) => c['status'] == 'pending').length;
          resolvedCount = complaints.where((c) => c['status'] == 'resolved').length;
          rejectedCount = complaints.where((c) => c['status'] == 'rejected').length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching counts: $e");
    }
  }

  Future<void> fetchAdminProfile() async {
    setState(() => isLoadingProfile = true);
    try {
      final response = await http.get(
        Uri.parse(
            "http://localhost:8000/api/admin/profile/${widget.adminUsername}/"),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          adminProfile     = data['data'];
          isLoadingProfile = false;
        });
      } else {
        setState(() => isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      setState(() => isLoadingProfile = false);
    }
  }

  String getRoleTitle() {
    switch (widget.adminRole) {
      case 'warden':      return 'Warden Portal';
      case 'examination': return 'Examination Portal';
      default:            return 'Administration Portal';
    }
  }

  Color getRoleColor() {
    switch (widget.adminRole) {
      case 'warden':      return const Color(0xFF10B981);
      case 'examination': return const Color(0xFFF59E0B);
      default:            return const Color(0xFF2B6CB0);
    }
  }

  IconData getRoleIcon() {
    switch (widget.adminRole) {
      case 'warden':      return Icons.apartment_rounded;
      case 'examination': return Icons.edit_note_rounded;
      default:            return Icons.business_center_rounded;
    }
  }

  Widget _sidebarAvatar() {
    final picUrl = adminProfile?['profile_picture'];
    final bool hasPic = picUrl != null && picUrl.toString().isNotEmpty;

    String? absoluteUrl;
    if (hasPic) {
      final raw = picUrl.toString();
      absoluteUrl =
          raw.startsWith('http') ? raw : 'http://127.0.0.1:8000$raw';
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPic
          ? Image.network(
              absoluteUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(getRoleIcon(), color: Colors.white, size: 36),
            )
          : Icon(getRoleIcon(), color: Colors.white, size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────
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
                topRight:    Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Sidebar Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        getRoleColor(),
                        getRoleColor().withAlpha(179),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      _sidebarAvatar(),
                      const SizedBox(height: 12),
                      Text(
                        widget.adminName,
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
                        getRoleTitle(),
                        style: TextStyle(
                          color: Colors.white.withAlpha(179),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _sidebarStat('Total',    totalCount.toString(),    Icons.format_list_numbered, getRoleColor()),
                      const SizedBox(height: 8),
                      _sidebarStat('Pending',  pendingCount.toString(),  Icons.pending_actions,      const Color(0xFFF59E0B)),
                      const SizedBox(height: 8),
                      _sidebarStat('Resolved', resolvedCount.toString(), Icons.check_circle,          const Color(0xFF10B981)),
                      const SizedBox(height: 8),
                      _sidebarStat('Rejected', rejectedCount.toString(), Icons.cancel,                const Color(0xFFDC2626)),
                    ],
                  ),
                ),

                const Divider(),

                // Menu Items
                // FIX: Each ListTile is wrapped in Material(color: transparent)
                // so that tileColor and ink splashes render correctly over the
                // parent Container's white background.
                Expanded(
                  child: ListView.builder(
                    itemCount: menuItems.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final item       = menuItems[index];
                      final isSelected = selectedIndex == index;

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Icon(
                            item['icon'] as IconData,
                            color: isSelected
                                ? getRoleColor()
                                : Colors.grey.shade500,
                            size: 22,
                          ),
                          title: Text(
                            item['title'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? getRoleColor()
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          tileColor:
                              isSelected ? getRoleColor().withAlpha(26) : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onTap: () {
                            if (item['filter'] == 'logout') {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const WelcomeScreen()),
                              );
                            } else {
                              setState(() => selectedIndex = index);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Main Content ─────────────────────────────────────────
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _sidebarStat(
      String title, String value, IconData icon, Color color) {
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
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (selectedIndex) {
      case 0:
        return AdminProfileScreen(
          adminRole:     widget.adminRole,
          adminName:     widget.adminName,
          adminUsername: widget.adminUsername,
        );
      case 1:
        return AdminRoleComplaintsScreen(
          adminRole: widget.adminRole,
          title: "All Complaints",
          filter: "all",
        );
      case 2:
        return AdminRoleComplaintsScreen(
          adminRole: widget.adminRole,
          title: "Pending Complaints",
          filter: "pending",
        );
      case 3:
        return AdminRoleComplaintsScreen(
          adminRole: widget.adminRole,
          title: "Resolved Complaints",
          filter: "resolved",
        );
      case 4:
        return AdminRoleRejectedComplaintsScreen(
          adminRole: widget.adminRole,
        );
      default:
        return const Center(child: Text('Select an option'));
    }
  }
}