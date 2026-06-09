import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'student_register.dart';
import 'student_sidebar_dashboard.dart';
import '../shared/welcome.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    studentIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (studentIdController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Student ID and Password'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse('http://localhost:8000/api/student/login/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentIdController.text,
          'password': passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response.statusCode == 200 && data['success'] == true) {
        String studentId = data['student_id'];
        String studentName = data['name'] ?? studentId;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentSidebarDashboard(
              studentId: studentId,
              studentName: studentName,
              studentUsername: studentId, // ✅ fixed: pass studentUsername
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Login failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error connecting to server'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.grey.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        color: const Color(0xFF1A365D),
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen())),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF2B6CB0).withAlpha(26), borderRadius: BorderRadius.circular(20)),
                      child: const Text("Student", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2B6CB0))),
                    ),
                  ],
                ),
              ),

              // Hero section
              Stack(
                children: [
                  Container(
                    height: 260,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF1A365D), Color(0xFF2B6CB0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                    ),
                  ),
                  Positioned(top: 40, right: -30, child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.white.withAlpha(13), shape: BoxShape.circle))),
                  Positioned(top: 120, left: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(color: Colors.white.withAlpha(10), shape: BoxShape.circle))),
                  Positioned(
                    bottom: 20, left: 20, right: 20,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, 10))]),
                          child: const Icon(Icons.school_rounded, size: 55, color: Color(0xFF2B6CB0)),
                        ),
                        const SizedBox(height: 16),
                        const Text("Student Portal", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        const Text("Welcome Back!", style: TextStyle(fontSize: 15, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Login form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.grey.withAlpha(40), blurRadius: 20, offset: const Offset(0, 8))]),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Student ID", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A365D))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: studentIdController,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF2B6CB0)),
                            hintText: "Enter your Student ID",
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            filled: true, fillColor: const Color(0xFFF7F9FC),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text("Password", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A365D))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2B6CB0)),
                            suffixIcon: IconButton(
                              icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                              onPressed: () => setState(() => obscurePassword = !obscurePassword),
                            ),
                            hintText: "Enter your password",
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            filled: true, fillColor: const Color(0xFFF7F9FC),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact admin to reset password'), behavior: SnackBarBehavior.floating)),
                            child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFF2B6CB0), fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity, height: 55,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B6CB0), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            child: isLoading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Login to Account", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(children: [
                          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text("New Student?", style: TextStyle(color: Colors.grey.shade500, fontSize: 14))),
                          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                        ]),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity, height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegisterScreen())),
                            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2B6CB0), side: const BorderSide(color: Color(0xFF2B6CB0)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            child: const Text("Create New Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              Center(child: Text("© 2026 Digital Complaint System", style: TextStyle(color: Colors.grey.shade400, fontSize: 12))),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}