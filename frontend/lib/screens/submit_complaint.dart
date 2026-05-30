import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'confirmation.dart';

class SubmitComplaintScreen extends StatefulWidget {
  final String? studentId;

  const SubmitComplaintScreen({super.key, this.studentId});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final rollController    = TextEditingController();
  final deptController    = TextEditingController();
  final sessionController = TextEditingController();
  final typeController    = TextEditingController();
  final descController    = TextEditingController();

  String? selectedAdminType;
  bool isLoading = false;

  // ── File upload (bytes-based — works on Web + Mobile) ──────────
  Uint8List? _fileBytes;
  String?    _fileName;
  String?    _fileType;
  bool       isFileSelected = false;

  final List<Map<String, dynamic>> adminTypes = [
    {'value': 'administration', 'label': 'Administration', 'icon': Icons.business_center,  'color': const Color(0xFF2B6CB0)},
    {'value': 'warden',         'label': 'Warden',         'icon': Icons.apartment,         'color': const Color(0xFF10B981)},
    {'value': 'examination',    'label': 'Examination',    'icon': Icons.edit_note,          'color': const Color(0xFFF59E0B)},
    {'value': 'treasury',       'label': 'Treasury',       'icon': Icons.account_balance,    'color': const Color(0xFF8B5CF6)},
    {'value': 'security',       'label': 'Security',       'icon': Icons.security,           'color': const Color(0xFFEF4444)},
    {'value': 'transport',      'label': 'Transport',      'icon': Icons.directions_bus,     'color': const Color(0xFF06B6D4)},
    {'value': 'library',        'label': 'Library',        'icon': Icons.menu_book,          'color': const Color(0xFFEC4899)},
    {'value': 'hostel',         'label': 'Hostel',         'icon': Icons.house,              'color': const Color(0xFFF97316)},
    {'value': 'sports',         'label': 'Sports',         'icon': Icons.sports_soccer,      'color': const Color(0xFF22C55E)},
    {'value': 'it',             'label': 'IT Department',  'icon': Icons.computer,           'color': const Color(0xFF6366F1)},
  ];

  @override
  void dispose() {
    rollController.dispose();
    deptController.dispose();
    sessionController.dispose();
    typeController.dispose();
    descController.dispose();
    super.dispose();
  }

  // ── Pick file using bytes (Web + Mobile safe) ──────────────────
  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        withData: true, // ← forces bytes to be loaded on all platforms
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _fileBytes      = result.files.single.bytes;
          _fileName       = result.files.single.name;
          _fileType       = result.files.single.extension;
          isFileSelected  = true;
        });
      } else if (result != null && mounted) {
        // bytes were null — shouldn't happen with withData:true, but guard anyway
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read file. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void removeFile() {
    setState(() {
      _fileBytes     = null;
      _fileName      = null;
      _fileType      = null;
      isFileSelected = false;
    });
  }

  Future<void> submitComplaint() async {
    if (rollController.text.isEmpty ||
        deptController.text.isEmpty ||
        sessionController.text.isEmpty ||
        typeController.text.isEmpty ||
        descController.text.isEmpty ||
        selectedAdminType == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and select a department"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse('http://localhost:8000/api/student/complaint/submit/');

      var request = http.MultipartRequest('POST', url);

      // Text fields
      request.fields['roll_number']    = rollController.text.trim();
      request.fields['department']     = deptController.text.trim();
      request.fields['session']        = sessionController.text.trim();
      request.fields['complaint_type'] = typeController.text.trim();
      request.fields['title']          = typeController.text.trim();
      request.fields['description']    = descController.text.trim();
      request.fields['admin_type']     = selectedAdminType!;

      // File — attach via bytes so it works on Flutter Web too
      if (isFileSelected && _fileBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'attachment',
            _fileBytes!,
            filename: _fileName ?? 'attachment',
          ),
        );
        request.fields['attachment_name'] = _fileName ?? '';
        request.fields['attachment_type'] = _fileType ?? '';
      }

      final response     = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data         = jsonDecode(responseBody);

      if (!mounted) return;

      if (response.statusCode == 201 && data['success'] == true) {
        final String savedId = widget.studentId ?? rollController.text;

        rollController.clear();
        deptController.clear();
        sessionController.clear();
        typeController.clear();
        descController.clear();
        setState(() {
          selectedAdminType = null;
          _fileBytes        = null;
          isFileSelected    = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ComplaintSubmittedScreen(studentId: savedId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Submission failed"),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A365D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Submit Complaint",
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A365D)),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A365D), Color(0xFF2B6CB0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.withAlpha(40),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.description_outlined,
                        size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Submit Your Complaint",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select the department your complaint belongs to",
                    style:
                        TextStyle(fontSize: 13, color: Colors.white.withAlpha(179)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withAlpha(30),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(
                        label: "Roll Number",
                        hint: "Enter your roll number",
                        icon: Icons.badge_outlined,
                        controller: rollController),
                    const SizedBox(height: 18),
                    _buildInputField(
                        label: "Department",
                        hint: "Enter your department",
                        icon: Icons.business_outlined,
                        controller: deptController),
                    const SizedBox(height: 18),
                    _buildInputField(
                        label: "Session",
                        hint: "e.g., 2022-2026",
                        icon: Icons.calendar_today_outlined,
                        controller: sessionController),
                    const SizedBox(height: 18),
                    _buildInputField(
                        label: "Complaint Type",
                        hint: "Enter complaint type",
                        icon: Icons.category_outlined,
                        controller: typeController),
                    const SizedBox(height: 18),

                    // Department dropdown
                    const Text(
                      "Send To Department",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A365D)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedAdminType,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.send_outlined,
                              color: Color(0xFF2B6CB0), size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                        ),
                        hint: const Text("Select department to send complaint"),
                        items: adminTypes.map<DropdownMenuItem<String>>((type) {
                          return DropdownMenuItem<String>(
                            value: type['value'] as String,
                            child: Row(
                              children: [
                                Icon(type['icon'] as IconData,
                                    color: type['color'] as Color, size: 18),
                                const SizedBox(width: 10),
                                Text(type['label'] as String),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => selectedAdminType = value),
                        isExpanded: true,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── File Upload Section ────────────────────────
                    const Text(
                      "Attach File (Optional)",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A365D)),
                    ),
                    const SizedBox(height: 8),

                    if (!isFileSelected)
                      GestureDetector(
                        onTap: pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_upload_outlined,
                                  size: 40, color: Color(0xFF2B6CB0)),
                              const SizedBox(height: 8),
                              Text(
                                "Click to upload file",
                                style:
                                    TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Supported: Images, PDF, DOC",
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (isFileSelected)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(26),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _fileType == 'pdf'
                                    ? Icons.picture_as_pdf
                                    : (_fileType == 'jpg' ||
                                            _fileType == 'jpeg' ||
                                            _fileType == 'png'
                                        ? Icons.image
                                        : Icons.insert_drive_file),
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fileName ?? 'File',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'File attached successfully',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green.shade600),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.red, size: 20),
                              onPressed: removeFile,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 18),

                    _buildDescriptionField(
                      label: "Description",
                      hint: "Describe your issue in detail...",
                      icon: Icons.description_outlined,
                      controller: descController,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B6CB0),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            "Submit Complaint",
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A365D))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(14)),
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              prefixIcon:
                  Icon(icon, color: const Color(0xFF2B6CB0), size: 20),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A365D))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(14)),
          child: TextField(
            controller: controller,
            maxLines: 5,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Icon(icon, color: const Color(0xFF2B6CB0), size: 20),
              ),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              alignLabelWithHint: true,
            ),
          ),
        ),
      ],
    );
  }
}