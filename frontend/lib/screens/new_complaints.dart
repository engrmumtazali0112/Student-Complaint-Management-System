import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'view_complains.dart';

// ─── Brand Colors ─────────────────────────────────────────────────────────────
class _C {
  static const pageBg      = Color(0xFFF0F4FA);
  static const cardBg      = Colors.white;
  static const darkNavy    = Color(0xFF0F1E38);
  static const navy        = Color(0xFF1A365D);
  static const mutedBlue   = Color(0xFF4F6FA5);

  static const pendingBg   = Color(0xFFFFF7ED);
  static const pendingBdr  = Color(0xFFFED7AA);
  static const pendingTxt  = Color(0xFFB45309);
  static const pendingIc   = Color(0xFFD97706);

  static const resolvedBg  = Color(0xFFF0FDF4);
  static const resolvedBdr = Color(0xFFBBF7D0);
  static const resolvedTxt = Color(0xFF15803D);
  static const resolvedIc  = Color(0xFF16A34A);

  static const rejectedBg  = Color(0xFFFEF2F2);
  static const rejectedBdr = Color(0xFFFECACA);
  static const rejectedTxt = Color(0xFFDC2626);
  static const urgentRed   = Color(0xFFDC2626);

  static const border      = Color(0xFFD8E0EF);
  static const borderLight = Color(0xFFEDF0F7);
  static const totalIcBg   = Color(0xFFEEF2FF);
  static const totalIcClr  = Color(0xFF4F46E5);
  static const searchHint  = Color(0xFFA8B4CC);
  static const metaGray    = Color(0xFF8B9DC3);
  static const dateGray    = Color(0xFFA8B4CC);
}

// ─── Complete Complaint-type Icon Mapper ───────────────────────────────────────
class _ComplaintIcon {
  static IconData icon(String type) {
    final t = type.toLowerCase();
    
    if (t.contains('infrastructure') || t.contains('building') || t.contains('facility') || t.contains('fan') || t.contains('ac') || t.contains('cooler')) {
      return Icons.apartment_rounded;
    }
    if (t.contains('fee') || t.contains('finance') || t.contains('payment') || t.contains('scholarship') || t.contains('tuition')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (t.contains('result') || t.contains('grade') || t.contains('marks') || t.contains('gpa') || t.contains('exam')) {
      return Icons.bar_chart_rounded;
    }
    if (t.contains('attendance')) {
      return Icons.co_present_rounded;
    }
    if (t.contains('library') || t.contains('book')) {
      return Icons.menu_book_rounded;
    }
    if (t.contains('transport') || t.contains('bus') || t.contains('hostel') || t.contains('vehicle')) {
      return Icons.directions_bus_rounded;
    }
    if (t.contains('internet') || t.contains('wifi') || t.contains('network') || t.contains('lab') || t.contains('computer')) {
      return Icons.wifi_rounded;
    }
    if (t.contains('exam') || t.contains('paper') || t.contains('test') || t.contains('assessment') || t.contains('examination')) {
      return Icons.edit_note_rounded;
    }
    if (t.contains('harassment') || t.contains('emergency') || t.contains('safety') || t.contains('security') || t.contains('abuse')) {
      return Icons.shield_rounded;
    }
    if (t.contains('faculty') || t.contains('teacher') || t.contains('professor') || t.contains('staff')) {
      return Icons.school_rounded;
    }
    if (t.contains('admission') || t.contains('registration') || t.contains('enroll')) {
      return Icons.app_registration_rounded;
    }
    if (t.contains('medical') || t.contains('health') || t.contains('doctor') || t.contains('hospital')) {
      return Icons.local_hospital_rounded;
    }
    if (t.contains('canteen') || t.contains('food') || t.contains('mess') || t.contains('restaurant')) {
      return Icons.restaurant_rounded;
    }
    if (t.contains('discipline') || t.contains('conduct') || t.contains('rule') || t.contains('misconduct')) {
      return Icons.gavel_rounded;
    }
    if (t.contains('noise') || t.contains('sound') || t.contains('disturbance') || t.contains('loud')) {
      return Icons.volume_up_rounded;
    }
    if (t.contains('clean') || t.contains('hygiene') || t.contains('dustbin') || t.contains('garbage')) {
      return Icons.cleaning_services_rounded;
    }
    if (t.contains('sports') || t.contains('game') || t.contains('playground')) {
      return Icons.sports_soccer_rounded;
    }
    
    return Icons.report_problem_outlined;
  }

  static Color iconBg(String type, bool isResolved, bool isRejected) {
    if (isResolved) return _C.resolvedBg;
    if (isRejected) return _C.rejectedBg;
    
    final t = type.toLowerCase();
    if (t.contains('infrastructure') || t.contains('building') || t.contains('fan')) return const Color(0xFFEEF2FF);
    if (t.contains('fee') || t.contains('finance'))             return const Color(0xFFFFFBEB);
    if (t.contains('result') || t.contains('grade') || t.contains('exam')) return const Color(0xFFEFF6FF);
    if (t.contains('attendance'))                               return const Color(0xFFF5F3FF);
    if (t.contains('library') || t.contains('book'))            return const Color(0xFFFFF7ED);
    if (t.contains('emergency') || t.contains('harassment'))    return const Color(0xFFFEF2F2);
    if (t.contains('noise') || t.contains('sound'))             return const Color(0xFFFEF2F2);
    if (t.contains('exam') || t.contains('paper'))              return const Color(0xFFECFDF5);
    if (t.contains('faculty') || t.contains('teacher'))         return const Color(0xFFF0F9FF);
    if (t.contains('transport') || t.contains('bus'))           return const Color(0xFFF0FDF4);
    if (t.contains('canteen') || t.contains('food'))            return const Color(0xFFFFF7ED);
    
    return const Color(0xFFEEF2FF);
  }

  static Color iconColor(String type, bool isResolved, bool isRejected) {
    if (isResolved) return _C.resolvedIc;
    if (isRejected) return _C.rejectedTxt;
    
    final t = type.toLowerCase();
    if (t.contains('infrastructure') || t.contains('building') || t.contains('fan')) return const Color(0xFF4F46E5);
    if (t.contains('fee') || t.contains('finance'))             return const Color(0xFFD97706);
    if (t.contains('result') || t.contains('grade') || t.contains('exam')) return const Color(0xFF2563EB);
    if (t.contains('attendance'))                               return const Color(0xFF7C3AED);
    if (t.contains('library') || t.contains('book'))            return const Color(0xFFEA580C);
    if (t.contains('emergency') || t.contains('harassment'))    return _C.urgentRed;
    if (t.contains('noise') || t.contains('sound'))             return const Color(0xFFDC2626);
    if (t.contains('exam') || t.contains('paper'))              return const Color(0xFF059669);
    if (t.contains('faculty') || t.contains('teacher'))         return const Color(0xFF0284C7);
    if (t.contains('transport') || t.contains('bus'))           return const Color(0xFF16A34A);
    if (t.contains('canteen') || t.contains('food'))            return const Color(0xFFEA580C);
    
    return const Color(0xFF4F46E5);
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class NewComplaintsScreen extends StatefulWidget {
  const NewComplaintsScreen({super.key});
  
  @override
  State<NewComplaintsScreen> createState() => _NewComplaintsScreenState();
}

class _NewComplaintsScreenState extends State<NewComplaintsScreen> {
  List complaints         = [];
  List filteredComplaints = [];
  bool isLoading          = true;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/admin/complaint/'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          complaints         = data['data'];
          filteredComplaints = complaints;
          isLoading          = false;
        });
      } else if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
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
        final complaintType = (c['complaint_type'] ?? '').toString().toLowerCase();
        final title = (c['title'] ?? '').toString().toLowerCase();
        final studentId = (c['student_id'] ?? '').toString().toLowerCase();
        return complaintType.contains(q) ||
            title.contains(q) ||
            c['id'].toString().contains(q) ||
            studentId.contains(q);
      }).toList();
    });
  }

  Future<void> updateStatus(int id, String newStatus) async {
    final url = Uri.parse(
        'http://127.0.0.1:8000/api/admin/complaint/update-status/$id/');
    try {
      final response = await http.patch(url, body: {'status': newStatus});
      if (response.statusCode == 200 && mounted) {
        setState(() {
          for (int i = 0; i < complaints.length; i++) {
            if (complaints[i]['id'] == id) {
              complaints[i] = Map<String, dynamic>.from(complaints[i])
                ..['status'] = newStatus.toLowerCase();
            }
          }
          filteredComplaints = List.from(complaints);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Complaint #$id marked as $newStatus'),
            backgroundColor: newStatus == 'resolved' ? Colors.green : _C.urgentRed,
            duration: const Duration(seconds: 2),
          ));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: _C.urgentRed,
        ));
      }
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
        await fetchComplaints();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complaint rejected with reason'),
              backgroundColor: Color(0xFFDC2626),
              duration: Duration(seconds: 2),
            ),
          );
        }
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

  int get _totalCount    => filteredComplaints.length;
  int get _pendingCount  => filteredComplaints
      .where((c) => (c['status'] ?? '').toString().toLowerCase() == 'pending')
      .length;
  int get _resolvedCount => filteredComplaints
      .where((c) => (c['status'] ?? '').toString().toLowerCase() == 'resolved')
      .length;
  int get _newBadgeCount => complaints
      .where((c) => (c['status'] ?? '').toString().toLowerCase() == 'pending')
      .length;

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
              _buildStatsRow(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildSectionLabel(),
              const SizedBox(height: 12),
              _buildList(),
            ],
          ),
        ),
      ),
    );
  }

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
              Text('New Complaints',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                      color: _C.darkNavy, letterSpacing: -0.5)),
              Text('Review and action incoming complaints',
                  style: TextStyle(fontSize: 12, color: _C.metaGray)),
            ],
          ),
        ),
        if (_newBadgeCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _C.rejectedBg,
              border: Border.all(color: _C.rejectedBdr),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$_newBadgeCount New',
                style: const TextStyle(color: _C.urgentRed,
                    fontWeight: FontWeight.w700, fontSize: 13)),
          ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard(icon: Icons.format_list_numbered_rounded,
            iconBg: _C.totalIcBg, iconColor: _C.totalIcClr,
            label: 'Total', value: '$_totalCount'),
        const SizedBox(width: 10),
        _statCard(icon: Icons.access_time_rounded,
            iconBg: const Color(0xFFFFF7ED), iconColor: _C.pendingIc,
            label: 'Pending', value: '$_pendingCount'),
        const SizedBox(width: 10),
        _statCard(icon: Icons.check_circle_outline_rounded,
            iconBg: _C.resolvedBg, iconColor: _C.resolvedIc,
            label: 'Resolved', value: '$_resolvedCount'),
      ],
    );
  }

  Widget _statCard({required IconData icon, required Color iconBg,
      required Color iconColor, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(width: 38, height: 38,
                decoration: BoxDecoration(color: iconBg,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 18)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 20,
                  fontWeight: FontWeight.w700, color: _C.darkNavy, height: 1)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, color: _C.metaGray)),
            ]),
          ],
        ),
      ),
    );
  }

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
              onChanged: filterSearch,
              style: const TextStyle(fontSize: 14, color: _C.darkNavy),
              decoration: const InputDecoration(
                hintText: 'Search by ID, subject, or student...',
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

  Widget _buildSectionLabel() {
    return Text('COMPLAINTS LIST',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            letterSpacing: 1.2, color: _C.metaGray.withAlpha(200)));
  }

  Widget _buildList() {
    return Expanded(
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: _C.mutedBlue))
          : filteredComplaints.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(Icons.inbox_outlined, size: 64,
                        color: _C.metaGray.withAlpha(120)),
                    const SizedBox(height: 12),
                    const Text('No complaints found',
                        style: TextStyle(color: _C.metaGray, fontSize: 15)),
                  ]))
              : ListView.builder(
                  itemCount: filteredComplaints.length,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemBuilder: (context, index) =>
                      _buildComplaintCard(filteredComplaints[index]),
                ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> c) {
    final status    = (c['status'] ?? 'pending').toString().toLowerCase();
    final type      = c['complaint_type']?.toString() ?? '';
    final title     = c['title']?.toString() ?? type;
    final id        = c['id'];
    final studentId = c['student_id']?.toString() ?? '';
    final date      = c['date']?.toString() ?? '';
    
    final isUrgent   = type.toLowerCase().contains('infrastructure') ||
                       type.toLowerCase().contains('emergency');
    final isResolved = status == 'resolved';
    final isRejected = status == 'rejected';
    final isPending  = status == 'pending';

    final iconData = _ComplaintIcon.icon(type);
    final iconBgColor = _ComplaintIcon.iconBg(type, isResolved, isRejected);
    final iconColor = _ComplaintIcon.iconColor(type, isResolved, isRejected);

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
          if (isUrgent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: const BoxDecoration(
                color: _C.urgentRed,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text('URGENT', style: TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title.isNotEmpty ? title : type,
                        style: const TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w600, color: _C.darkNavy)),
                    const SizedBox(height: 3),
                    Text('ID: #$id  •  Student: $studentId',
                        style: const TextStyle(fontSize: 12, color: _C.metaGray)),
                  ]),
                ),
                _statusBadge(status),
              ]),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: _C.borderLight),
              ),
              Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: _C.mutedBlue),
                const SizedBox(width: 5),
                Text(date.isNotEmpty ? date : 'No date',
                    style: const TextStyle(fontSize: 12, color: _C.dateGray)),
                const Spacer(),
                _outlinedBtn(
                  label: 'View Details',
                  icon: Icons.visibility_outlined,
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) =>
                      ViewComplaintDetailsScreen(
                        complaintId: id, studentId: studentId))),
                ),
                const SizedBox(width: 8),
                // Resolve button
                if (isPending)
                  _resolveButton(onTap: () => updateStatus(id, 'resolved')),
                const SizedBox(width: 8),
                // ✅ Reject button
                if (isPending)
                  _rejectButton(onTap: () => showRejectDialog(id, title)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    late Color bg, border, text;
    late IconData icon;
    late String label;
    switch (status) {
      case 'resolved':
        bg = _C.resolvedBg; border = _C.resolvedBdr; text = _C.resolvedTxt;
        icon = Icons.check_circle_outline_rounded; label = 'Resolved';
        break;
      case 'rejected':
        bg = _C.rejectedBg; border = _C.rejectedBdr; text = _C.rejectedTxt;
        icon = Icons.cancel_outlined; label = 'Rejected';
        break;
      default:
        bg = _C.pendingBg; border = _C.pendingBdr; text = _C.pendingTxt;
        icon = Icons.access_time_rounded; label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: text, size: 13),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
            color: text, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _outlinedBtn({required String label, required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.border, width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: _C.mutedBlue),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: _C.mutedBlue)),
        ]),
      ),
    );
  }

  Widget _resolveButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 15, color: Colors.white),
            SizedBox(width: 5),
            Text(
              'Resolve',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Reject button widget
  Widget _rejectButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, size: 15, color: Colors.white),
            SizedBox(width: 5),
            Text(
              'Reject',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}