import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'view_complains.dart';

class AdminRoleComplaintsScreen extends StatefulWidget {
  final String adminRole;
  final String title;
  final String filter;

  const AdminRoleComplaintsScreen({
    super.key,
    required this.adminRole,
    required this.title,
    required this.filter,
  });

  @override
  State<AdminRoleComplaintsScreen> createState() => _AdminRoleComplaintsScreenState();
}

class _AdminRoleComplaintsScreenState extends State<AdminRoleComplaintsScreen> {
  List complaints = [];
  List filteredComplaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/admin/complaints/${widget.adminRole}/"),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        List allComplaints = data['data'];
        
        List filtered;
        if (widget.filter == 'pending') {
          filtered = allComplaints.where((c) => c['status'] == 'pending').toList();
        } else if (widget.filter == 'resolved') {
          filtered = allComplaints.where((c) => c['status'] == 'resolved').toList();
        } else {
          filtered = allComplaints;
        }
        
        setState(() {
          complaints = filtered;
          filteredComplaints = filtered;
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

  Future<void> updateStatus(int id, String newStatus) async {
    final url = Uri.parse("http://127.0.0.1:8000/api/admin/complaint/update-status/$id/");
    try {
      final response = await http.patch(url, body: {"status": newStatus});
      if (response.statusCode == 200 && mounted) {
        fetchComplaints();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complaint marked as $newStatus'),
            backgroundColor: newStatus == 'resolved' ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // ✅ Show rejection dialog
  Future<void> showRejectDialog(int id, String title) async {
    final TextEditingController remarksController = TextEditingController();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
              const SizedBox(width: 8),
              const Text('Reject Complaint', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complaint Details',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Please provide a reason for rejection:'),
              const SizedBox(height: 8),
              TextField(
                controller: remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter rejection reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (remarksController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter rejection reason'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                await rejectComplaint(id, remarksController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Confirm Reject'),
            ),
          ],
        );
      },
    );
  }

  // ✅ Reject complaint with remarks
  Future<void> rejectComplaint(int id, String remarks) async {
    final url = Uri.parse('http://127.0.0.1:8000/api/admin/complaint/reject/$id/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rejection_remarks': remarks}),
      );
      if (response.statusCode == 200 && mounted) {
        fetchComplaints();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint rejected with reason'),
            backgroundColor: Color(0xFFDC2626),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject complaint'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
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
        title: Text(
          widget.title,
          style: const TextStyle(
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

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${filteredComplaints.length} complaints",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A365D),
                  ),
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
                              Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                "No complaints found",
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredComplaints.length,
                          itemBuilder: (context, index) {
                            final complaint = filteredComplaints[index];
                            return _buildComplaintCard(complaint);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final title = complaint['title'] ?? complaint['complaint_type'] ?? "Complaint";
    final id = complaint['id'];
    final studentName = complaint['complainant'] ?? "Student";
    final studentId = complaint['student_id'] ?? "";
    final date = complaint['date'] ?? "";
    final status = complaint['status'] ?? "pending";
    final isResolved = status.toLowerCase() == 'resolved';
    final isPending = status.toLowerCase() == 'pending';
    final isRejected = status.toLowerCase() == 'rejected';

    Color statusColor = getStatusColor(status);
    IconData statusIcon = Icons.pending;
    if (isResolved) {
      statusIcon = Icons.check_circle;
    } else if (isRejected) {
      statusIcon = Icons.cancel;
    }

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
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
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
                if (isPending) ...[
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => updateStatus(id, 'resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Resolve"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => showRejectDialog(id, title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Reject"),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}