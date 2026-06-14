import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import 'super_admin_dashboard.dart';
import 'super_admin_escalated_screen.dart';
import 'super_admin_ratings_screen.dart';
import 'super_admin_profile_screen.dart';

class SuperAdminSidebarDashboard extends StatefulWidget {
  final String username;
  const SuperAdminSidebarDashboard({super.key, required this.username});

  @override
  State<SuperAdminSidebarDashboard> createState() => _SuperAdminSidebarDashboardState();
}

class _SuperAdminSidebarDashboardState extends State<SuperAdminSidebarDashboard> {
  int _selectedIndex = 0;
  int _totalCount = 0;
  int _pendingCount = 0;
  int _resolvedCount = 0;
  int _rejectedCount = 0;
  bool _loadingStats = true;

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard, 'screen': 'dashboard'},
    {'title': 'Profile', 'icon': Icons.person_outline, 'screen': 'profile'},
    {'title': 'Escalated Complaints', 'icon': Icons.warning_amber, 'screen': 'escalated'},
    {'title': 'Admin Ratings', 'icon': Icons.star_outline, 'screen': 'ratings'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/super-admin/stats/'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final overall = data['overall'] ?? {};
        setState(() {
          _totalCount = overall['total'] ?? 0;
          _pendingCount = overall['pending'] ?? 0;
          _resolvedCount = overall['resolved'] ?? 0;
          _rejectedCount = overall['rejected'] ?? 0;
          _loadingStats = false;
        });
      } else {
        setState(() => _loadingStats = false);
      }
    } catch (e) {
      setState(() => _loadingStats = false);
    }
  }

  Widget _getSelectedScreen() {
    switch (_menuItems[_selectedIndex]['screen']) {
      case 'dashboard':
        return SuperAdminDashboard(username: widget.username);
      case 'profile':
        return SuperAdminProfileScreen(username: widget.username);
      case 'escalated':
        return const SuperAdminEscalatedScreen();
      case 'ratings':
        return const SuperAdminRatingsScreen();
      default:
        return SuperAdminDashboard(username: widget.username);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(2, 0))],
              borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
                    borderRadius: BorderRadius.only(topRight: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.admin_panel_settings, size: 45, color: Color(0xFF1565C0)),
                      ),
                      const SizedBox(height: 12),
                      const Text('Super Admin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.username, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                      const SizedBox(height: 16),
                      if (!_loadingStats)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatBadge('Total', _totalCount),
                              _buildStatBadge('Pending', _pendingCount),
                              _buildStatBadge('Resolved', _resolvedCount),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected = _selectedIndex == index;
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Icon(item['icon'] as IconData, color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade600),
                          title: Text(item['title'] as String, style: TextStyle(
                            color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          )),
                          tileColor: isSelected ? const Color(0xFF1565C0).withValues(alpha: 0.1) : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onTap: () => setState(() => _selectedIndex = index),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(child: _getSelectedScreen()),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int count) {
    return Column(
      children: [
        Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10)),
      ],
    );
  }
}