import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_view_complaint.dart';

class AdminPendingComplaintsScreen extends StatefulWidget {
  final String adminType;

  const AdminPendingComplaintsScreen({super.key, required this.adminType});

  @override
  State<AdminPendingComplaintsScreen> createState() => _AdminPendingComplaintsScreenState();
}

class _AdminPendingComplaintsScreenState extends State<AdminPendingComplaintsScreen> {
  List complaints = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchPendingComplaints();
  }

  Future<void> fetchPendingComplaints() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/admin/complaint/pending/?admin_type=${widget.adminType}'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          complaints = data['data'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateStatus(int id, String newStatus, {String? remarks}) async {
    final url = Uri.parse("http://127.0.0.1:8000/api/admin/complaint/update-status/$id/");
    try {
      final response = await http.patch(url, body: {"status": newStatus});
      if (response.statusCode == 200 && mounted) {
        fetchPendingComplaints();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Complaint marked as $newStatus'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red));
    }
  }

  List get filteredComplaints {
    if (searchQuery.isEmpty) return complaints;
    return complaints.where((c) {
      final title = c['title']?.toString().toLowerCase() ?? '';
      final student = c['student_name']?.toString().toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();
      return title.contains(query) || student.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text("Pending Complaints"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsCard(),
          _buildComplaintsList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withAlpha(15), blurRadius: 8)],
        ),
        child: TextField(
          onChanged: (value) => setState(() => searchQuery = value),
          decoration: InputDecoration(
            hintText: "Search by title or student...",
            prefixIcon: const Icon(Icons.search, color: Color(0xFF2B6CB0)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.pending_actions, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pending Complaints", style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text("${filteredComplaints.length}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsList() {
    return Expanded(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredComplaints.isEmpty
              ? const Center(child: Text("No pending complaints"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredComplaints.length,
                  itemBuilder: (context, index) => _buildComplaintCard(filteredComplaints[index]),
                ),
    );
  }

  Widget _buildComplaintCard(dynamic complaint) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(complaint['title'] ?? complaint['complaint_type'], style: const TextStyle(fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B).withAlpha(26), borderRadius: BorderRadius.circular(12)),
                  child: const Text("PENDING", style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("ID: #${complaint['id']} - ${complaint['student_name']} (${complaint['student_id']})"),
            Text(complaint['created_at'] ?? 'Unknown date', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewComplaintDetailsScreen(complaintId: complaint['id'], studentId: complaint['student_id']))),
                  child: const Text("View Details"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => updateStatus(complaint['id'], 'resolved'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Resolve", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}