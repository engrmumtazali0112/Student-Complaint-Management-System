import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'view_complains.dart';

// ─── Brand Colors ──────────────────────────────────────────────────────────────
class _C {
  static const pageBg      = Color(0xFFF0F4FA);
  static const cardBg      = Colors.white;
  static const darkNavy    = Color(0xFF0F1E38);
  static const navy        = Color(0xFF1A365D);
  static const mutedBlue   = Color(0xFF4F6FA5);
  static const border      = Color(0xFFD8E0EF);

  static const metaGray    = Color(0xFF8B9DC3);
  static const searchHint  = Color(0xFFA8B4CC);

  static const rejectedBg  = Color(0xFFFEF2F2);
  static const rejectedBdr = Color(0xFFFECACA);
  static const rejectedTxt = Color(0xFFDC2626);

}

class RejectedComplaintsScreen extends StatefulWidget {
  const RejectedComplaintsScreen({super.key});

  @override
  State<RejectedComplaintsScreen> createState() => _RejectedComplaintsScreenState();
}

class _RejectedComplaintsScreenState extends State<RejectedComplaintsScreen> {
  List complaints = [];
  bool isLoading  = true;

  @override
  void initState() {
    super.initState();
    fetchRejectedComplaints();
  }

  Future<void> fetchRejectedComplaints({String query = ''}) async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/admin/complaint/rejected/?search=$query'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          complaints = data['data'];
          isLoading  = false;
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
      backgroundColor: _C.pageBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSummaryCard(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildListHeader(),
              const SizedBox(height: 12),
              _buildList(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _C.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.border, width: 0.5),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: _C.navy),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rejected Complaints',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: _C.darkNavy, letterSpacing: -0.3)),
              Text('Complaints rejected with admin remarks',
                  style: TextStyle(fontSize: 12, color: _C.metaGray)),
            ],
          ),
        ),
        // Total badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _C.rejectedBg,
            border: Border.all(color: _C.rejectedBdr),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel_outlined, color: _C.rejectedTxt, size: 14),
              const SizedBox(width: 5),
              Text('${complaints.length}',
                  style: const TextStyle(color: _C.rejectedTxt,
                      fontWeight: FontWeight.w700, fontSize: 13)),
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
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.cancel_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                complaints.length.toString(),
                style: const TextStyle(
                    fontSize: 42, fontWeight: FontWeight.w800,
                    color: Colors.white, height: 1),
              ),
              Text(
                'Total Rejected Complaints',
                style: TextStyle(
                    fontSize: 13, color: Colors.white.withAlpha(200)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border, width: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: _C.metaGray, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => fetchRejectedComplaints(query: v),
              style: const TextStyle(fontSize: 14, color: _C.darkNavy),
              decoration: const InputDecoration(
                hintText: 'Search by ID, title, student, or reason...',
                hintStyle: TextStyle(color: _C.searchHint, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── List Header ─────────────────────────────────────────────────────────────
  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('REJECTED LIST',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 1.2, color: _C.metaGray.withAlpha(200))),
        Text('${complaints.length} items',
            style: const TextStyle(fontSize: 12, color: _C.metaGray)),
      ],
    );
  }

  // ── List ────────────────────────────────────────────────────────────────────
  Widget _buildList() {
    return Expanded(
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: _C.rejectedTxt))
          : complaints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 72, color: _C.metaGray.withAlpha(80)),
                      const SizedBox(height: 14),
                      const Text('No rejected complaints',
                          style: TextStyle(color: _C.metaGray, fontSize: 15)),
                      const SizedBox(height: 6),
                      const Text('All complaints are pending or resolved',
                          style: TextStyle(color: _C.metaGray, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: complaints.length,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemBuilder: (context, index) =>
                      _buildCard(complaints[index]),
                ),
    );
  }

  // ── Card ────────────────────────────────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> c) {
    final title       = c['title']?.toString() ?? c['complaint_type'] ?? 'Complaint';
    final id          = c['id'];
    final studentName = c['student_name'] ?? 'Student';
    final studentId   = c['student_id']  ?? '';
    final remarks     = c['rejection_remarks'] ?? 'No reason provided.';
    final createdAt   = c['created_at']  ?? '';
    final dept        = c['department']  ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Red top strip ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: _C.rejectedBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined, color: _C.rejectedTxt, size: 14),
                const SizedBox(width: 6),
                const Text('REJECTED',
                    style: TextStyle(color: _C.rejectedTxt, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const Spacer(),
                if (createdAt.isNotEmpty)
                  Text('Submitted: $createdAt',
                      style: const TextStyle(fontSize: 11, color: _C.metaGray)),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + ID row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _C.rejectedBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.report_problem_outlined,
                          color: _C.rejectedTxt, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.w600, color: _C.darkNavy),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text('ID: #$id  •  $studentName',
                              style: const TextStyle(fontSize: 12, color: _C.metaGray)),
                          if (dept.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text('Dept: $dept',
                                style: const TextStyle(fontSize: 11, color: _C.metaGray)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Rejection Remarks Box ─────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _C.rejectedBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.rejectedBdr),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.comment_outlined,
                              size: 14, color: _C.rejectedTxt),
                          SizedBox(width: 6),
                          Text('Admin Rejection Reason',
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _C.rejectedTxt)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(remarks,
                          style: const TextStyle(
                              fontSize: 13, color: _C.darkNavy, height: 1.45)),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Footer row ────────────────────────────────────────────
                Row(
                  children: [
                    // Student ID chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 13, color: _C.mutedBlue),
                        const SizedBox(width: 4),
                        Text(studentId,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _C.mutedBlue)),
                      ]),
                    ),
                    const Spacer(),
                    // View Details button
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewComplaintDetailsScreen(
                            complaintId: id,
                            studentId: studentId,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _C.border, width: 0.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_outlined,
                                size: 15, color: _C.mutedBlue),
                            SizedBox(width: 5),
                            Text('View Details',
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _C.mutedBlue)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}