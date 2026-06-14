  // lib/screens/super_admin/super_admin_ratings_screen.dart
//
// Feature 3 – Super Admin views all admin performance ratings
//
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../constants/api_constants.dart';

const _primary = Color(0xFF1565C0);

class SuperAdminRatingsScreen extends StatefulWidget {
  const SuperAdminRatingsScreen({super.key});

  @override
  State<SuperAdminRatingsScreen> createState() =>
      _SuperAdminRatingsScreenState();
}

class _SuperAdminRatingsScreenState extends State<SuperAdminRatingsScreen> {
  bool _loading = true;
  List _ratings = [];
  String? _error;
  String _filterDept = '';

  static const _departments = [
    '', 'warden','administration','examination','treasury',
    'security','transport','library','hostel','sports','it',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final query = _filterDept.isNotEmpty ? '?admin_type=$_filterDept' : '';
      final res = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/super-admin/admin-ratings/$query'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() { _ratings = body['data'] ?? []; _loading = false; });
      } else {
        setState(() { _error = 'Error ${res.statusCode}'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Network error: $e'; _loading = false; });
    }
  }

  double get _avgRating {
    if (_ratings.isEmpty) return 0;
    final sum = _ratings.fold<double>(
        0, (s, r) => s + ((r['rating'] as num?)?.toDouble() ?? 0));
    return sum / _ratings.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: _primary,
        title: const Text('⭐ Admin Ratings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          // ── Summary banner ──────────────────────────────────────────
          Container(
            color: _primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              const Icon(Icons.star, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Overall Average: ${_avgRating.toStringAsFixed(2)} / 5',
                    style: const TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('${_ratings.length} rating(s)',
                    style: const TextStyle(color: Colors.white70)),
              ]),
            ]),
          ),

          // ── Filter bar ──────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _filterDept,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _departments.map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d.isEmpty ? 'All Departments' : d.toUpperCase()),
                  )).toList(),
                  onChanged: (val) {
                    setState(() => _filterDept = val ?? '');
                    _load();
                  },
                ),
              ),
            ]),
          ),

          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _ratings.isEmpty
                        ? const Center(child: Text('No ratings found.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _ratings.length,
                              itemBuilder: (_, i) => _buildCard(_ratings[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map r) {
    final rating = (r['rating'] as num?)?.toInt() ?? 0;
    final color  = rating >= 4
        ? Colors.green
        : rating == 3
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Admin + rating row
          Row(children: [
            CircleAvatar(
              backgroundColor: _primary.withValues(alpha: 0.15),
              child: Text(
                (r['admin_role'] as String? ?? 'X').substring(0, 1).toUpperCase(),
                style: const TextStyle(color: _primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r['admin_username'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text((r['admin_role'] as String? ?? '').toUpperCase(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            // Star display
            Row(children: List.generate(5, (i) => Icon(
              i < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 18,
            ))),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text('$rating/5',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ]),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Details
          _detailRow('Student', '${r['student_name']} (${r['student_id']})'),
          _detailRow('Complaint', '#${r['complaint_id']} — ${r['complaint_type']}'),
          _detailRow('Date', r['created_at'] ?? ''),
          if ((r['comment'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text('"${r['comment']}"',
                  style: const TextStyle(fontStyle: FontStyle.italic,
                      color: Colors.black87, fontSize: 13)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(
          width: 80,
          child: Text('$label:', style: const TextStyle(
              color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }
}