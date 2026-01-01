import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:flutter_application_1/view/auth/login/login.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminEditProfile extends StatefulWidget {
  const AdminEditProfile({super.key});

  @override
  State<AdminEditProfile> createState() => _AdminEditProfileState();
}

class _AdminEditProfileState extends State<AdminEditProfile> {
  // Professional Color Palette
  static const Color primaryTeal = Color(0xFF00796B);
  static const Color lightTeal = Color(0xFF4DB6AC);
  static const Color cardGrey = Color(0xFFF8F9FA);
  static const Color darkGrey = Color(0xFF2C3E50);

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Firebase & Supabase
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  // State
  File? _imageFile;
  String? _imageUrl;
  bool _loading = true;
  bool _saving = false;
  String _role = 'admin';

  String get _uid => _auth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Load Admin Data from Firestore
  Future<void> _loadAdminData() async {
    log('Loading admin data for $_uid');
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();

      if (doc.exists) {
        setState(() {
          _nameController.text = doc['name'] ?? '';
          _emailController.text = doc['email'] ?? _auth.currentUser!.email ?? '';
          _phoneController.text = doc['phone'] ?? '';
          _role = doc['role'] ?? 'admin';
          _imageUrl = doc['imageUrl'];
        });
        log('Admin data loaded successfully');
      } else {
        _emailController.text = _auth.currentUser!.email ?? '';
      }
    } catch (e) {
      log('Load Admin Error: $e');
      _showSnackBar('Failed to load profile data', isError: true);
    }

    setState(() => _loading = false);
  }

  /// Pick Image from Gallery
  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
        log('Image selected: ${picked.path}');
      }
    } catch (e) {
      log('Pick Image Error: $e');
      _showSnackBar('Failed to select image', isError: true);
    }
  }

  /// Save Admin Profile
  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    setState(() => _saving = true);
    log('Saving admin profile for $_uid');

    String? uploadedImageUrl;

    try {
      // Upload image to Supabase if selected
      if (_imageFile != null) {
        final folder = _role.toLowerCase();
        final fileName = '${_uid}_${DateTime.now().millisecondsSinceEpoch}.png';
        final path = '$folder/$fileName';
        
        log('Uploading image to Supabase: $path');

        await _supabase.storage.from('images').upload(
          path,
          _imageFile!,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ),
        );

        uploadedImageUrl = _supabase.storage.from('images').getPublicUrl(path);
        log('Image uploaded successfully: $uploadedImageUrl');
      }

      // Update Firestore
      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _role,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (uploadedImageUrl != null) {
        data['imageUrl'] = uploadedImageUrl;
      }

      await _firestore.collection('users').doc(_uid).set(
        data,
        SetOptions(merge: true),
      );

      log('Admin profile updated successfully');
      _showSnackBar('Profile updated successfully!');

      // Reload data to show updated info
      await _loadAdminData();
      setState(() => _imageFile = null); // Clear local file

    } catch (e) {
      log('Save Profile Error: $e');
      _showSnackBar('Failed to update profile', isError: true);
    }

    setState(() => _saving = false);
  }

  /// Logout
  Future<void> _logout() async {
    try {
      log('Logging out admin $_uid');
      await AuthService().signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      }
    } catch (e) {
      log('Logout Error: $e');
    }
  }

  /// Show SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryTeal),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildProfileImage(),
                          const SizedBox(height: 30),
                          _buildForm(),
                          const SizedBox(height: 30),
                          _buildButtons(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal, lightTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Update your information',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Profile Image with Camera Button
  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryTeal.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 70,
            backgroundColor: cardGrey,
            backgroundImage: _imageFile != null
                ? FileImage(_imageFile!)
                : (_imageUrl != null && _imageUrl!.isNotEmpty
                    ? NetworkImage(_imageUrl!) as ImageProvider
                    : null),
            child: (_imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty))
                ? Icon(Icons.person, size: 70, color: Colors.grey[400])
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryTeal, lightTeal],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryTeal.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Form with Input Fields
  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkGrey,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Full Name',
            controller: _nameController,
            icon: Icons.person_outline,
            hint: 'Enter your name',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Email Address',
            controller: _emailController,
            icon: Icons.email_outlined,
            hint: 'Enter your email',
            enabled: false,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Phone Number',
            controller: _phoneController,
            icon: Icons.phone_outlined,
            hint: 'Enter your phone',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Role',
            controller: TextEditingController(text: _role.toUpperCase()),
            icon: Icons.admin_panel_settings_outlined,
            enabled: false,
          ),
        ],
      ),
    );
  }

  /// Custom Text Field
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: darkGrey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryTeal, size: 22),
            filled: true,
            fillColor: enabled ? cardGrey : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryTeal, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  /// Action Buttons
  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              shadowColor: primaryTeal.withOpacity(0.4),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}