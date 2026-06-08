import 'package:flutter/material.dart';
import 'screens/shared/welcome.dart';

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
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
