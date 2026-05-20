import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'view_complains.dart';

class TrackComplaintsScreen extends StatefulWidget {
  final String studentId;

  const TrackComplaintsScreen({super.key, required this.studentId});

  @override
  State<TrackComplaintsScreen> createState() =>
      _TrackComplaintsScreenState();
}

class _TrackComplaintsScreenState extends State<TrackComplaintsScreen> {
  List complaints = [];
  List filteredComplaints = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      final response = await http.get(
        Uri.parse(
            "http://localhost:8000/api/student/complaint/track/${widget.studentId}/"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          complaints = data['data'];
          filteredComplaints = complaints;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load complaints");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredComplaints = complaints.where((complaint) {
        return complaint['subject']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            complaint['status']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            complaint['id']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9EDF5),
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + Title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Track Complaints",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  onChanged: filterSearch,
                  decoration: const InputDecoration(
                    hintText: "Search complaints",
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // List Section
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
                            itemCount:
                                filteredComplaints.length,
                            itemBuilder: (context, index) {
                              final complaint =
                                  filteredComplaints[index];

                              return complaintTile(
                                subject:
                                    complaint['subject'],
                                id: complaint['id']
                                    .toString(),
                                status:
                                    complaint['status'],
                                complaintId:
                                    complaint['id'],
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

  Widget complaintTile({
    required String subject,
    required String id,
    required String status,
    required int complaintId,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () {
          Navigator.push(
             context,
             MaterialPageRoute(
             builder: (context) => ViewComplaintDetailsScreen(
                 complaintId: complaintId,
                 studentId: widget.studentId,
                  ),
                ),
          );
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    "Subject: $subject",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ID: $id | Status: $status",
                    style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right,
                  size: 24),
            ],
          ),
        ),
      ),
    );
  }
}