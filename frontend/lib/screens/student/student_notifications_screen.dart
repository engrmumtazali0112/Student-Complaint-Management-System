import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StudentNotificationsScreen extends StatefulWidget {
  final String studentId;

  /// Called whenever the unread count changes so the sidebar badge updates.
  final ValueChanged<int>? onUnreadCountChanged;

  const StudentNotificationsScreen({
    super.key,
    required this.studentId,
    this.onUnreadCountChanged,
  });

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

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
            'http://127.0.0.1:8000/api/student/notifications/${widget.studentId}/'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final list = (data['notifications'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
        _notifyBadge();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markOneRead(int id) async {
    // Optimistic update
    setState(() {
      final idx = _notifications.indexWhere((n) => n['id'] == id);
      if (idx != -1) _notifications[idx]['is_read'] = true;
    });
    _notifyBadge();
    try {
      await http.post(Uri.parse(
          'http://127.0.0.1:8000/api/student/notifications/mark-read/$id/'));
      _fetchNotifications(); // Refresh after marking read
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllRead() async {
    setState(() {
      for (final n in _notifications) {
        n['is_read'] = true;
      }
    });
    _notifyBadge();
    try {
      await http.post(Uri.parse(
          'http://127.0.0.1:8000/api/student/notifications/mark-all-read/${widget.studentId}/'));
      _fetchNotifications(); // Refresh after marking all read
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  /// Fetch complaint detail from backend and show in bottom sheet.
  Future<void> _openComplaintDetail(int complaintId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComplaintDetailSheet(complaintId: complaintId),
    );
  }

  int get _unreadCount =>
      _notifications.where((n) => !(n['is_read'] as bool? ?? false)).length;

  void _notifyBadge() {
    widget.onUnreadCountChanged?.call(_unreadCount);
  }

  int? _complaintIdOf(Map<String, dynamic> n) {
    if (n['complaint_id'] != null) {
      final v = n['complaint_id'];
      if (v is int) return v;
      return int.tryParse(v.toString());
    }
    final msg = n['message'] as String? ?? '';
    final match = RegExp(r'#(\d+)').firstMatch(msg);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  void _onTapNotification(Map<String, dynamic> notification) {
    final id = notification['id'] as int;
    if (!(notification['is_read'] as bool? ?? false)) {
      _markOneRead(id);
    }
    final complaintId = _complaintIdOf(notification);
    if (complaintId != null) {
      _openComplaintDetail(complaintId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Color(0xFF2B6CB0),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
                  : Column(
                      children: [
                        if (_unreadCount > 0) _buildUnreadBanner(),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notifications.length,
                            itemBuilder: (context, i) =>
                                _buildCard(_notifications[i]),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none,
                  size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No notifications yet',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                "You'll be notified when your\ncomplaint status changes.",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnreadBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: const Color(0xFF2B6CB0).withAlpha(20),
      child: Text(
        '$_unreadCount unread notification${_unreadCount > 1 ? 's' : ''}',
        style: const TextStyle(
          color: Color(0xFF2B6CB0),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] as bool? ?? false;
    final message = notification['message'] as String? ?? '';
    final createdAt = notification['created_at'] as String? ?? '';
    final hasLink = _complaintIdOf(notification) != null;

    final bool isResolved =
        message.contains('resolved') || message.contains('✅');
    final bool isRejected =
        message.contains('rejected') || message.contains('❌');

    final Color accent = isResolved
        ? const Color(0xFF10B981)
        : isRejected
            ? const Color(0xFFDC2626)
            : const Color(0xFF2B6CB0);

    final IconData notifIcon = isResolved
        ? Icons.check_circle_outline
        : isRejected
            ? Icons.cancel_outlined
            : Icons.notifications_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : accent.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: isRead
            ? null
            : Border.all(color: accent.withAlpha(60), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTapNotification(notification),
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
                  child: Icon(notifIcon, color: accent, size: 22),
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
                          fontWeight:
                              isRead ? FontWeight.normal : FontWeight.w600,
                          color: const Color(0xFF1A365D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            createdAt,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                          if (hasLink) ...[
                            const SizedBox(width: 10),
                            Text(
                              'View details →',
                              style: TextStyle(
                                fontSize: 11,
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Complaint detail bottom sheet
class _ComplaintDetailSheet extends StatefulWidget {
  final int complaintId;
  const _ComplaintDetailSheet({required this.complaintId});

  @override
  State<_ComplaintDetailSheet> createState() => _ComplaintDetailSheetState();
}

class _ComplaintDetailSheetState extends State<_ComplaintDetailSheet> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/api/complaint/${widget.complaintId}/'),
      );
      if (response.statusCode == 200 && mounted) {
        final body = jsonDecode(response.body);
        setState(() {
          _data = body['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load complaint details.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error.';
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'resolved': return const Color(0xFF10B981);
      case 'rejected': return const Color(0xFFDC2626);
      default:         return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Complaint Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A365D),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(
                          child: Text(_error,
                              style: TextStyle(color: Colors.grey.shade500)))
                      : ListView(
                          controller: controller,
                          padding: const EdgeInsets.all(20),
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _statusColor(_data!['status'])
                                        .withAlpha(25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: _statusColor(_data!['status'])
                                            .withAlpha(80)),
                                  ),
                                  child: Text(
                                    (_data!['status'] as String? ?? '')
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColor(_data!['status']),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _row('Title',
                                _data!['title'] ?? _data!['complaint_type']),
                            _row('Type', _data!['complaint_type']),
                            _row('Department', _data!['department']),
                            _row('Session', _data!['session']),
                            _row('Roll Number', _data!['roll_number']),
                            _row('Submitted', _data!['submitted_on']),
                            if (_data!['resolved_at'] != null)
                              _row('Resolved On', _data!['resolved_at']),
                            if (_data!['rejection_remarks'] != null)
                              _row('Rejection Reason',
                                  _data!['rejection_remarks']),
                            const SizedBox(height: 12),
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A365D),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4F8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _data!['description'] ?? '',
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF1A365D)),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '—',
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A365D)),
            ),
          ),
        ],
      ),
    );
  }
}