// lib/screens/super_admin/super_admin_register.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'super_admin_login.dart';
import '../../constants/api_constants.dart';

class SuperAdminRegisterScreen extends StatefulWidget {
  const SuperAdminRegisterScreen({super.key});

  @override
  State<SuperAdminRegisterScreen> createState() => _SuperAdminRegisterScreenState();
}

class _SuperAdminRegisterScreenState extends State<SuperAdminRegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _obscureSecret = true;
  bool _isLoading = false;
  
  Uint8List? _selectedProfileImageBytes;
  String? _selectedProfileImageName;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _secretKeyController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePicture() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && mounted) {
        setState(() {
          _selectedProfileImageBytes = result.files.single.bytes;
          _selectedProfileImageName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error picking image: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadProfilePicture(String username) async {
    if (_selectedProfileImageBytes == null) return;
    
    
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/super-admin/upload-profile-pic/'),
      );
      
      request.fields['username'] = username;
      
      var multipartFile = http.MultipartFile.fromBytes(
        'profile_picture',
        _selectedProfileImageBytes!,
        filename: _selectedProfileImageName ?? 'profile.jpg',
      );
      
      request.files.add(multipartFile);
      
      final response = await request.send();
      
      if (response.statusCode == 200) {
        debugPrint("Super Admin profile picture uploaded successfully");
      } else {
        debugPrint("Failed to upload Super Admin profile picture");
      }
    } catch (e) {
      debugPrint("Error uploading Super Admin profile picture: $e");
    } finally {
      if (mounted) {
      }
    }
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final secretKey = _secretKeyController.text.trim();
    final phone = _phoneController.text.trim();
    final department = _departmentController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();

    if ([name, username, password, confirmPassword, secretKey].any((s) => s.isEmpty)) {
      _showSnack('Please fill in all required fields.', isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showSnack('Passwords do not match.', isError: true);
      return;
    }

    if (password.length < 8) {
      _showSnack('Password must be at least 8 characters.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/super-admin/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'username': username,
          'password': password,
          'confirm_password': confirmPassword,
          'super_admin_secret_key': secretKey,
          'phone': phone,
          'department': department,
          'email': email,
          'address': address,
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        if (_selectedProfileImageBytes != null) {
          await _uploadProfilePicture(username);
        }
        
        _showSnack('Super Admin account created! Please log in.', isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          _fadeRoute(const SuperAdminLoginScreen()),
        );
      } else {
        _showSnack(data['message'] ?? 'Registration failed.', isError: true);
      }
    } catch (e) {
      _showSnack('Connection error. Is the server running?', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F2942)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildTopBar(),
                      const SizedBox(height: 36),
                      _buildHeroSection(),
                      const SizedBox(height: 30),
                      _buildFormCard(),
                      const SizedBox(height: 24),
                      _buildLoginRow(),
                      const SizedBox(height: 32),
                      _buildFooter(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70, size: 18),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.25)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings, color: Color(0xFF60A5FA), size: 14),
              SizedBox(width: 6),
              Text('Super Admin', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 20),
        const Text('Create Super Admin Account', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: 0.2)),
        const SizedBox(height: 8),
        Text('A valid super admin secret key is required to register.', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickProfilePicture,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(color: const Color(0xFF1565C0), width: 2),
                          image: _selectedProfileImageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_selectedProfileImageBytes!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _selectedProfileImageBytes == null
                            ? const Icon(Icons.admin_panel_settings, size: 50, color: Color(0xFF1565C0))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedProfileImageBytes == null 
                      ? "Tap to add profile picture" 
                      : "Profile picture selected",
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 20),

          _fieldLabel('Full Name *'),
          const SizedBox(height: 8),
          _buildTextField(controller: _nameController, hint: 'Enter your full name', icon: Icons.person_outline_rounded),
          const SizedBox(height: 18),

          _fieldLabel('Username / Admin ID *'),
          const SizedBox(height: 8),
          _buildTextField(controller: _usernameController, hint: 'Choose a unique username', icon: Icons.badge_outlined),
          const SizedBox(height: 18),

          _fieldLabel('Department (Optional)'),
          const SizedBox(height: 8),
          _buildTextField(controller: _departmentController, hint: 'Department name', icon: Icons.business_outlined),
          const SizedBox(height: 18),

          _fieldLabel('Phone (Optional)'),
          const SizedBox(height: 8),
          _buildTextField(controller: _phoneController, hint: 'Contact number', icon: Icons.phone_outlined),
          const SizedBox(height: 18),

          _fieldLabel('Email (Optional)'),
          const SizedBox(height: 8),
          _buildTextField(controller: _emailController, hint: 'Email address', icon: Icons.email_outlined),
          const SizedBox(height: 18),

          _fieldLabel('Address (Optional)'),
          const SizedBox(height: 8),
          _buildTextField(controller: _addressController, hint: 'Office address', icon: Icons.location_on_outlined, maxLines: 2),
          const SizedBox(height: 18),

          _fieldLabel('Password *'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passwordController,
            hint: 'At least 8 characters',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffixIcon: _eyeButton(_obscurePassword, () => setState(() => _obscurePassword = !_obscurePassword)),
          ),
          const SizedBox(height: 18),

          _fieldLabel('Confirm Password *'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: 'Re-enter your password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureConfirm,
            suffixIcon: _eyeButton(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
          ),
          const SizedBox(height: 18),

          _fieldLabel('Super Admin Secret Key *'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _secretKeyController,
            hint: 'Enter the secret key',
            icon: Icons.vpn_key_outlined,
            obscure: _obscureSecret,
            suffixIcon: _eyeButton(_obscureSecret, () => setState(() => _obscureSecret = !_obscureSecret)),
          ),

          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Default secret key is: SUPER_ADMIN_SECRET_2026',
                    style: TextStyle(color: const Color(0xFFF59E0B).withValues(alpha: 0.85), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.admin_panel_settings, size: 18),
                        SizedBox(width: 8),
                        Text('Create Super Admin Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Already have an account? ", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(context, _fadeRoute(const SuperAdminLoginScreen())),
          child: const Text('Login here', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text('© 2026 Digital Complaint System', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12)),
    );
  }

  Widget _fieldLabel(String label) => Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2));

  Widget _eyeButton(bool obscure, VoidCallback onTap) => IconButton(
        icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white38, size: 20),
        onPressed: onTap,
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF60A5FA), size: 20),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}