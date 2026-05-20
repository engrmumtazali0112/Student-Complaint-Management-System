import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PendingComplaintsScreen extends StatefulWidget {
  const PendingComplaintsScreen({super.key});

  @override
  State<PendingComplaintsScreen> createState() =>
      _PendingComplaintsScreenState();
}

class _PendingComplaintsScreenState extends State<PendingComplaintsScreen> {
  List complaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints({String query = ""}) async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        "http://localhost:8000/api/admin/complaint/pending/?search=$query");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        complaints = data['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pending Complaints",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            /// 🔍 Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                onChanged: (value) {
                  fetchComplaints(query: value);
                },
                decoration: const InputDecoration(
                  hintText: "Search complaints",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 📌 Complaints List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : complaints.isEmpty
                      ? const Center(child: Text("No complaints found"))
                      : ListView.builder(
                          itemCount: complaints.length,
                          itemBuilder: (context, index) {
                            final item = complaints[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 25),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// Left Side
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Complainant: ${item['student_name'] ?? 'N/A'}",
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Subject: ${item['complaint_type'] ?? 'N/A'}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),

                                  /// Status
                                  Text(
                                    item['status'] ?? 'Pending',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}