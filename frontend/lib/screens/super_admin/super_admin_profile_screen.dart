// lib/screens/super_admin/super_admin_profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';

class SuperAdminProfileScreen extends StatefulWidget {
  final String username;
  const SuperAdminProfileScreen({super.key, required this.username});

  @override
  State<SuperAdminProfileScreen> createState() => _SuperAdminProfileScreenState();
}

class _SuperAdminProfileScreenState extends State<SuperAdminProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminProfile}${widget.username}/'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _profileData = data['data'];
          _loading = false;
        });
      } else {
        setState(() { _error = 'Failed to load profile'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Network error'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Super Admin Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.admin_panel_settings, size: 50, color: Color(0xFF1565C0)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _profileData?['name'] ?? 'Super Admin',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profileData?['username'] ?? widget.username,
                              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Super Administrator', style: TextStyle(fontSize: 12, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Profile Details
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10)],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildInfoRow(Icons.person_outline, 'Full Name', _profileData?['name'] ?? 'Super Admin'),
                              const Divider(height: 24),
                              _buildInfoRow(Icons.badge_outlined, 'Username', _profileData?['username'] ?? widget.username),
                              const Divider(height: 24),
                              _buildInfoRow(Icons.admin_panel_settings, 'Role', 'Super Administrator'),
                              const Divider(height: 24),
                              _buildInfoRow(Icons.email_outlined, 'Email', _profileData?['email'] ?? 'admin@complaintsystem.com'),
                              const Divider(height: 24),
                              _buildInfoRow(Icons.phone_outlined, 'Phone', _profileData?['phone'] ?? '+92 XXX XXXXXXX'),
                              const Divider(height: 24),
                              _buildInfoRow(Icons.calendar_today, 'Member Since', _profileData?['created_at'] ?? '2026'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF1565C0), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A365D))),
            ],
          ),
        ),
      ],
    );
  }
}