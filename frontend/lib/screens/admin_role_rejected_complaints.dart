import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'view_complains.dart';

class AdminRoleRejectedComplaintsScreen extends StatefulWidget {
  final String adminRole;

  const AdminRoleRejectedComplaintsScreen({
    super.key,
    required this.adminRole,
  });

  @override
  State<AdminRoleRejectedComplaintsScreen> createState() => _AdminRoleRejectedComplaintsScreenState();
}

class _AdminRoleRejectedComplaintsScreenState extends State<AdminRoleRejectedComplaintsScreen> {
  List complaints = [];
  List filteredComplaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRejectedComplaints();
  }

  Future<void> fetchRejectedComplaints() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/admin/complaints/${widget.adminRole}/"),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        List allComplaints = data['data'];
        
        // Filter only rejected complaints
        final rejected = allComplaints.where((c) => c['status'] == 'rejected').toList();
        
        setState(() {
          complaints = rejected;
          filteredComplaints = rejected;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredComplaints = complaints;
        return;
      }
      final q = query.toLowerCase();
      filteredComplaints = complaints.where((c) {
        final title = (c['title'] ?? '').toString().toLowerCase();
        final complainant = (c['complainant'] ?? '').toString().toLowerCase();
        return title.contains(q) || complainant.contains(q) || c['id'].toString().contains(q);
      }).toList();
    });
  }

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
          "Rejected Complaints",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A365D),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    "Total Rejected",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complaints.length.toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withAlpha(15), blurRadius: 8),
                ],
              ),
              child: TextField(
                onChanged: filterSearch,
                decoration: InputDecoration(
                  hintText: "Search by title or student...",
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2B6CB0)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Rejected Complaints",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A365D),
                  ),
                ),
                Text(
                  "${filteredComplaints.length} items",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredComplaints.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel_outlined, size: 80, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                "No rejected complaints",
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredComplaints.length,
                          itemBuilder: (context, index) {
                            final complaint = filteredComplaints[index];
                            return _buildRejectedCard(complaint);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedCard(Map<String, dynamic> complaint) {
    final title = complaint['title'] ?? complaint['complaint_type'] ?? "Complaint";
    final id = complaint['id'];
    final studentName = complaint['complainant'] ?? "Student";
    final studentId = complaint['student_id'] ?? "";
    final date = complaint['date'] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withAlpha(15), blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A365D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel, size: 12, color: Color(0xFFDC2626)),
                      SizedBox(width: 4),
                      Text(
                        "REJECTED",
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "ID: #$id • $studentName ($studentId)",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            if (date.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                date,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewComplaintDetailsScreen(
                        complaintId: id,
                        studentId: studentId,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2B6CB0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("View Details", style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}