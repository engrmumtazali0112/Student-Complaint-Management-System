import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class AdminProfileScreen extends StatefulWidget {
  final String adminRole;
  final String adminName;
  final String adminUsername;

  const AdminProfileScreen({
    super.key,
    required this.adminRole,
    required this.adminName,
    required this.adminUsername,
  });

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  Map<String, dynamic>? adminData;
  List _notifications = [];
  bool isLoading = true;
  bool isLoadingNotifications = false;
  bool isUploading = false;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    fetchAdminProfile();
    fetchNotifications();
  }

  Future<void> fetchAdminProfile() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
            "http://localhost:8000/api/admin/profile/${widget.adminUsername}/"),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          adminData = data['data'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoadingNotifications = true);
    try {
      final response = await http.get(
        Uri.parse(
            "http://localhost:8000/api/admin/notifications/?admin_type=${widget.adminRole}"),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _notifications = data['notifications'] ?? [];
          isLoadingNotifications = false;
        });
      } else {
        if (mounted) setState(() => isLoadingNotifications = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingNotifications = false);
    }
  }

  Future<void> pickAndUploadImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && mounted) {
        setState(() {
          _selectedImageBytes = result.files.single.bytes;
          isUploading = true;
        });

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://127.0.0.1:8000/api/admin/upload-profile-pic/'),
        );

        request.fields['username'] = widget.adminUsername;

        var multipartFile = http.MultipartFile.fromBytes(
          'profile_picture',
          _selectedImageBytes!,
          filename: result.files.single.name,
        );

        request.files.add(multipartFile);

        final response = await request.send();

        if (!mounted) return;

        if (response.statusCode == 200) {
          await fetchAdminProfile();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated!'),
                backgroundColor: Colors.green,
              ),
            );
          }
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

  String getRoleTitle() {
    switch (widget.adminRole) {
      case 'warden':      return 'Warden';
      case 'examination': return 'Examination Officer';
      case 'treasury':    return 'Treasury Officer';
      case 'security':    return 'Security Officer';
      case 'transport':   return 'Transport Officer';
      case 'library':     return 'Librarian';
      case 'hostel':      return 'Hostel Manager';
      case 'sports':      return 'Sports Officer';
      case 'it':          return 'IT Administrator';
      default:            return 'Administrator';
    }
  }

  /// Renders profile picture correctly for both absolute and relative URLs.
  Widget _buildProfileAvatar(Map<String, dynamic> profileData) {
    final picUrl = profileData['profile_picture'];
    final bool hasPic = picUrl != null && picUrl.toString().isNotEmpty;

    String? absoluteUrl;
    if (hasPic) {
      final raw = picUrl.toString();
      absoluteUrl = raw.startsWith('http') ? raw : 'http://127.0.0.1:8000$raw';
    }

    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: hasPic
          ? Image.network(
              absoluteUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.white.withAlpha(30),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 50,
                  color: Colors.white.withAlpha(179),
                ),
              ),
            )
          : Container(
              color: Colors.white.withAlpha(30),
              child: Icon(
                Icons.admin_panel_settings,
                size: 50,
                color: Colors.white.withAlpha(179),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileData = adminData ?? {
      'name':            widget.adminName,
      'username':        widget.adminUsername,
      'role':            widget.adminRole,
      'email':           '',
      'phone':           'Not provided',
      'department':      'Not assigned',
      'address':         'Not provided',
      'created_at':      '2026',
      'profile_picture': null,
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
                  // ── Profile Header ─────────────────────────────
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
                              _buildProfileAvatar(profileData),
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
                            profileData['name'] ?? widget.adminName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profileData['username'] ?? widget.adminUsername,
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
                              getRoleTitle(),
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

                  // ── Profile Details Card ───────────────────────
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
                            label: 'Username',
                            value: profileData['username'] ?? 'N/A',
                            icon: Icons.badge_outlined,
                          ),
                          const Divider(height: 24),
                          _buildProfileRow(
                            label: 'Role',
                            value: getRoleTitle(),
                            icon: Icons.admin_panel_settings,
                          ),
                          const Divider(height: 24),
                          _buildProfileRow(
                            label: 'Department',
                            value: profileData['department'] ?? 'Not assigned',
                            icon: Icons.business_outlined,
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
                            value: profileData['email'] != null &&
                                    profileData['email'] != ''
                                ? profileData['email']
                                : 'Not provided',
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

                  // ── Notifications Section ──────────────────────
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
                      if (_notifications.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B6CB0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_notifications.length}',
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
        ),
      );
    }

    if (_notifications.isEmpty) {
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
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _notifications.map<Widget>((n) {
        final isResolved = (n['message'] ?? '').toString().contains('resolved');
        final notifColor =
            isResolved ? const Color(0xFF10B981) : const Color(0xFFDC2626);
        final notifIcon =
            isResolved ? Icons.check_circle_outline : Icons.cancel_outlined;

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
                  color: notifColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(notifIcon, color: notifColor, size: 18),
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
                      n['created_at'] ?? '',
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