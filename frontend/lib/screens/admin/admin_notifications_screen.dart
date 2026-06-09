import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../shared/welcome.dart'; // optional, for back button

class AdminNotificationsScreen extends StatefulWidget {
  final String adminType;
  final String adminUsername;

  const AdminNotificationsScreen({
    super.key,
    required this.adminType,
    required this.adminUsername,
  });

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  // Local read tracking (since backend doesn't persist admin notification read status)
  final Set<int> _readComplaintIds = {};

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/api/admin/notifications/?admin_type=${widget.adminType}'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final List list = data['notifications'] ?? [];
        setState(() {
          _notifications = list.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching admin notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  void _markAsRead(int complaintId) {
    setState(() {
      _readComplaintIds.add(complaintId);
    });
    // Optionally call backend mark‑seen endpoint
    http.post(
      Uri.parse('http://127.0.0.1:8000/api/admin/mark-seen/'),
      body: {'complaint_id': complaintId},
    ).catchError((e) => debugPrint('Mark seen error: $e'));
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        final cid = n['complaint_id'];
        if (cid != null) _readComplaintIds.add(cid);
      }
    });
    // Optional: call mark‑seen without specific id (marks all)
    http.post(
      Uri.parse('http://127.0.0.1:8000/api/admin/mark-seen/'),
    ).catchError((e) => debugPrint('Mark all seen error: $e'));
  }

  int get _unreadCount {
    return _notifications.where((n) {
      final cid = n['complaint_id'];
      return cid != null && !_readComplaintIds.contains(cid);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A365D),
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Color(0xFF2B6CB0), fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: _notifications.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (_, i) => _buildCard(_notifications[i]),
                    ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No notifications', style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text('New complaints or status updates will appear here',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> notification) {
    final int? complaintId = notification['complaint_id'] as int?;
    final bool isRead = complaintId != null && _readComplaintIds.contains(complaintId);
    final String message = notification['message'] ?? '';
    final String createdAt = notification['created_at'] ?? '';
    final bool isResolved = message.contains('resolved') || message.contains('✅');
    final bool isRejected = message.contains('rejected') || message.contains('❌');
    final Color accent = isResolved
        ? const Color(0xFF10B981)
        : isRejected
            ? const Color(0xFFDC2626)
            : const Color(0xFF2B6CB0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : accent.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: isRead ? null : Border.all(color: accent.withAlpha(60), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isRead && complaintId != null) {
              _markAsRead(complaintId);
            }
            // Optionally navigate to complaint details
            if (complaintId != null) {
              _showComplaintDetails(context, complaintId);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(isRead ? 20 : 35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isResolved ? Icons.check_circle_outline : (isRejected ? Icons.cancel_outlined : Icons.notifications_outlined),
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                          color: const Color(0xFF1A365D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(createdAt, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComplaintDetails(BuildContext context, int complaintId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComplaintDetailSheet(complaintId: complaintId),
    );
  }
}

// Simple complaint detail bottom sheet (same as student version)
class _ComplaintDetailSheet extends StatefulWidget {
  final int complaintId;
  const _ComplaintDetailSheet({required this.complaintId});

  @override
  State<_ComplaintDetailSheet> createState() => _ComplaintDetailSheetState();
}

class _ComplaintDetailSheetState extends State<_ComplaintDetailSheet> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/complaint/${widget.complaintId}/'),
      );
      if (response.statusCode == 200 && mounted) {
        final body = jsonDecode(response.body);
        setState(() {
          _data = body['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _data == null
                ? const Center(child: Text('Failed to load complaint'))
                : ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_data!['status']).withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (_data!['status'] as String).toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(_data!['status']),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _row('Title', _data!['title'] ?? _data!['complaint_type']),
                      _row('Type', _data!['complaint_type']),
                      _row('Department', _data!['department']),
                      _row('Student', _data!['student_name']),
                      _row('Roll Number', _data!['roll_number']),
                      _row('Submitted', _data!['submitted_on']),
                      if (_data!['resolved_at'] != null)
                        _row('Resolved On', _data!['resolved_at']),
                      if (_data!['rejection_remarks'] != null)
                        _row('Rejection Reason', _data!['rejection_remarks']),
                      const SizedBox(height: 12),
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_data!['description'] ?? ''),
                      ),
                    ],
                  ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(child: Text(value?.toString() ?? '—')),
        ],
      ),
    );
  }
}