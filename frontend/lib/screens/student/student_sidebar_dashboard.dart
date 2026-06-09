import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'student_submit_complaint.dart';
import 'student_track_complaints.dart';
import 'student_rejected_complaints.dart';
import 'student_resolved_complaints.dart';
import 'student_profile_screen.dart';
import 'student_login.dart';

class StudentSidebarDashboard extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentUsername;

  const StudentSidebarDashboard({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentUsername,
  });

  @override
  State<StudentSidebarDashboard> createState() => _StudentSidebarDashboardState();
}

class _StudentSidebarDashboardState extends State<StudentSidebarDashboard> {
  int _selectedIndex = 0;
  String? profilePictureUrl;
  Map<String, dynamic> studentData = {};
  bool isLoading = true;

  // Badge counts
  int _newResolvedCount = 0;
  int _newRejectedCount = 0;
  int _prevResolved = 0;
  int _prevRejected = 0;
  bool _firstFetch = true;

  final Color _studentColor     = const Color(0xFF2B6CB0);
  final Color _studentDarkColor = const Color(0xFF1A365D);

  // ── Menu items (Dashboard removed) ─────────────────────────────────────────
  static const List<Map<String, dynamic>> _menuItems = [
    {'title': 'Profile',             'icon': Icons.person_outline},
    {'title': 'Submit Complaint',    'icon': Icons.add_circle_outline},
    {'title': 'Track Complaints',    'icon': Icons.track_changes_outlined},
    {'title': 'Rejected Complaints', 'icon': Icons.cancel_outlined},
    {'title': 'Resolved Complaints', 'icon': Icons.check_circle_outline},
    {'title': 'Logout',              'icon': Icons.logout},
  ];

  @override
  void initState() {
    super.initState();
    fetchStudentData();
    _startPolling();
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        fetchStudentData(showLoading: false);
        _startPolling();
      }
    });
  }

  Future<void> fetchStudentData({bool showLoading = true}) async {
    if (showLoading) setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/student/dashboard/${widget.studentId}/'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final int currentResolved = (data['stats']['resolved'] as num).toInt();
          final int currentRejected = (data['stats']['rejected'] as num).toInt();

          setState(() {
            studentData = {
              'total_complaints':    data['stats']['total'],
              'pending_complaints':  data['stats']['pending'],
              'resolved_complaints': currentResolved,
              'rejected_complaints': currentRejected,
              'name':       data['student']['name'],
              'student_id': data['student']['student_id'],
              'department': data['student']['department'],
            };
            profilePictureUrl = data['student']['profile_picture'];
            isLoading = false;

            if (_firstFetch) {
              _prevResolved = currentResolved;
              _prevRejected = currentRejected;
              _firstFetch   = false;
            } else {
              final deltaResolved = currentResolved - _prevResolved;
              final deltaRejected = currentRejected - _prevRejected;
              if (deltaResolved > 0) _newResolvedCount += deltaResolved;
              if (deltaRejected > 0) _newRejectedCount += deltaRejected;
              _prevResolved = currentResolved;
              _prevRejected = currentRejected;
            }
          });
        } else {
          if (showLoading) setState(() => isLoading = false);
        }
      } else {
        if (showLoading) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching student data: $e");
      if (showLoading && mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchStudentProfile() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/student/profile/${widget.studentId}/'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() => profilePictureUrl = data['data']['profile_picture']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile picture: $e");
    }
  }

  // index mapping (no Dashboard):
  // 0 Profile | 1 Submit | 2 Track | 3 Rejected | 4 Resolved | 5 Logout
  int _badgeFor(int index) {
    if (index == 3) return _newRejectedCount;
    if (index == 4) return _newResolvedCount;
    return 0;
  }

  Color _badgeColorFor(int index) {
    if (index == 4) return const Color(0xFF10B981); // green for resolved
    return const Color(0xFFEF4444);                  // red for rejected
  }

  void _onMenuTap(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 3) _newRejectedCount = 0;
      if (index == 4) _newResolvedCount  = 0;
    });
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
      (route) => false,
    );
  }

  Widget _sidebarAvatar() {
    final bool hasPic = profilePictureUrl != null && profilePictureUrl!.isNotEmpty;
    final String? absoluteUrl = hasPic
        ? (profilePictureUrl!.startsWith('http') ? profilePictureUrl! : 'http://127.0.0.1:8000$profilePictureUrl')
        : null;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(color: Colors.white.withAlpha(30), shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: hasPic
          ? Image.network(absoluteUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 36))
          : const Icon(Icons.person, color: Colors.white, size: 36),
    );
  }

  Widget _sidebarStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Screens aligned to menu indices (no Dashboard screen)
    // 0 Profile | 1 Submit | 2 Track | 3 Rejected | 4 Resolved
    final List<Widget> screens = [
      StudentProfileScreen(
        studentId: widget.studentId,
        studentName: widget.studentName,
        studentUsername: widget.studentUsername,
      ),
      SubmitComplaintScreen(studentId: widget.studentId),
      TrackComplaintsScreen(studentId: widget.studentId),
      StudentRejectedComplaintsScreen(studentId: widget.studentId),
      StudentResolvedComplaintsScreen(studentId: widget.studentId),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────────
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withAlpha(20), blurRadius: 10, offset: const Offset(2, 0))],
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Gradient header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_studentDarkColor, _studentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      _sidebarAvatar(),
                      const SizedBox(height: 12),
                      Text(
                        widget.studentName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text('Student Portal', style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 12)),
                    ],
                  ),
                ),

                // Stats
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _sidebarStat('Total',    studentData['total_complaints']?.toString()    ?? '0', Icons.format_list_numbered, _studentColor),
                      const SizedBox(height: 8),
                      _sidebarStat('Pending',  studentData['pending_complaints']?.toString()  ?? '0', Icons.pending_actions,      const Color(0xFFF59E0B)),
                      const SizedBox(height: 8),
                      _sidebarStat('Resolved', studentData['resolved_complaints']?.toString() ?? '0', Icons.check_circle,         const Color(0xFF10B981)),
                      const SizedBox(height: 8),
                      _sidebarStat('Rejected', studentData['rejected_complaints']?.toString() ?? '0', Icons.cancel,               const Color(0xFFDC2626)),
                    ],
                  ),
                ),
                const Divider(),

                // Menu
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final item       = _menuItems[index];
                      final isSelected = _selectedIndex == index;
                      final badge      = _badgeFor(index);
                      final badgeColor = _badgeColorFor(index);

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                color: isSelected ? _studentColor : Colors.grey.shade500,
                                size: 22,
                              ),
                              if (badge > 0)
                                Positioned(
                                  top: -4, right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                    decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                                    child: Text(
                                      badge > 9 ? '9+' : '$badge',
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            item['title'] as String,
                            style: TextStyle(
                              color: isSelected ? _studentColor : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          tileColor: isSelected ? _studentColor.withAlpha(26) : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onTap: () {
                            if (item['title'] == 'Logout') {
                              _logout();
                            } else {
                              _onMenuTap(index);
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

          // Main Content
          Expanded(child: screens[_selectedIndex.clamp(0, screens.length - 1)]),
        ],
      ),
    );
  }
}