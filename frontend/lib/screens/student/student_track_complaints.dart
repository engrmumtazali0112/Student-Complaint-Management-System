import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'student_view_complaint.dart';  // ✅ Fixed: changed from 'view_complains.dart'

class TrackComplaintsScreen extends StatefulWidget {
  final String studentId;

  const TrackComplaintsScreen({super.key, required this.studentId});

  @override
  State<TrackComplaintsScreen> createState() => _TrackComplaintsScreenState();
}

class _TrackComplaintsScreenState extends State<TrackComplaintsScreen> {
  List complaints = [];
  List filteredComplaints = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      final response = await http.get(
        Uri.parse(
            "http://localhost:8000/api/student/complaint/track/${widget.studentId}/"),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          complaints = data['data'];
          filteredComplaints = complaints;
          isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void filterSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredComplaints = complaints.where((complaint) {
        final title = complaint['title'] ?? complaint['subject'] ?? '';
        final status = complaint['status'] ?? '';
        final id = complaint['id'].toString();
        
        return title.toLowerCase().contains(query.toLowerCase()) ||
            status.toLowerCase().contains(query.toLowerCase()) ||
            id.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    int pendingCount = complaints.where((c) => 
      (c['status'] ?? '').toLowerCase() == 'pending'
    ).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color.fromARGB(255, 238, 242, 248)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Track Complaints",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 136, 167, 211),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: pendingCount > 0 ? const Color(0xFFF59E0B) : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  pendingCount > 0 ? Icons.pending_actions : Icons.check_circle,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  "Pending: $pendingCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Stats Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A365D), Color(0xFF2B6CB0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    title: "Total",
                    value: complaints.length.toString(),
                    icon: Icons.format_list_numbered,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withAlpha(50),
                  ),
                  _buildStatItem(
                    title: "Pending",
                    value: pendingCount.toString(),
                    icon: Icons.pending_actions,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withAlpha(50),
                  ),
                  _buildStatItem(
                    title: "Resolved",
                    value: complaints.where((c) => (c['status'] ?? '').toLowerCase() == 'resolved').length.toString(),
                    icon: Icons.check_circle,
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
                  BoxShadow(
                    color: Colors.grey.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: filterSearch,
                decoration: InputDecoration(
                  hintText: "Search by title, status, or ID...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2B6CB0), size: 22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Complaints List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Your Complaints",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A365D),
                  ),
                ),
                Text(
                  "${filteredComplaints.length} items",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // List Section
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredComplaints.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No complaints found",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                ),
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

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withAlpha(179),
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final title = complaint['title'] ?? complaint['subject'] ?? "Complaint";
    final status = complaint['status'] ?? "Pending";
    final id = complaint['id'].toString();
    final createdAt = complaint['created_at'] ?? "";
    
    final isResolved = status.toLowerCase() == 'resolved';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          onTap: () {
            // ✅ Fixed: Removed complaintData parameter
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewComplaintDetailsScreen(
                  complaintId: int.parse(id),
                  studentId: widget.studentId,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isResolved
                        ? Colors.green.withAlpha(26)
                        : const Color(0xFFF59E0B).withAlpha(26),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isResolved ? Icons.check_circle : Icons.pending,
                    color: isResolved ? Colors.green : const Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                
                // Complaint Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A365D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? Colors.green.withAlpha(26)
                                  : const Color(0xFFF59E0B).withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isResolved ? Colors.green : const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "ID: #$id",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (createdAt.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              "•",
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              createdAt,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B6CB0).withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF2B6CB0),
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