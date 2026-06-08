import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'student_submit_complaint.dart';
import 'student_track_complaints.dart';
import 'student_rejected_complaints.dart';
import 'student_resolved_complaints.dart';
import 'student_login.dart';

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
  int _selectedIndex = 0;
  String? profilePictureUrl;
  Map<String, dynamic> studentData = {};
  bool isLoading = true;

  // Different screens for each menu item
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/student/profile/${widget.studentId}/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            studentData = data['data'];
            profilePictureUrl = studentData['profile_picture'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      setState(() => isLoading = false);
    }
  }

  void _onMenuItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize screens with current student data
    _screens.clear();
    _screens.addAll([
      DashboardContent(
        studentId: widget.studentId,
        studentName: widget.studentName,
        studentData: studentData,
        profilePictureUrl: profilePictureUrl,
        onProfileUpdate: fetchStudentData,
      ),
      SubmitComplaintScreen(studentId: widget.studentId),
      TrackComplaintsScreen(studentId: widget.studentId),
      StudentRejectedComplaintsScreen(studentId: widget.studentId),
      StudentResolvedComplaintsScreen(studentId: widget.studentId),
    ]);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A365D), Color(0xFF2B6CB0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Profile Section
                GestureDetector(
                  onTap: () => _showProfilePictureOptions(),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      image: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(profilePictureUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: profilePictureUrl == null || profilePictureUrl!.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                        : null,
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
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.studentId,
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24, thickness: 1),
                const SizedBox(height: 20),
                // Menu Items
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: "Dashboard",
                  index: 0,
                ),
                _buildMenuItem(
                  icon: Icons.add_circle_outline,
                  title: "Submit Complaint",
                  index: 1,
                ),
                _buildMenuItem(
                  icon: Icons.track_changes,
                  title: "Track Complaints",
                  index: 2,
                ),
                _buildMenuItem(
                  icon: Icons.cancel_outlined,
                  title: "Rejected Complaints",
                  index: 3,
                ),
                _buildMenuItem(
                  icon: Icons.check_circle_outline,
                  title: "Resolved Complaints",
                  index: 4,
                ),
                const Spacer(),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: "Logout",
                  index: -1,
                  isLogout: true,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
    bool isLogout = false,
  }) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF2B6CB0) : Colors.white70,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF2B6CB0) : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        tileColor: isSelected ? Colors.white : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () {
          if (isLogout) {
            _logout();
          } else {
            _onMenuItemTapped(index);
          }
        },
      ),
    );
  }

  void _showProfilePictureOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Text(
              "Profile Picture",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Color(0xFF2B6CB0)),
              title: const Text("Change Profile Picture"),
              onTap: () {
                Navigator.pop(context);
                _changeProfilePicture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text("Remove Profile Picture"),
              onTap: () {
                Navigator.pop(context);
                _removeProfilePicture();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _changeProfilePicture() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile picture update feature coming soon"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _removeProfilePicture() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Remove profile picture feature coming soon"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _logout() {
    // Navigate back to login screen without using SharedPreferences
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const StudentLoginScreen()),
      (route) => false,
    );
  }
}

// Dashboard Content Widget
class DashboardContent extends StatelessWidget {
  final String studentId;
  final String studentName;
  final Map<String, dynamic> studentData;
  final String? profilePictureUrl;
  final VoidCallback onProfileUpdate;

  const DashboardContent({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentData,
    this.profilePictureUrl,
    required this.onProfileUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A365D), Color(0xFF2B6CB0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back,",
                        style: TextStyle(
                          color: Colors.white.withAlpha(179),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        studentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        studentId,
                        style: TextStyle(
                          color: Colors.white.withAlpha(179),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showFullProfile(context),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                        ? NetworkImage(profilePictureUrl!)
                        : null,
                    child: profilePictureUrl == null || profilePictureUrl!.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF2B6CB0),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Cards
          Row(
            children: [
              _buildStatCard(
                title: "Total",
                value: "${studentData['total_complaints'] ?? 0}",
                icon: Icons.description,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: "Pending",
                value: "${studentData['pending_complaints'] ?? 0}",
                icon: Icons.pending_actions,
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                title: "Resolved",
                value: "${studentData['resolved_complaints'] ?? 0}",
                icon: Icons.check_circle,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: "Rejected",
                value: "${studentData['rejected_complaints'] ?? 0}",
                icon: Icons.cancel,
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Profile Information Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(30),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "Profile Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A365D),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _buildInfoRow("Full Name", studentData['name'] ?? 'Not provided'),
                _buildInfoRow("Father Name", studentData['father_name'] ?? 'Not provided'),
                _buildInfoRow("Roll Number", studentData['student_id'] ?? studentId),
                _buildInfoRow("Department", studentData['department'] ?? 'Not assigned'),
                _buildInfoRow("Session", studentData['session'] ?? 'Not set'),
                _buildInfoRow("Email", studentData['email'] ?? 'Not provided'),
                _buildInfoRow("Phone", studentData['phone'] ?? 'Not provided'),
                _buildInfoRow("Address", studentData['address'] ?? 'Not provided'),
              ],
            ),
          ),
        ],
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(30),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A365D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A365D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Profile Picture"),
        content: SizedBox(
          width: 200,
          height: 200,
          child: ClipOval(
            child: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                ? Image.network(
                    profilePictureUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, size: 100);
                    },
                  )
                : const Icon(Icons.person, size: 100),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
