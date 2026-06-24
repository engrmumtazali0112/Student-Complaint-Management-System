// lib/screens/student/student_rate_admin_screen.dart
//
// Feature 3 – Student: Accept Resolution & Rate Admin
//
// Usage: Navigate to this screen after student opens a resolved complaint.
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => StudentRateAdminScreen(
//       complaintId: complaint['id'],
//       complaintTitle: complaint['title'] ?? complaint['complaint_type'],
//     )));
//
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../constants/api_constants.dart';

const _primary  = Color(0xFF1565C0);
const _resolved = Color(0xFF4CAF50);
const _amber    = Color(0xFFFFC107);

class StudentRateAdminScreen extends StatefulWidget {
  final int    complaintId;
  final String complaintTitle;

  const StudentRateAdminScreen({
    super.key,
    required this.complaintId,
    required this.complaintTitle,
  });

  @override
  State<StudentRateAdminScreen> createState() => _StudentRateAdminScreenState();
}

class _StudentRateAdminScreenState extends State<StudentRateAdminScreen> {
  // Existing rating check
  bool   _checkingExisting = true;
  bool   _alreadyRated     = false;
  Map?   _existingRating;

  // Form state
  int    _selectedRating = 0;
  final  TextEditingController _commentCtrl = TextEditingController();
  bool   _submitting = false;

  // Label descriptions per star
  static const _ratingLabels = [
    '',
    'Poor — Unsatisfied with resolution',
    'Fair — Partially resolved',
    'Good — Acceptable handling',
    'Very Good — Well handled',
    'Excellent — Outstanding service',
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingRating();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkExistingRating() async {
    try {
      final res = await http.get(Uri.parse(
          '${ApiConstants.baseUrl}/api/student/complaint-rating/${widget.complaintId}/'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() {
          _alreadyRated = body['has_rated'] == true;
          if (_alreadyRated) _existingRating = body;
        });
      }
    } catch (_) {}
    setState(() => _checkingExisting = false);
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      _showSnack('Please select a star rating before submitting.', Colors.orange);
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}/api/student/rate-admin/${widget.complaintId}/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rating':  _selectedRating,
          'comment': _commentCtrl.text.trim(),
        }),
      );
      String? body0Error;
      Map body = {};
      try {
        body = json.decode(res.body);
      } catch (_) {
        body0Error = 'Server returned an unexpected response (HTTP ${res.statusCode}).';
      }
      if (res.statusCode == 200 && body0Error == null) {
        _showSuccessDialog();
      } else {
        _showSnack(body0Error ?? body['error'] ?? 'Submission failed', Colors.red);
      }
    } catch (e) {
      _showSnack('Network error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
    ));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.thumb_up_rounded, color: _resolved, size: 64),
          const SizedBox(height: 12),
          const Text('Thank You!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Your rating has been recorded.\nThis helps us improve our service.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => Icon(
                i < _selectedRating ? Icons.star : Icons.star_border,
                color: _amber,
                size: 28,
              ))),
        ]),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary, foregroundColor: Colors.white,
                  minimumSize: const Size(120, 42)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true); // return true = rated
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: _primary,
        title: const Text('Rate Resolution',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _checkingExisting
          ? const Center(child: CircularProgressIndicator())
          : _alreadyRated
              ? _buildAlreadyRated()
              : _buildRatingForm(),
    );
  }

  // ── Already rated view ────────────────────────────────────────────────
  Widget _buildAlreadyRated() {
    final rating  = (_existingRating?['rating']  as int?) ?? 0;
    final comment = (_existingRating?['comment'] as String?) ?? '';
    final date    = (_existingRating?['created_at'] as String?) ?? '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.verified_rounded, color: _resolved, size: 56),
              const SizedBox(height: 12),
              const Text('Rating Already Submitted',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: _amber, size: 32,
                  ))),
              const SizedBox(height: 8),
              Text('$rating / 5 Stars',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('"$comment"',
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                ),
              ],
              if (date.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Submitted on $date',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Rating form ───────────────────────────────────────────────────────
  Widget _buildRatingForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Complaint info card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: _resolved.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(Icons.check_circle, color: _resolved, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Complaint Resolved',
                        style: TextStyle(color: _resolved, fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(widget.complaintTitle, maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ])),
            ]),
          ),
        ),

        const SizedBox(height: 24),
        const Text('Rate the Admin\'s Performance',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _primary)),
        const SizedBox(height: 6),
        const Text('Your honest feedback helps improve the complaint system.',
            style: TextStyle(color: Colors.grey, fontSize: 13)),

        const SizedBox(height: 20),

        // ── Star selector ─────────────────────────────────────────────
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = star),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    star <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: star <= _selectedRating ? _amber : Colors.grey.shade400,
                    size: 44,
                  ),
                ),
              );
            }),
          ),
        ),

        // Rating label
        if (_selectedRating > 0)
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _ratingLabels[_selectedRating],
                key: ValueKey(_selectedRating),
                style: TextStyle(
                  color: _selectedRating >= 4 ? _resolved
                      : _selectedRating == 3 ? Colors.orange
                      : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // ── Criteria chips ────────────────────────────────────────────
        const Text('Rating Criteria:',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        const Wrap(spacing: 8, runSpacing: 6, children: [
          _CriteriaChip(icon: Icons.high_quality, label: 'Resolution Quality'),
          _CriteriaChip(icon: Icons.timer,         label: 'Response Time'),
          _CriteriaChip(icon: Icons.people,        label: 'Professionalism'),
        ]),

        const SizedBox(height: 20),

        // ── Comment field ─────────────────────────────────────────────
        TextField(
          controller: _commentCtrl,
          maxLines: 3,
          maxLength: 300,
          decoration: InputDecoration(
            labelText: 'Optional Comment',
            hintText: 'Share your experience...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _primary, width: 2)),
          ),
        ),

        const SizedBox(height: 24),

        // ── Submit button ─────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: _submitting
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
            label: Text(_submitting ? 'Submitting...' : 'Submit Rating'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            onPressed: _submitting ? null : _submit,
          ),
        ),

        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Rate Later', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ]),
    );
  }
}

// ── Small helper widget ───────────────────────────────────────────────────
class _CriteriaChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _CriteriaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: _primary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: _primary,
            fontWeight: FontWeight.w500)),
      ]),
    );
  }
}