import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'student_login.dart';

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  
  Uint8List? selectedImageBytes;
  String? selectedImageName;
  bool isUploadingPicture = false;

  final List<String> departments = [
    'Select Department',
    'Computer Science',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Business Administration',
  ];
  String? selectedDepartment;

  Future<void> pickProfilePicture() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && mounted) {
        setState(() {
          selectedImageBytes = result.files.single.bytes;
          selectedImageName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error picking image: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> uploadProfilePicture(String studentId) async {
    if (selectedImageBytes == null) return;
    
    setState(() => isUploadingPicture = true);
    
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/api/student/upload-profile-pic/'),
      );
      
      request.fields['student_id'] = studentId;
      
      var multipartFile = http.MultipartFile.fromBytes(
        'profile_picture',
        selectedImageBytes!,
        filename: selectedImageName ?? 'profile.jpg',
      );
      
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        debugPrint("Profile picture uploaded successfully");
      } else {
        debugPrint("Failed to upload profile picture: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error uploading profile picture: $e");
    } finally {
      if (mounted) {
        setState(() => isUploadingPicture = false);
      }
    }
  }

  // Validate roll number format
  bool isValidRollNumber(String rollNo) {
    final regex = RegExp(r'^[A-Z]{2}-\d{2}[A-Z]/\d{2}-\d{2}$');
    return regex.hasMatch(rollNo.toUpperCase());
  }

  Future<void> registerStudent() async {
    // Validation
    if (nameController.text.isEmpty ||
        fatherNameController.text.isEmpty ||
        rollNoController.text.isEmpty ||
        selectedDepartment == null ||
        selectedDepartment == 'Select Department' ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate roll number format
    if (!isValidRollNumber(rollNoController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid roll number format. Use format: CS-06F/22-26'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 6 characters"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse('http://localhost:8000/api/student/register/');

    try {
      final requestBody = {
        "name": nameController.text.trim(),
        "father_name": fatherNameController.text.trim(),
        "roll_no": rollNoController.text.trim().toUpperCase(),
        "department": selectedDepartment,
        // Session field removed - backend will handle default value
        "password": passwordController.text,
        "confirm_password": confirmPasswordController.text,
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "address": addressController.text.trim(),
        "date_of_birth": dobController.text.trim().isEmpty ? null : dobController.text.trim(),
      };

      debugPrint("Sending request to: $url");
      debugPrint("Request body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (!mounted) return;

      if (response.body.trim().startsWith('{')) {
        final data = jsonDecode(response.body);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (data['success'] == true) {
            if (selectedImageBytes != null) {
              await uploadProfilePicture(rollNoController.text.trim().toUpperCase());
            }
            
            if (!mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Registration successful! Please login."),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );

            nameController.clear();
            fatherNameController.clear();
            rollNoController.clear();
            passwordController.clear();
            confirmPasswordController.clear();
            emailController.clear();
            phoneController.clear();
            addressController.clear();
            dobController.clear();
            setState(() {
              selectedDepartment = null;
              selectedImageBytes = null;
            });

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentLoginScreen(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Registration failed'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Registration failed. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        debugPrint("Non-JSON response received");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server error. Please check if backend is running correctly.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint("Registration error: $e");
      if (!mounted) return;
      
      String errorMessage = "Connection error. Please make sure the server is running.";
      if (e.toString().contains('Connection refused')) {
        errorMessage = "Cannot connect to server. Please ensure backend is running on port 8000.";
      } else if (e.toString().contains('timeout')) {
        errorMessage = "Connection timeout. Please check your network.";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
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
          "Registration",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A365D),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
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
              ),
              child: Column(
                children: [
                  const Icon(Icons.person_add_alt_1, size: 50, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    "Create Your Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Join the Digital Complaint System",
                    style: TextStyle(
                      color: Colors.white.withAlpha(179),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(30),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: pickProfilePicture,
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFF7F9FC),
                                    border: Border.all(
                                      color: const Color(0xFF2B6CB0),
                                      width: 2,
                                    ),
                                    image: selectedImageBytes != null
                                        ? DecorationImage(
                                            image: MemoryImage(selectedImageBytes!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: selectedImageBytes == null
                                      ? const Icon(
                                          Icons.camera_alt,
                                          size: 40,
                                          color: Color(0xFF2B6CB0),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2B6CB0),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedImageBytes == null 
                                ? "Tap to add profile picture" 
                                : "Profile picture selected",
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedImageBytes == null 
                                  ? Colors.grey.shade600 
                                  : const Color(0xFF2B6CB0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    
                    _buildInputField(
                      label: "Full Name *",
                      hint: "Enter your full name",
                      icon: Icons.person_outline,
                      controller: nameController,
                    ),
                    const SizedBox(height: 16),

                    _buildInputField(
                      label: "Father Name *",
                      hint: "Enter your father's name",
                      icon: Icons.family_restroom_outlined,
                      controller: fatherNameController,
                    ),
                    const SizedBox(height: 16),

                    _buildInputField(
                      label: "Roll Number *",
                      hint: "e.g., CS-06F/22-26",
                      icon: Icons.numbers_outlined,
                      controller: rollNoController,
                    ),
                    const SizedBox(height: 16),

                    // Department Dropdown
                    const Text(
                      "Department *",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A365D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedDepartment,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.business_outlined,
                            color: Color(0xFF2B6CB0),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                        items: departments.map((dept) {
                          return DropdownMenuItem(
                            value: dept,
                            child: Text(dept),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDepartment = value;
                          });
                        },
                        hint: const Text("Select Department"),
                        isExpanded: true,
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Session field REMOVED - no longer displayed

                    _buildInputField(
                      label: "Email",
                      hint: "your@email.com",
                      icon: Icons.email_outlined,
                      controller: emailController,
                    ),
                    const SizedBox(height: 16),

                    _buildInputField(
                      label: "Phone",
                      hint: "0300-1234567",
                      icon: Icons.phone_outlined,
                      controller: phoneController,
                    ),
                    const SizedBox(height: 16),

                    _buildInputField(
                      label: "Address",
                      hint: "Your complete address",
                      icon: Icons.location_on_outlined,
                      controller: addressController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    _buildInputField(
                      label: "Date of Birth",
                      hint: "YYYY-MM-DD",
                      icon: Icons.cake_outlined,
                      controller: dobController,
                    ),
                    const SizedBox(height: 16),

                    _buildPasswordField(
                      label: "Password *",
                      hint: "Create a password (min 6 characters)",
                      controller: passwordController,
                      obscureText: obscurePassword,
                      onToggle: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildPasswordField(
                      label: "Confirm Password *",
                      hint: "Re-enter your password",
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      onToggle: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : registerStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B6CB0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Create Account",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account? ",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentLoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Login Here",
                    style: TextStyle(
                      color: Color(0xFF2B6CB0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
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
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A365D),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF2B6CB0)),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A365D),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2B6CB0)),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: onToggle,
              ),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    fatherNameController.dispose();
    rollNoController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    dobController.dispose();
    super.dispose();
  }
}