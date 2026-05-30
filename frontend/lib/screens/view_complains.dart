import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ViewComplaintDetailsScreen extends StatefulWidget {
  final int complaintId;
  final String studentId;

  const ViewComplaintDetailsScreen({
    super.key,
    required this.complaintId,
    required this.studentId,
  });

  @override
  State<ViewComplaintDetailsScreen> createState() =>
      _ViewComplaintDetailsScreenState();
}

class _ViewComplaintDetailsScreenState
    extends State<ViewComplaintDetailsScreen> {
  
  Map<String, dynamic>? complaintData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchComplaintDetails();
  }

  Future<void> fetchComplaintDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final url = Uri.parse(
      'http://localhost:8000/api/complaint/${widget.complaintId}/',
    );

    try {
      debugPrint("Fetching from URL: $url");
      final response = await http.get(url);
      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          setState(() {
            complaintData = decoded['data'];
            isLoading = false;
          });
          return;
        } else {
          setState(() {
            errorMessage = decoded['message'] ?? 'Complaint not found';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Complaint not found (404)';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() {
        errorMessage = 'Connection error: $e';
        isLoading = false;
      });
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A365D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Complaint Details",
          style: TextStyle(
            fontSize: 20,
            color: Color(0xFF1A365D),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => fetchComplaintDetails(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B6CB0),
                        ),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Status Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [getStatusColor(complaintData!['status'] ?? 'pending'), getStatusColor(complaintData!['status'] ?? 'pending').withAlpha(179)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: getStatusColor(complaintData!['status'] ?? 'pending').withAlpha(40),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              getStatusIcon(complaintData!['status'] ?? 'pending'),
                              size: 50,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              (complaintData!['status'] ?? 'PENDING').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Complaint ID: #${widget.complaintId}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withAlpha(179),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Complaint Title Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A365D), Color(0xFF2B6CB0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withAlpha(30),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.report_problem_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              complaintData!['title'] ?? complaintData!['complaint_type'] ?? "Complaint",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Information Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(10),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                label: "Submitted On",
                                value: complaintData!['submitted_on'] ?? "N/A",
                                icon: Icons.calendar_today,
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                label: "Complaint Type",
                                value: complaintData!['complaint_type'] ?? "N/A",
                                icon: Icons.category,
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                label: "Department",
                                value: complaintData!['department'] ?? "N/A",
                                icon: Icons.business,
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                label: "Session",
                                value: complaintData!['session'] ?? "N/A",
                                icon: Icons.calendar_month,
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                label: "Roll Number",
                                value: complaintData!['roll_number'] ?? widget.studentId,
                                icon: Icons.badge,
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                label: "Status",
                                value: complaintData!['status'] ?? "Pending",
                                icon: Icons.info_outline,
                                valueColor: getStatusColor(complaintData!['status'] ?? 'pending'),
                              ),
                              if ((complaintData!['status'] ?? '').toLowerCase() == 'rejected') ...[
                                const Divider(height: 24),
                                _buildRejectionRow(
                                  label: "Rejection Reason",
                                  value: complaintData!['rejection_remarks'] ?? "No reason provided",
                                ),
                              ],
                              if ((complaintData!['status'] ?? '').toLowerCase() == 'resolved') ...[
                                const Divider(height: 24),
                                _buildInfoRow(
                                  label: "Resolved On",
                                  value: complaintData!['resolved_at'] ?? "N/A",
                                  icon: Icons.done_all,
                                  valueColor: Colors.green,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(10),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.description, size: 18, color: Colors.grey.shade600),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Description",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  complaintData!['description'] ?? "No description provided",
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Close Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Close",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A365D),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Icon(icon, size: 18, color: Colors.grey.shade500),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF1A365D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRejectionRow({
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 32,
          child: Icon(Icons.comment_outlined, size: 18, color: Color(0xFFDC2626)),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A365D),
              ),
            ),
          ),
        ),
      ],
    );
  }
}