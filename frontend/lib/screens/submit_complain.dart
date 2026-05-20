import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'confirmation.dart';

class SubmitComplaintScreen extends StatefulWidget {
  const SubmitComplaintScreen({super.key});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final rollController = TextEditingController();
  final deptController = TextEditingController();
  final sessionController = TextEditingController();
  final typeController = TextEditingController();
  final descController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    rollController.dispose();
    deptController.dispose();
    sessionController.dispose();
    typeController.dispose();
    descController.dispose();
    super.dispose();
  }

  Future<void> submitComplaint() async {
    if (rollController.text.isEmpty ||
        deptController.text.isEmpty ||
        sessionController.text.isEmpty ||
        typeController.text.isEmpty ||
        descController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('http://localhost:8000/api/student/complaint/submit/'); // Replace with your URL

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roll_number': rollController.text,
          'department': deptController.text,
          'session': sessionController.text,
          'complaint_type': typeController.text,
          'description': descController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return; // ✅ Check context before using it

      if (response.statusCode == 201 && data['success'] == true) {
        // Clear fields after submission
        rollController.clear();
        deptController.clear();
        sessionController.clear();
        typeController.clear();
        descController.clear();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ComplaintSubmittedScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Submission failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8ECF5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Submit Complaint",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                "Fill in the details below to submit your complaint",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 25),

            buildLabel("Roll number"),
            buildInput(rollController),

            const SizedBox(height: 18),
            buildLabel("Department"),
            buildInput(deptController),

            const SizedBox(height: 18),
            buildLabel("Session"),
            buildInput(sessionController),

            const SizedBox(height: 18),
            buildLabel("Complaint type"),
            buildInput(typeController, hint: "Enter complaint type"),

            const SizedBox(height: 18),
            buildLabel("Description"),
            buildInput(descController, maxLines: 5),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: isLoading ? null : submitComplaint,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  backgroundColor: const Color(0xFF0D6EFD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper widgets
  Widget buildLabel(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    );
  }

  Widget buildInput(TextEditingController controller,
      {String? hint, int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E9F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45),
        ),
      ),
    );
  }
}
