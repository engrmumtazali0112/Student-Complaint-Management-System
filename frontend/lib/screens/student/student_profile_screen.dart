import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class StudentProfileScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentUsername;

  const StudentProfileScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentUsername,
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Map<String, dynamic>? studentData;
  List notifications = [];
  bool isLoading = true;
  bool isLoadingNotifications = false;
  bool isUploading = false;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    fetchStudentProfile();
    fetchNotifications();
  }

  Future<void> fetchStudentProfile() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse("http://localhost:8000/api/student/profile/${widget.studentUsername}/");
      debugPrint("Fetching profile from: $url");
      
      final response = await http.get(url);
      debugPrint("Profile response status: ${response.statusCode}");
      debugPrint("Profile response body: ${response.body}");
      
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            studentData = data['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          debugPrint("Error: ${data['message']}");
        }
      } else {
        setState(() => isLoading = false);
        debugPrint("Failed to fetch profile. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoadingNotifications = true);
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/student/dashboard/${widget.studentUsername}/'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          notifications = data['notifications'] ?? [];
          isLoadingNotifications = false;
        });
      } else {
        if (mounted) setState(() => isLoadingNotifications = false);
      }
    } catch (_) {
      if (mounted) setState(() => isLoadingNotifications = false);
    }
  }

  Future<void> pickAndUploadImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && mounted) {
        setState(() {
          _selectedImageBytes = result.files.single.bytes;
          isUploading = true;
        });

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://localhost:8000/api/student/upload-profile-pic/'),
        );
        request.fields['student_id'] = widget.studentUsername;

        var multipartFile = http.MultipartFile.fromBytes(
          'profile_picture',
          _selectedImageBytes!,
          filename: result.files.single.name,
        );
        request.files.add(multipartFile);

        final response = await request.send();

        if (!mounted) return;

        if (response.statusCode == 200) {
          await fetchStudentProfile();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        if (mounted) setState(() => isUploading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error uploading image'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isUploading = false);
      }
    }
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return 'http://localhost:8000$path';
  }

  @override
  Widget build(BuildContext context) {
    // Use actual data from API or fallback to defaults
    final profileData = studentData ?? {
      'name': widget.studentName,
      'student_id': widget.studentUsername,
      'father_name': 'Not provided',
      'department': 'Not assigned',
      'session': 'Not set',
      'email': 'Not provided',
      'phone': 'Not provided',
      'address': 'Not provided',
      'created_at': '2026',
      'profile_picture': null,
      'total_complaints': 0,
      'pending_complaints': 0,
      'resolved_complaints': 0,
      'rejected_complaints': 0,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  GestureDetector(
                    onTap: pickAndUploadImage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A365D), Color(0xFF2B6CB0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  shape: BoxShape.circle,
                                  image: profileData['profile_picture'] != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            _getImageUrl(profileData['profile_picture']),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: profileData['profile_picture'] == null
                                    ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.white.withAlpha(179),
                                      )
                                    : null,
                              ),
                              if (!isUploading)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(30),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Color(0xFF2B6CB0),
                                    ),
                                  ),
                                ),
                              if (isUploading)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            profileData['name'] ?? 'Student',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profileData['student_id'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha(179),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              profileData['department'] ?? 'Student',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap on profile picture to change',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatCard(
                        title: "Total",
                        value: (profileData['total_complaints'] ?? 0).toString(),
                        icon: Icons.format_list_numbered,
                        color: const Color(0xFF2B6CB0),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: "Pending",
                        value: (profileData['pending_complaints'] ?? 0).toString(),
                        icon: Icons.pending_actions,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: "Resolved",
                        value: (profileData['resolved_complaints'] ?? 0).toString(),
                        icon: Icons.check_circle,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: "Rejected",
                        value: (profileData['rejected_complaints'] ?? 0).toString(),
                        icon: Icons.cancel_outlined,
                        color: const Color(0xFFDC2626),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Profile Details Card
                  Container(
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
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildProfileRow(
                            label: 'Full Name',
                            value: profileData['name'] ?? 'N/A',
                            icon: Icons.person_outline,
                          ),
                          const Divider(height: 24),
                          _buildProfileRow(
                            label: 'Father Name',
                            value: profileData['father_name'] ?? 'Not provided',
                            icon: Icons.family_restroom_outlined,
                          ),
                          const Divider(height: 24),
                          _buildProfileRow(
                            label: 'Roll Number',
                            value: profileData['student_id'] ?? 'N/A',
                            icon: Icons.badge_outlined,
                          ),
                          const Divider(height: 24),
                          _buildProfileRow(
                            label: 'Department',
                            value: profileData['department'] ?? 'Not assigned',
                            icon: Icons.business_outlined,
                          ),
                          const Divider(height: 24),
                          _buildProfileRow(
                            label: 'Session',
                            value: profileData['session'] ?? 'Not set',
                            icon: Icons.calendar_today_outlined,
                          ),
                          const Divider(height: 24),
                          _buildProfileRow(
                            label: 'Phone',
                            value: profileData['phone'] ?? 'Not provided',
                            icon: Icons.phone_outlined,
                          ),
                          const Divider(height: 24),
                          _buildProfileRow(
                            label: 'Email',
                            value: profileData['email'] ?? 'Not provided',
                            icon: Icons.email_outlined,
                          ),
                          const Divider(height: 24),
                          _buildProfileRow(
                            label: 'Address',
                            value: profileData['address'] ?? 'Not provided',
                            icon: Icons.location_on_outlined,
                          ),
                          const Divider(height: 24),
                          _buildProfileRow(
                            label: 'Member Since',
                            value: profileData['created_at'] ?? '2026',
                            icon: Icons.calendar_month,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Notifications Section
                  Row(
                    children: [
                      const Icon(Icons.notifications_outlined,
                          color: Color(0xFF1A365D), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A365D),
                        ),
                      ),
                      const Spacer(),
                      if (notifications.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B6CB0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${notifications.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildNotifications(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildNotifications() {
    if (isLoadingNotifications) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ));
    }

    if (notifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.notifications_off_outlined,
                  color: Colors.grey.shade300, size: 40),
              const SizedBox(height: 8),
              Text(
                'No notifications yet',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ],
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
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
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
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2B6CB0).withAlpha(26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2B6CB0)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A365D)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}