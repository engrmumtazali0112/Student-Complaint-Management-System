import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'view_complains.dart';

/// Student-facing page that lists all their REJECTED complaints,
/// showing the admin's rejection remarks for each one.
class StudentRejectedComplaintsScreen extends StatefulWidget {
  final String studentId;

  const StudentRejectedComplaintsScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentRejectedComplaintsScreen> createState() =>
      _StudentRejectedComplaintsScreenState();
}

class _StudentRejectedComplaintsScreenState
    extends State<StudentRejectedComplaintsScreen> {
  List complaints = [];
  bool isLoading  = true;

  @override
  void initState() {
    super.initState();
    fetchRejectedComplaints();
  }

  Future<void> fetchRejectedComplaints() async {
    setState(() => isLoading = true);
    try {
      // Re-use the track endpoint and filter client-side for 'rejected'
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/api/student/complaint/track/${widget.studentId}/'),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final all  = List<Map<String, dynamic>>.from(data['data'] ?? []);

        setState(() {
          complaints = all
              .where((c) =>
                  (c['status'] ?? '').toString().toLowerCase() == 'rejected')
              .toList();
          isLoading = false;
        });
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
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
        title: const Text(
          'Rejected Complaints',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A365D)),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: fetchRejectedComplaints,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : complaints.isEmpty
                ? _buildEmpty()
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 20),
                      const Text(
                        'Your Rejected Complaints',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A365D)),
                      ),
                      const SizedBox(height: 12),
                      ...complaints.map((c) => _buildCard(c)),
                    ],
                  ),
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 80, color: Colors.green.shade300),
              const SizedBox(height: 16),
              const Text(
                'No rejected complaints!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A365D)),
              ),
              const SizedBox(height: 8),
              Text(
                'None of your complaints have been rejected.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Summary Card ────────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.cancel_outlined,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                complaints.length.toString(),
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1),
              ),
              Text(
                'Rejected Complaints',
                style:
                    TextStyle(fontSize: 13, color: Colors.white.withAlpha(200)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Complaint Card ──────────────────────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> c) {
    final title     = c['title']?.toString() ?? c['complaint_type'] ?? 'Complaint';
    final id        = c['id'];
    final createdAt = c['created_at'] ?? '';
    // remarks come from the detail endpoint; track only has basic fields.
    // We show them if available, otherwise prompt user to tap View Details.
    final remarks   = c['rejection_remarks']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Red top strip ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined,
                    color: Color(0xFFDC2626), size: 14),
                const SizedBox(width: 6),
                const Text('REJECTED',
                    style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8)),
                const Spacer(),
                if (createdAt.isNotEmpty)
                  Text('Submitted: $createdAt',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + ID
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.report_problem_outlined,
                          color: Color(0xFFDC2626), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A365D)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text('ID: #$id',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Rejection Reason Box ──────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.comment_outlined,
                              size: 14, color: Color(0xFFDC2626)),
                          SizedBox(width: 6),
                          Text('Admin Rejection Reason',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        remarks ?? 'Tap "View Details" to see the full reason.',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1A365D),
                            height: 1.45),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── View Details button ───────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewComplaintDetailsScreen(
                          complaintId: id,
                          studentId: widget.studentId,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDC2626)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined,
                              size: 15, color: Color(0xFFDC2626)),
                          SizedBox(width: 5),
                          Text('View Details',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}