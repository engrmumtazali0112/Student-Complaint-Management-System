import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SolvedComplaintsScreen extends StatefulWidget {
  const SolvedComplaintsScreen({super.key});

  @override
  State<SolvedComplaintsScreen> createState() => _SolvedComplaintsScreenState();
}

class _SolvedComplaintsScreenState extends State<SolvedComplaintsScreen> {
  List complaints = [];
  bool isLoading = true;
  String searchQuery = "";

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
        "http://127.0.0.1:8000/api/admin/complaint/solved/?search=$query");

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
      backgroundColor: const Color(0xFFF1F5FB),
      appBar: AppBar(
        title: const Text("Solved Complaints"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 Search Bar
            TextField(
              onChanged: (value) {
                searchQuery = value;
                fetchComplaints(query: value);
              },
              decoration: InputDecoration(
                hintText: "Search complaints...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 📋 List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : complaints.isEmpty
                      ? const Center(child: Text("No complaints found"))
                      : ListView.builder(
                          itemCount: complaints.length,
                          itemBuilder: (context, index) {
                            final c = complaints[index];

                            return ListTile(
                              title: Text(
                                "${c['complaint_type']} - ${c['department']} Departement",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "ID: ${c['id']} | Resolved: ${c['resolved_at']}",
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {},
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