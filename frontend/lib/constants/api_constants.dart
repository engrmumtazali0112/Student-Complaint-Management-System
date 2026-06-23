import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConstants {
  // Your computer's LAN IP — used only for physical Android/iOS devices.
  static const String _lanIp = 'http://192.168.220.182:8000';

  // Automatically picks the right host per platform, so you don't have to
  // hand-edit this every time you switch between Chrome and a real device.
  static String get baseUrl {
    if (kIsWeb) {
      // Chrome / Edge / any browser target -> backend on the same machine.
      return 'http://localhost:8000';
    }
    if (Platform.isAndroid) {
      // NOTE: Android emulator needs 10.0.2.2, a *physical* Android phone
      // needs _lanIp. Flip this if you're on the emulator instead.
      return _lanIp; // or 'http://10.0.2.2:8000' for the emulator
    }
    if (Platform.isIOS) {
      // iOS simulator can use localhost; a physical iPhone needs _lanIp.
      return _lanIp; // or 'http://localhost:8000' for the simulator
    }
    return _lanIp;
  }
  
  // Super Admin Endpoints
  static const String superAdminLogin = '/api/super-admin/login/';
  static const String superAdminRegister = '/api/super-admin/register/';
  static const String superAdminStats = '/api/super-admin/stats/';
  static const String superAdminEscalated = '/api/super-admin/escalated/';
  static const String superAdminReassign = '/api/super-admin/reassign/';
  static const String superAdminResolve = '/api/super-admin/resolve/';
  static const String superAdminAdminRatings = '/api/super-admin/admin-ratings/';
  
  // Admin Endpoints
  static const String adminLogin = '/api/admin/login/';
  static const String adminRegister = '/api/admin/register/';
  static const String adminProfile = '/api/admin/profile/';
  static const String adminUploadProfilePic = '/api/admin/upload-profile-pic/';
  static const String adminComplaints = '/api/admin/complaints/';
  static const String adminAnonymousComplaints = '/api/admin/anonymous-complaints/';
  static const String adminComplaintPending = '/api/admin/complaint/pending/';
  static const String adminComplaintSolved = '/api/admin/complaint/solved/';
  static const String adminComplaintRejected = '/api/admin/complaint/rejected/';
  static const String adminComplaintUpdateStatus = '/api/admin/complaint/update-status/';
  static const String adminComplaintReject = '/api/admin/complaint/reject/';
  static const String adminNewCount = '/api/admin/new-count/';
  static const String adminMarkSeen = '/api/admin/mark-seen/';
  static const String adminNotifications = '/api/admin/notifications/';
  static const String adminNotificationCount = '/api/admin/notifications/count/';
  static const String adminMarkNotificationRead = '/api/admin/notifications/mark-read/';
  
  // Student Endpoints
  static const String studentLogin = '/api/student/login/';
  static const String studentRegister = '/api/student/register/';
  static const String studentDashboard = '/api/student/dashboard/';
  static const String studentProfile = '/api/student/profile/';
  static const String studentUploadProfilePic = '/api/student/upload-profile-pic/';
  static const String submitComplaint = '/api/student/complaint/submit/';
  static const String trackComplaints = '/api/student/complaint/track/';
  static const String studentResolvedComplaints = '/api/student/complaint/resolved/';
  static const String studentRejectedComplaints = '/api/student/complaint/rejected/';
  static const String studentComplaintDetail = '/api/student/complaint/';
  static const String studentRateAdmin = '/api/student/rate-admin/';
  static const String studentComplaintRating = '/api/student/complaint-rating/';
  static const String studentNotifications = '/api/student/notifications/';
  static const String studentMarkNotificationRead = '/api/student/notifications/mark-read/';
  static const String studentMarkAllNotificationsRead = '/api/student/notifications/mark-all-read/';
  static const String studentResolvedCount = '/api/student/resolved-count/';
  static const String studentRejectedCount = '/api/student/rejected-count/';
  static const String studentMarkResolvedSeen = '/api/student/mark-resolved-seen/';
  
  // Other Endpoints
  static const String complaintDetail = '/api/complaint/';
  static const String availableDepartments = '/api/departments/available/';
}