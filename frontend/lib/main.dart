import 'package:flutter/material.dart';
import 'screens/shared/welcome.dart';
import 'screens/shared/role_selection_screen.dart';
import 'screens/student/student_login.dart';
import 'screens/admin/admin_login.dart';
import 'screens/super_admin/super_admin_register.dart'; 
import 'screens/super_admin/super_admin_login.dart';

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
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/student-login': (context) => const StudentLoginScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/super-admin-login': (context) => const SuperAdminLoginScreen(),
        '/super-admin-register': (context) => const SuperAdminRegisterScreen(),
      },
    );
  }
}