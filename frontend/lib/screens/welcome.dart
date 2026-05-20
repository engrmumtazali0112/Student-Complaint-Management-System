import 'package:flutter/material.dart';
import 'role_selection_screen.dart';

void main() {
  runApp(const DigitalComplaintSystem());
}

class DigitalComplaintSystem extends StatelessWidget {
  const DigitalComplaintSystem({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Complaint System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Image
            SizedBox(
              height: size.height * 0.3,
              width: double.infinity,
              child: Image.asset(
                'assets/images/clg pic.jpg', // replace with your image path
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            const Text(
              'Digital Complaint System',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Submit, track, and resolve complaints efficiently with our streamlined platform',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 28),

            // Feature Cards
            const FeatureCard(
              icon: Icons.check_circle,
              iconColor: Colors.green,
              title: 'Easy Complaint Submission',
              subtitle: 'Submit in under 2 minutes',
            ),
            const FeatureCard(
              icon: Icons.access_time,
              iconColor: Colors.orange,
              title: 'Real-time Status Tracking',
              subtitle: 'Live updates on progress',
            ),
            const FeatureCard(
              icon: Icons.security,
              iconColor: Colors.purple,
              title: 'Secure And Confidential',
              subtitle: 'Enterprise-grade security',
            ),

            const SizedBox(height: 30),

            // Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Reusable Feature Card Widget
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withAlpha(26),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
