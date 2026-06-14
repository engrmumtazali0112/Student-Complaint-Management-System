// lib/constants/api_constants.dart
class ApiConstants {
  // For Web/Chrome - use localhost
  static const String baseUrl = 'http://localhost:8000/api';
  
  // For Android emulator (use this only for Android)
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // For iOS simulator
  // static const String baseUrl = 'http://localhost:8000/api';
  
  // For physical device (replace with your computer's IP)
  // static const String baseUrl = 'http://192.168.x.x:8000/api';
  
  static const String superAdminLogin = '/super-admin/login/';
  static const String superAdminStats = '/super-admin/stats/';
  static const String superAdminEscalated = '/super-admin/escalated/';
  static const String superAdminRatings = '/super-admin/admin-ratings/';
  static const String adminProfile = '/admin/profile/';
  static const String adminLogin = '/admin/login/';
  static const String studentLogin = '/student/login/';
}