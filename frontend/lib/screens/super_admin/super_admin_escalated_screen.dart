// lib/screens/super_admin/super_admin_escalated_screen.dart
//
// Feature 2 – Escalated Complaints Screen
// Allows Super Admin to: view, reassign, or resolve escalated complaints.
//
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../constants/api_constants.dart';

const _primary   = Color(0xFF1565C0);
const _escalated = Color(0xFF9C27B0);
const _resolved  = Color(0xFF4CAF50);

class SuperAdminEscalatedScreen extends StatefulWidget {
  const SuperAdminEscalatedScreen({super.key});

  @override
  State<SuperAdminEscalatedScreen> createState() =>
      _SuperAdminEscalatedScreenState();
}

class _SuperAdminEscalatedScreenState
    extends State<SuperAdminEscalatedScreen> {
  bool _loading = true;
  List _complaints = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/super-admin/escalated/'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() {
          _complaints = body['complaints'] ?? [];
          _loading = false;
        });
      } else {
        setState(() { _error = 'Server error ${res.statusCode}'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Network error: $e'; _loading = false; });
    }
  }

  // ── Reassign dialog ───────────────────────────────────────────────────
  Future<void> _showReassignDialog(Map complaint) async {
    const departments = [
      'warden','administration','examination','treasury',
      'security','transport','library','hostel','sports','it',
    ];
    String? selected = complaint['admin_type'];

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reassign Complaint'),
        content: StatefulBuilder(
          builder: (_, setS) => DropdownButton<String>(
            value: selected,
            isExpanded: true,
            items: departments.map((d) => DropdownMenuItem(
              value: d,
              child: Text(d.toUpperCase()),
            )).toList(),
            onChanged: (val) => setS(() => selected = val),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            onPressed: () async {
              Navigator.pop(ctx);
              await _reassign(complaint['id'], selected!);
            },
            child: const Text('Reassign', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _reassign(int id, String newType) async {
    _showLoading('Reassigning...');
    try {
      final res = await http.post(
        Uri.parse('\${ApiConstants.baseUrl}/super-admin/reassign/\$id/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'new_admin_type': newType}),
      );
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      final body = json.decode(res.body);
      _showSnack(body['message'] ?? body['error'] ?? 'Done',
          res.statusCode == 200 ? _resolved : Colors.red);
      if (res.statusCode == 200) _load();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Error: \$e', Colors.red);
    }
  }

  Future<void> _resolve(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Complaint'),
        content: const Text('Mark this complaint as resolved by Super Admin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _resolved),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resolve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    _showLoading('Resolving...');
    try {
      final res = await http.post(
          Uri.parse('\${ApiConstants.baseUrl}/super-admin/resolve/\$id/'));
      if (!mounted) return;
      Navigator.pop(context);
      final body = json.decode(res.body);
      _showSnack(body['message'] ?? body['error'] ?? 'Done',
          res.statusCode == 200 ? _resolved : Colors.red);
      if (res.statusCode == 200) _load();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Error: \$e', Colors.red);
    }
  }

  void _showLoading(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Text(msg),
        ]),
      ),
    );
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: _escalated,
        title: const Text('⚠️ Escalated Complaints',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _complaints.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 72, color: _resolved),
                          SizedBox(height: 12),
                          Text('No escalated complaints!',
                              style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _complaints.length,
                        itemBuilder: (_, i) => _buildCard(_complaints[i]),
                      ),
                    ),
    );
  }

  Widget _buildCard(Map c) {
    final days = c['days_pending'] ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _escalated.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _escalated.withValues(alpha: 0.5)),
              ),
              child: Text('#${c['id']}',
                  style: const TextStyle(color: _escalated,
                      fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(c['title'] ?? '', maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text('$days days',
                  style: TextStyle(color: Colors.red.shade700,
                      fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 8),

          // Info rows
          _infoRow(Icons.person,         c['student_name'] ?? ''),
          _infoRow(Icons.badge,          c['student_id'] ?? ''),
          _infoRow(Icons.business,
              (c['admin_type'] ?? '').toString().toUpperCase()),
          _infoRow(Icons.calendar_today, c['escalated_at'] ?? ''),
          const SizedBox(height: 6),
          Text(c['description'] ?? '',
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),

          const SizedBox(height: 12),
          // Action buttons
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Reassign'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: _primary)),
                onPressed: () => _showReassignDialog(c),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Resolve'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _resolved, foregroundColor: Colors.white),
                onPressed: () => _resolve(c['id']),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }
}