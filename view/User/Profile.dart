// import 'dart:developer';
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
// import 'package:flutter_application_1/view/auth/login/login.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class EditProfilePage extends StatefulWidget {
//   const EditProfilePage({super.key});

//   @override
//   State<EditProfilePage> createState() => _EditProfilePageState();
// }

// class _EditProfilePageState extends State<EditProfilePage> {
//   // --- Colors ---
//   final Color primaryTeal = const Color(0xFFB2DFDB);
//   final Color darkTeal = const Color(0xFF00796B);
//   final Color accentTeal = const Color(0xFF80CBC4);

//   // --- Controllers ---
//   final _name = TextEditingController();
//   final _email = TextEditingController();
//   final _phone = TextEditingController();

//   // --- Image & Loading ---
//   File? _imageFile;
//   bool _loading = true;
//   bool _saving = false;

//   // --- Firebase & Supabase ---
//   final _auth = FirebaseAuth.instance;
//   final _firestore = FirebaseFirestore.instance;
//   final _picker = ImagePicker();
//   final _supabase = Supabase.instance.client;
//   String? _imageUrl;

//   String _role = 'user'; // default role
//   String get _uid => _auth.currentUser!.uid;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   /// 🔥 LOAD LOGGED-IN USER DATA
//   Future<void> _loadUserData() async {
//     log('Loading user data for $_uid');
//     try {
//       final doc = await _firestore.collection('users').doc(_uid).get();

//       if (doc.exists) {
//         _name.text = doc['name'] ?? '';
//         _email.text = doc['email'] ?? _auth.currentUser!.email ?? '';
//         _phone.text = doc['phone'] ?? '';
//         _role = doc['role'] ?? 'user';
//         if (doc['imageUrl'] != null && doc['imageUrl'].toString().isNotEmpty) {
//           _imageUrl = doc['imageUrl'];
//           log('Existing image found: $_imageUrl');
//         }
//       } else {
//         _email.text = _auth.currentUser!.email ?? '';
//       }
//     } catch (e) {
//       log('Load User Error: $e');
//     }

//     setState(() => _loading = false);
//   }

//   /// 🖼 PICK IMAGE (LOCAL PREVIEW)
//   Future<void> _pickImage() async {
//     try {
//       final picked = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//       );
//       if (picked != null) {
//         setState(() => _imageFile = File(picked.path));
//         log('Image selected: ${picked.path}');
//       }
//     } catch (e) {
//       log('Pick Image Error: $e');
//     }
//   }

//   /// 💾 SAVE PROFILE + UPLOAD IMAGE TO SUPABASE
//   Future<void> _saveProfile() async {
//     if (_name.text.isEmpty || _phone.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("All fields are required")),
//       );
//       return;
//     }

//     setState(() => _saving = true);
//     log('Saving profile for user $_uid with role $_role');

//     String? imageUrl;

//     try {
//       // 1️⃣ Upload image to Supabase Storage if selected
//       if (_imageFile != null) {
//         final folder = _role.toLowerCase(); // admin/doctor/user
//         final path = '$folder/$_uid/${DateTime.now().millisecondsSinceEpoch}.png';
//         log('Uploading image to Supabase path: $path');

//         final response = await _supabase.storage
//             .from('images')
//             .upload(path, _imageFile!, fileOptions: const FileOptions(cacheControl: '3600', upsert: true));

//         if (response != null) {
//           _imageUrl = _supabase.storage.from('images').getPublicUrl(path);
//           log(_imageUrl.runtimeType.toString()); // should print: String

//           log('Image uploaded successfully. URL: $imageUrl');
//         }
//       }

//       // 2️⃣ Update Firestore user document
//       final data = {
//         'name': _name.text.trim(),
//         'email': _email.text.trim(),
//         'phone': _phone.text.trim(),
//         'role': _role,
//         'updatedAt': FieldValue.serverTimestamp(),
//       };
//       if (imageUrl != null) data['imageUrl'] = imageUrl;

//       await _firestore.collection('users').doc(_uid).set(data, SetOptions(merge: true));
//       log('User profile updated in Firestore');

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Profile updated successfully ✅")),
//       );
//     } catch (e) {
//       log('Save Profile Error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Failed to update profile")),
//       );
//     }

//     setState(() => _saving = false);
//   }

//   /// 🚪 LOGOUT
//   Future<void> _logout() async {
//     try {
//       log('Logging out user $_uid');
//       await AuthService().signOut();

//       if (mounted) {
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) => const LoginPage()),
//           (_) => false,
//         );
//       }
//     } catch (e) {
//       log('Logout Error: $e');
//     }
//   }

//   /// --- BUILD UI ---
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: primaryTeal,
//       appBar: _buildAppBar(),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator(color: Colors.white))
//           : SingleChildScrollView(
//               child: Column(
//                 children: [
//                   const SizedBox(height: 20),
//                   _profileImage(),
//                   const SizedBox(height: 30),
//                   _form(),
//                   const SizedBox(height: 40),
//                   _buttons(),
//                   if (_saving)
//                     const Padding(
//                       padding: EdgeInsets.all(20),
//                       child: LinearProgressIndicator(color: Colors.teal),
//                     ),
//                 ],
//               ),
//             ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() => AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text('Edit Profile',
//             style: TextStyle(color: Colors.white, fontSize: 24)),
//         centerTitle: true,
//       );

//  Widget _profileImage() => Stack(
//   children: [
//     CircleAvatar(
//       radius: 70,
//       backgroundColor: Colors.grey.shade300,
//       backgroundImage: _imageFile != null
//           ? FileImage(_imageFile!)
//           : (_imageUrl != null ? NetworkImage(_imageUrl!) : null),
//       child: (_imageFile == null && _imageUrl == null)
//           ? const Icon(Icons.person, size: 70, color: Colors.white)
//           : null,
//     ),
//     Positioned(
//       bottom: 0,
//       right: 0,
//       child: GestureDetector(
//         onTap: _pickImage,
//         child: CircleAvatar(
//           backgroundColor: darkTeal,
//           child: const Icon(Icons.camera_alt, color: Colors.white),
//         ),
//       ),
//     )
//   ],
// );

//   Widget _form() => Container(
//         margin: const EdgeInsets.symmetric(horizontal: 24),
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(32),
//         ),
//         child: Column(
//           children: [
//             _field("Name", _name, Icons.person),
//             const SizedBox(height: 20),
//             _field("Email", _email, Icons.email, enabled: false),
//             const SizedBox(height: 20),
//             _field("Phone", _phone, Icons.phone),
//             const SizedBox(height: 20),
//             _roleField(),
//           ],
//         ),
//       );

//   Widget _field(String label, TextEditingController c, IconData i,
//           {bool enabled = true}) =>
//       TextField(
//         controller: c,
//         enabled: enabled,
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(i, color: accentTeal),
//           filled: true,
//           fillColor: primaryTeal.withOpacity(0.1),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       );

//   Widget _roleField() => TextField(
//         controller: TextEditingController(text: _role),
//         enabled: false,
//         decoration: InputDecoration(
//           labelText: "Role",
//           prefixIcon: Icon(Icons.admin_panel_settings, color: accentTeal),
//           filled: true,
//           fillColor: primaryTeal.withOpacity(0.1),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       );

//   Widget _buttons() => Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24),
//         child: Column(
//           children: [
//             ElevatedButton(
//               onPressed: _saveProfile,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 foregroundColor: darkTeal,
//                 minimumSize: const Size(double.infinity, 60),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20)),
//               ),
//               child: const Text("Save Changes",
//                   style: TextStyle(fontSize: 18)),
//             ),
//             const SizedBox(height: 20),
//             TextButton.icon(
//               onPressed: _logout,
//               icon: const Icon(Icons.logout, color: Colors.white),
//               label: const Text("Logout",
//                   style: TextStyle(color: Colors.white)),
//             )
//           ],
//         ),
//       );
// }


import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/auth/login/login.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import '../../../services/firebase_authentication/auth_api.dart';


class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // --- Professional Theme Colors ---
  final Color darkTeal = const Color(0xFF00796B);
  final Color mediumTeal = const Color(0xFF4DB6AC);
  final Color lightTeal = const Color(0xFF80CBC4);

  // --- Controllers ---
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  // --- State Variables ---
  File? _imageFile;
  bool _loading = true;
  bool _saving = false;
  String? _imageUrl;
  String _role = 'user';

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  String get _uid => _auth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      if (doc.exists) {
        setState(() {
          _name.text = doc['name'] ?? '';
          _email.text = doc['email'] ?? _auth.currentUser!.email ?? '';
          _phone.text = doc['phone'] ?? '';
          _role = doc['role'] ?? 'user';
          _imageUrl = doc['imageUrl'];
          _loading = false;
        });
      }
    } catch (e) {
      log('Load User Error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      _showSnackBar("Please fill all fields", Colors.orange);
      return;
    }

    setState(() => _saving = true);

    try {
      String? finalImageUrl = _imageUrl;

      // 1. Image Upload logic to Supabase
      if (_imageFile != null) {
        final path = 'profiles/$_uid/${DateTime.now().millisecondsSinceEpoch}.png';
        await _supabase.storage.from('images').upload(path, _imageFile!, 
            fileOptions: const FileOptions(upsert: true));
        finalImageUrl = _supabase.storage.from('images').getPublicUrl(path);
      }

      // 2. Update Firestore
      await _firestore.collection('users').doc(_uid).set({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'imageUrl': finalImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showSnackBar("Profile Updated Successfully! 🎉", darkTeal);
    } catch (e) {
      _showSnackBar("Update Failed: $e", Colors.red);
    } finally {
      setState(() => _saving = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkTeal, mediumTeal, lightTeal],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(languageProvider),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _loading 
                    ? Center(child: CircularProgressIndicator(color: darkTeal))
                    : _buildForm(languageProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(LanguageProvider languageProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          Expanded(
            child: Text(
              languageProvider.t('My Profile', 'میری پروفائل'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 40), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildForm(LanguageProvider languageProvider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProfileImagePicker(),
          const SizedBox(height: 32),
          _buildSectionHeader(languageProvider.t("Personal Details", "ذاتی تفصیلات"), Icons.person_outline),
          const SizedBox(height: 16),
          _buildTextField(controller: _name, label: languageProvider.t("Full Name", "مکمل نام"), icon: Icons.person),
          const SizedBox(height: 16),
          _buildTextField(controller: _email, label: languageProvider.t("Email Address", "ای میل ایڈریس"), icon: Icons.email, enabled: false),
          const SizedBox(height: 16),
          _buildTextField(controller: _phone, label: languageProvider.t("Phone Number", "فون نمبر"), icon: Icons.phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildTextField(controller: TextEditingController(text: _role.toUpperCase()), label: languageProvider.t("Account Role", "اکاؤنٹ کا کردار"), icon: Icons.security, enabled: false),
          const SizedBox(height: 40),
          _buildSaveButton(languageProvider),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: Text(languageProvider.t("Sign Out", "سائن آؤٹ"), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: darkTeal, width: 2)),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: _imageFile != null
                ? FileImage(_imageFile!)
                : (_imageUrl != null ? NetworkImage(_imageUrl!) : null) as ImageProvider?,
            child: (_imageFile == null && _imageUrl == null)
                ? Icon(Icons.person, size: 60, color: darkTeal)
                : null,
          ),
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: darkTeal, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            child: const Icon(Icons.edit, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: darkTeal, size: 22),
        labelText: label,
        filled: true,
        fillColor: enabled ? const Color(0xFFF5F5F5) : Colors.grey[100],
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkTeal, width: 2),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: darkTeal, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
      ],
    );
  }

  Widget _buildSaveButton(LanguageProvider languageProvider) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [darkTeal, mediumTeal]),
        boxShadow: [BoxShadow(color: darkTeal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: _saving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _saving
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(languageProvider.t("Update Profile", "پروفائل اپ ڈیٹ کریں"), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
     await AuthService().signOut();
     Navigator.pushAndRemoveUntil(
       context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
  }
}