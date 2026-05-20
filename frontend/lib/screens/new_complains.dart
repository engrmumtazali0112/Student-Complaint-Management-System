import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'view_complains.dart';

class NewComplaintsScreen extends StatefulWidget {
  const NewComplaintsScreen({super.key});

  @override
  State<NewComplaintsScreen> createState() =>
      _NewComplaintsScreenState();
}

class _NewComplaintsScreenState extends State<NewComplaintsScreen> {
  List complaints = [];
  List filteredComplaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  /// 🔥 FETCH COMPLAINTS
  Future<void> fetchComplaints() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://localhost:8000/api/admin/complaint/",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          complaints = data['data'];
          filteredComplaints = complaints;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 🔍 SEARCH
  void filterSearch(String query) {
    setState(() {
      filteredComplaints = complaints.where((c) {
        return c['complaint_type']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            c['id']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            c['student_id']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());
      }).toList();
    });
  }

  /// 🔄 UPDATE STATUS API
  Future<void> updateStatus(int id, String status) async {
    final url = Uri.parse(
      "http://127.0.0.1:8000/api/admin/complaint/update-status/$id/",
    );

    try {
      final response = await http.patch(
        url,
        body: {"status": status},
      );

      if (response.statusCode == 200) {
        fetchComplaints(); // refresh list
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              /// HEADER
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "New Complaints",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// SEARCH
              TextField(
                onChanged: filterSearch,
                decoration: InputDecoration(
                  hintText: "Search complaints...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// LIST
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : filteredComplaints.isEmpty
                        ? const Center(
                            child: Text("No complaints found"),
                          )
                        : ListView.builder(
                            itemCount: filteredComplaints.length,
                            itemBuilder: (context, index) {
                              final c = filteredComplaints[index];

                              return complaintTile(
                                subject:
                                    c['complaint_type'] ?? "",
                                id: c['id'].toString(),
                                studentId:
                                    c['student_id'] ?? "N/A",
                                complaintId: c['id'],
                                status: c['status'] ?? "Pending",
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🧩 COMPLAINT TILE (SAFE + PROFESSIONAL)
  Widget complaintTile({
    required String subject,
    required String id,
    required String studentId,
    required int complaintId,
    required String status,
  }) {
    Color statusColor =
        status == "Resolved" ? Colors.green : const Color.fromARGB(255, 236, 58, 58);

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () {
          /// 🚨 YOUR EXISTING NAVIGATION (UNCHANGED)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewComplaintDetailsScreen(
                complaintId: complaintId,
                studentId: studentId,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: .1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// TOP ROW
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  /// STATUS BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// DETAILS
              Text(
                "ID: $id | Student: $studentId",
                style:
                    TextStyle(color: Colors.grey.shade700),
              ),

              const SizedBox(height: 12),

              /// ACTION BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [

                  /// SOLVE
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      updateStatus(complaintId, "Resolved");
                    },
                    child: const Text("Solve"),
                  ),

                  const SizedBox(width: 10),

                  /// PENDING
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 214, 72, 72),
                    ),
                    onPressed: () {
                      updateStatus(complaintId, "Pending");
                    },
                    child: const Text("Pending"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}