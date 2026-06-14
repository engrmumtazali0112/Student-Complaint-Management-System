// lib/screens/super_admin/super_admin_all_complaints_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';

class SuperAdminAllComplaintsScreen extends StatefulWidget {
  const SuperAdminAllComplaintsScreen({super.key});

  @override
  State<SuperAdminAllComplaintsScreen> createState() => _SuperAdminAllComplaintsScreenState();
}

class _SuperAdminAllComplaintsScreenState extends State<SuperAdminAllComplaintsScreen> {
  List _complaints = [];
  List _filteredComplaints = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/complaint/'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _complaints = data['data'] ?? [];
          _filteredComplaints = _complaints;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _filterComplaints(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredComplaints = _complaints;
      } else {
        _filteredComplaints = _complaints.where((c) {
          final title = (c['title'] ?? '').toString().toLowerCase();
          final student = (c['complainant'] ?? '').toString().toLowerCase();
          final id = c['id'].toString();
          final queryLower = query.toLowerCase();
          return title.contains(queryLower) || student.contains(queryLower) || id.contains(queryLower);
        }).toList();
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return const Color(0xFF4CAF50);
      case 'pending': return const Color(0xFFFFA726);
      case 'rejected': return const Color(0xFFF44336);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('All Complaints', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadComplaints),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: _filterComplaints,
                decoration: InputDecoration(
                  hintText: 'Search by ID, title, or student...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${_filteredComplaints.length} complaints',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredComplaints.isEmpty
                    ? const Center(child: Text('No complaints found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredComplaints.length,
                        itemBuilder: (_, i) => _buildCard(_filteredComplaints[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map c) {
    final status = c['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
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
                Expanded(
                  child: Text(
                    c['title'] ?? c['complaint_type'] ?? 'Complaint',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('ID: #${c['id']} | Student: ${c['complainant']} (${c['student_id']})'),
            Text('Department: ${c['admin_type']?.toString().toUpperCase() ?? 'N/A'}'),
            Text('Submitted: ${c['date'] ?? ''}'),
          ],
        ),
      ),
    );
  }
}