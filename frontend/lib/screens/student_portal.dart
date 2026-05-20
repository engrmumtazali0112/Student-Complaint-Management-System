import 'package:flutter/material.dart';
import 'student_dashboard.dart';
//import 'view_complains.dart';
import 'track_complains.dart';

class StudentPortalScreen extends StatelessWidget {
  final String studentId;
  const StudentPortalScreen({super.key , required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      // Centering all content vertically and horizontally
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon + Title
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 40,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Student Portal",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),

              // Buttons Section
              buildBlueButton(context, "File Complaints"),
              const SizedBox(height: 20),
              buildBlueButton(context, "View Complaints"),
              const SizedBox(height: 20),
              buildBlueButton(context, "Track Complaints"),
              const SizedBox(height: 40),

              // Logout Button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E9F1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Text(
                      "Logout",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable blue button
  Widget buildBlueButton(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        if (title == "File Complaints") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  StudentDashboard(studentId: studentId)),
          );
        } else if (title == "View Complaints") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TrackComplaintsScreen(studentId: studentId,),),
            );
        } else if (title == "Track Complaints") {
           Navigator.push(context, MaterialPageRoute(builder: (context) => TrackComplaintsScreen(studentId: studentId)));
        }
      },
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D6EFD),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
