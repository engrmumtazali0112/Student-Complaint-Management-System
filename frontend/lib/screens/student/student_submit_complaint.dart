import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../student/student_sidebar_dashboard.dart';

class SubmitComplaintScreen extends StatefulWidget {
  final String studentId;

  const SubmitComplaintScreen({super.key, required this.studentId});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  
  String? selectedComplaintType;
  String? selectedAdminType;
  Uint8List? selectedFileBytes;
  String? fileName;
  String? fileMimeType;
  
  bool isLoading = false;
  bool isLoadingDepartments = true;
  
  List<Map<String, dynamic>> availableDepartments = [];
  
  final List<String> complaintTypes = [
    'Academic Issue',
    'Fee Issue',
    'Hostel Issue',
    'Transport Issue',
    'Library Issue',
    'Sports Issue',
    'IT/Lab Issue',
    'Security Issue',
    'Examination Issue',
    'General Complaint',
    'Infrastructure Issue',
    'Harassment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    fetchAvailableDepartments();
  }

  Future<void> fetchAvailableDepartments() async {
    setState(() => isLoadingDepartments = true);
    
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/departments/available/'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            availableDepartments = List<Map<String, dynamic>>.from(data['departments']);
            isLoadingDepartments = false;
          });
          
          if (availableDepartments.isNotEmpty && mounted) {
            setState(() {
              selectedAdminType = availableDepartments[0]['value'] as String;
            });
          }
        } else {
          if (mounted) setState(() => isLoadingDepartments = false);
          _showErrorSnackBar('Failed to load departments');
        }
      } else {
        if (mounted) setState(() => isLoadingDepartments = false);
        _showErrorSnackBar('Server error. Please try again.');
      }
    } catch (e) {
      debugPrint('Error fetching departments: $e');
      if (mounted) setState(() => isLoadingDepartments = false);
      _showErrorSnackBar('Connection error. Please check your internet.');
    }
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        withData: true, // required for Flutter Web
      );

      if (result != null && mounted) {
        final file = result.files.single;
        if (file.bytes == null) {
          _showErrorSnackBar('Could not read file. Please try again.');
          return;
        }
        setState(() {
          selectedFileBytes = file.bytes;
          fileName = file.name;
          fileMimeType = _getMimeType(file.extension ?? '');
        });
        _showSuccessSnackBar('File attached successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Error picking file: $e');
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> submitComplaint() async {
    if (titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a complaint title');
      return;
    }
    
    if (descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter complaint description');
      return;
    }
    
    if (selectedComplaintType == null) {
      _showErrorSnackBar('Please select complaint type');
      return;
    }
    
    if (selectedAdminType == null) {
      _showErrorSnackBar('Please select department to send complaint');
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/api/student/complaint/submit/'),
      );
      
      request.fields['roll_number'] = widget.studentId;
      request.fields['department'] = selectedComplaintType!;
      request.fields['session'] = '2024-2028';
      request.fields['complaint_type'] = selectedComplaintType!;
      request.fields['title'] = titleController.text.trim();
      request.fields['description'] = descriptionController.text.trim();
      request.fields['admin_type'] = selectedAdminType!;
      
      if (selectedFileBytes != null && fileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'attachment',
            selectedFileBytes!,
            filename: fileName,
          ),
        );
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (!mounted) return;
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar('Complaint submitted successfully!');
          
          titleController.clear();
          descriptionController.clear();
          setState(() {
            selectedComplaintType = null;
            selectedFileBytes = null;
            fileName = null;
            fileMimeType = null;
          });

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => StudentSidebarDashboard(
                studentId: widget.studentId,
                studentName: widget.studentId,
                studentUsername: widget.studentId,
              ),
            ),
            (route) => false, // clears the entire back stack
          );
        } else {
          _showErrorSnackBar(data['message'] ?? 'Submission failed');
        }
      } else {
        _showErrorSnackBar('Failed to submit complaint. Please try again.');
      }
    } catch (e) {
      debugPrint('Submit error: $e');
      _showErrorSnackBar('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          "Submit Complaint",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A365D),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoadingDepartments
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2B6CB0)),
                  SizedBox(height: 16),
                  Text("Loading available departments..."),
                ],
              ),
            )
          : availableDepartments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_center, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "No departments available",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Please contact administrator",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(30),
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
                              // Title Field
                              const Text(
                                "Complaint Title *",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A365D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: titleController,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  hintText: "Brief title of your complaint",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF7F9FC),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Complaint Type Dropdown
                              const Text(
                                "Complaint Type *",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A365D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: selectedComplaintType,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF7F9FC),
                                ),
                                items: complaintTypes.map<DropdownMenuItem<String>>((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedComplaintType = value;
                                  });
                                },
                                hint: const Text("Select complaint type"),
                              ),
                              const SizedBox(height: 20),

                              // Send To Department
                              const Text(
                                "Send To Department *",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A365D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F9FC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedAdminType,
                                    isExpanded: true,
                                    hint: const Text("Select department"),
                                    items: availableDepartments.map<DropdownMenuItem<String>>((dept) {
                                      return DropdownMenuItem<String>(
                                        value: dept['value'] as String,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dept['label'] as String,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              "Admin: ${dept['admin_name']}",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedAdminType = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Description Field
                              const Text(
                                "Description *",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A365D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: descriptionController,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText: "Describe your complaint in detail...",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF7F9FC),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // File Attachment
                              const Text(
                                "Attach File (Optional)",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A365D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: pickFile,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFFF7F9FC),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.attach_file,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          fileName ?? 'Click to attach file (jpg, png, pdf, doc)',
                                          style: TextStyle(
                                            color: fileName != null ? Colors.green : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                      if (fileName != null)
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 20),
                                          onPressed: () {
                                            setState(() {
                                              selectedFileBytes = null;
                                              fileName = null;
                                              fileMimeType = null;
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : submitComplaint,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2B6CB0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          "Submit Complaint",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    titleController.dispose();
    super.dispose();
  }
}