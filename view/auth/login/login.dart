
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
// import 'package:flutter_application_1/view/Doctor/DoctorDashboard.dart';
// import 'package:flutter_application_1/view/User/UserDashboard.dart';
// import 'package:flutter_application_1/view/Admin/AdminDashboard.dart';
// import 'package:flutter_application_1/view/auth/Signup/Signup.dart' hide UserRole;

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => LoginPageState();
// }

// class LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
//   bool _obscureText = true;
//   bool _isLoading = false;

//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1000),
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   /// ---------------- EMAIL LOGIN WITH BLOCK CHECK ----------------
//   Future<void> _signIn() async {
//     if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
//       _showError('Please fill all fields');
//       return;
//     }

//     setState(() => _isLoading = true);
    
//     try {
//       // 1. Authenticate with Firebase
//       UserCredential result = await _auth.signInWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );

//       User? user = result.user;

//       if (user != null) {
//         // 2. Get user document from Firestore
//         final doc = await _firestore.collection('users').doc(user.uid).get();

//         if (!doc.exists) {
//           await _auth.signOut();
//           _showError('User data not found. Please contact support.');
//           return;
//         }

//         final userData = doc.data()!;
        
//         // 3. Check if user is blocked
//         final isBlocked = userData['isBlocked'] ?? false;
//         if (isBlocked) {
//           await _auth.signOut();
//           _showError('🚫 Your account has been blocked.\nPlease contact admin for support.');
//           return;
//         }

//         // 4. Update online status
//         await _firestore.collection('users').doc(user.uid).update({
//           'online': true,
//           'lastLogin': FieldValue.serverTimestamp(),
//         });

//         // 5. Get role and navigate
//         final roleString = userData['role'];
//         final role = UserRole.values.firstWhere((e) => e.name == roleString);

//         _navigateByRole(role);
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = 'Login failed';
//       if (e.code == 'user-not-found') {
//         errorMessage = 'No user found with this email';
//       } else if (e.code == 'wrong-password') {
//         errorMessage = 'Incorrect password';
//       } else if (e.code == 'invalid-email') {
//         errorMessage = 'Invalid email format';
//       } else if (e.code == 'user-disabled') {
//         errorMessage = 'This account has been disabled';
//       } else {
//         errorMessage = e.message ?? 'Login failed';
//       }
//       _showError(errorMessage);
//     } catch (e) {
//       _showError('An error occurred: ${e.toString()}');
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   /// ---------------- GOOGLE LOGIN WITH ROLE SELECTION & BLOCK CHECK ----------------
//   Future<void> _signInWithGoogleWithRoleSelection() async {
//     // Show dialog for role selection
//     final UserRole? selectedRole = await _showRoleSelectionDialog();
    
//     if (selectedRole == null) {
//       return; // User cancelled
//     }

//     setState(() => _isLoading = true);
    
//     try {
//       final AuthService authService = AuthService();
//       final UserCredential? credential = await authService.signInWithGoogle(role: selectedRole);

//       if (credential == null || credential.user == null) {
//         _showError('Google Sign-In cancelled');
//         return;
//       }

//       final User user = credential.user!;
      
//       // Check if user is blocked
//       final doc = await _firestore.collection('users').doc(user.uid).get();
      
//       if (doc.exists) {
//         final isBlocked = doc.data()?['isBlocked'] ?? false;
//         if (isBlocked) {
//           await _auth.signOut();
//           _showError('🚫 Your account has been blocked.\nPlease contact admin for support.');
//           return;
//         }
        
//         // Update online status
//         await _firestore.collection('users').doc(user.uid).update({
//           'online': true,
//           'lastLogin': FieldValue.serverTimestamp(),
//         });
//       }
      
//       // Navigate based on selected role
//       _navigateByRole(selectedRole);
//     } catch (e) {
//       _showError('Google Sign-In failed: ${e.toString()}');
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   /// ---------------- ROLE SELECTION DIALOG ----------------
//   Future<UserRole?> _showRoleSelectionDialog() async {
//     return await showDialog<UserRole>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(20),
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   Colors.teal.shade50,
//                   Colors.blue.shade50,
//                 ],
//               ),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   Icons.account_circle,
//                   size: 60,
//                   color: Colors.teal.shade700,
//                 ),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Select Your Role',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF2C3E50),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Choose your role to continue',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 // Doctor Role Button
//                 _buildRoleButton(
//                   icon: Icons.medical_services_rounded,
//                   label: 'Sign in as Doctor',
//                   color: Colors.blue.shade700,
//                   onTap: () => Navigator.of(context).pop(UserRole.doctor),
//                 ),
//                 const SizedBox(height: 12),
//                 // User Role Button
//                 _buildRoleButton(
//                   icon: Icons.person_rounded,
//                   label: 'Sign in as User',
//                   color: Colors.green.shade700,
//                   onTap: () => Navigator.of(context).pop(UserRole.user),
//                 ),
//                 const SizedBox(height: 16),
//                 // Cancel Button
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   style: TextButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   ),
//                   child: const Text(
//                     'Cancel',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildRoleButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(14),
//         child: Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: color, width: 2),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, color: color, size: 26),
//               const SizedBox(width: 12),
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// ---------------- ROLE NAVIGATION ----------------
//   void _navigateByRole(UserRole role) {
//     if (!mounted) return;
    
//     Widget destination;
//     if (role == UserRole.admin) {
//       destination = const AdminDashboard();
//     } else if (role == UserRole.doctor) {
//       destination = const DoctorDashboardPage();
//     } else {
//       destination = UserDashboardPage();
//     }

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => destination),
//     );
//   }

//   /// ---------------- ERROR SNACKBAR ----------------
//   void _showError(String msg) {
//     if (!mounted) return;
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.error_outline, color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 msg,
//                 style: const TextStyle(fontSize: 14),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.red.shade700,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         margin: const EdgeInsets.all(16),
//         duration: const Duration(seconds: 4),
//       ),
//     );
//   }

//   /// ---------------- UI ----------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               const Color(0xFFB2DFDB),
//               const Color(0xFF80CBC4),
//               Colors.teal.shade300,
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//               child: FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // Logo with shadow
//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.white,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 20,
//                             offset: const Offset(0, 10),
//                           ),
//                         ],
//                       ),
//                       child: Image.asset(
//                         'assets/login/cow.png',
//                         width: 100,
//                         height: 100,
//                       ),
//                     ),
//                     const SizedBox(height: 30),
//                     // Welcome Text
//                     Text(
//                       'Welcome to',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.9),
//                         fontSize: 20,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'DignoVet',
//                       style: TextStyle(
//                         color: Colors.indigo[900],
//                         fontSize: 36,
//                         fontWeight: FontWeight.bold,
//                         letterSpacing: 1.2,
//                         shadows: [
//                           Shadow(
//                             color: Colors.white.withOpacity(0.5),
//                             offset: const Offset(2, 2),
//                             blurRadius: 4,
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Your trusted veterinary companion',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.8),
//                         fontSize: 14,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                     const SizedBox(height: 40),
//                     // Login Form Container
//                     Container(
//                       padding: const EdgeInsets.all(28),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(24),
//                         border: Border.all(
//                           color: Colors.teal.shade200,
//                           width: 2,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 20,
//                             offset: const Offset(0, 10),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         children: [
//                           // Email Field
//                           TextField(
//                             controller: _emailController,
//                             keyboardType: TextInputType.emailAddress,
//                             decoration: InputDecoration(
//                               prefixIcon: Icon(Icons.email_outlined, color: Colors.teal.shade600),
//                               labelText: 'Email',
//                               labelStyle: TextStyle(color: Colors.grey[700]),
//                               filled: true,
//                               fillColor: Colors.grey[50],
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(14),
//                                 borderSide: BorderSide.none,
//                               ),
//                               enabledBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(14),
//                                 borderSide: BorderSide(color: Colors.grey.shade300),
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(14),
//                                 borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 18),
//                           // Password Field
//                           TextField(
//                             controller: _passwordController,
//                             obscureText: _obscureText,
//                             decoration: InputDecoration(
//                               prefixIcon: Icon(Icons.lock_outline, color: Colors.teal.shade600),
//                               labelText: 'Password',
//                               labelStyle: TextStyle(color: Colors.grey[700]),
//                               filled: true,
//                               fillColor: Colors.grey[50],
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(14),
//                                 borderSide: BorderSide.none,
//                               ),
//                               enabledBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(14),
//                                 borderSide: BorderSide(color: Colors.grey.shade300),
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(14),
//                                 borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
//                               ),
//                               suffixIcon: IconButton(
//                                 icon: Icon(
//                                   _obscureText ? Icons.visibility_off : Icons.visibility,
//                                   color: Colors.grey[600],
//                                 ),
//                                 onPressed: () => setState(() => _obscureText = !_obscureText),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 30),
//                           // Loading or Buttons
//                           _isLoading
//                               ? Column(
//                                   children: [
//                                     CircularProgressIndicator(
//                                       color: Colors.teal.shade600,
//                                       strokeWidth: 3,
//                                     ),
//                                     const SizedBox(height: 16),
//                                     Text(
//                                       'Signing you in...',
//                                       style: TextStyle(
//                                         color: Colors.grey[600],
//                                         fontSize: 14,
//                                       ),
//                                     ),
//                                   ],
//                                 )
//                               : Column(
//                                   children: [
//                                     // Email Sign In Button
//                                     SizedBox(
//                                       width: double.infinity,
//                                       height: 54,
//                                       child: ElevatedButton(
//                                         onPressed: _signIn,
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor: Colors.teal.shade600,
//                                           foregroundColor: Colors.white,
//                                           elevation: 2,
//                                           shadowColor: Colors.teal.withOpacity(0.4),
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(14),
//                                           ),
//                                         ),
//                                         child: const Text(
//                                           'Sign In',
//                                           style: TextStyle(
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.bold,
//                                             letterSpacing: 0.5,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     const SizedBox(height: 16),
//                                     // Divider
//                                     Row(
//                                       children: [
//                                         Expanded(child: Divider(color: Colors.grey[400])),
//                                         Padding(
//                                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                                           child: Text(
//                                             'OR',
//                                             style: TextStyle(
//                                               color: Colors.grey[600],
//                                               fontWeight: FontWeight.w600,
//                                             ),
//                                           ),
//                                         ),
//                                         Expanded(child: Divider(color: Colors.grey[400])),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 16),
//                                     // Google Sign In Button
//                                     SizedBox(
//                                       width: double.infinity,
//                                       height: 54,
//                                       child: ElevatedButton(
//                                         onPressed: _signInWithGoogleWithRoleSelection,
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor: Colors.white,
//                                           foregroundColor: Colors.black87,
//                                           elevation: 2,
//                                           shadowColor: Colors.grey.withOpacity(0.3),
//                                           side: BorderSide(color: Colors.grey.shade300, width: 1.5),
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(14),
//                                           ),
//                                         ),
//                                         child: Row(
//                                           mainAxisAlignment: MainAxisAlignment.center,
//                                           children: [
//                                             Icon(Icons.g_mobiledata, size: 32, color: Colors.red[700]),
//                                             const SizedBox(width: 12),
//                                             const Text(
//                                               'Sign in with Google',
//                                               style: TextStyle(
//                                                 fontSize: 16,
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     // Sign Up Link
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             "Don't have an account? ",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 15,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           TextButton(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (_) => const SignupPage()),
//                               );
//                             },
//                             style: TextButton.styleFrom(
//                               padding: EdgeInsets.zero,
//                               minimumSize: Size.zero,
//                               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                             ),
//                             child: Text(
//                               'Sign Up',
//                               style: TextStyle(
//                                 color: Colors.indigo[900],
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.bold,
//                                 decoration: TextDecoration.underline,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:flutter_application_1/view/Doctor/DoctorDashboard.dart';
import 'package:flutter_application_1/view/Doctor/doctor_profile_page.dart';

import 'package:flutter_application_1/view/User/UserDashboard.dart';
import 'package:flutter_application_1/view/Admin/AdminDashboard.dart';
import 'package:flutter_application_1/view/auth/Signup/Signup.dart' hide UserRole;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// ---------------- EMAIL LOGIN WITH BLOCK CHECK ----------------
  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 1. Authenticate with Firebase
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = result.user;

      if (user != null) {
        // 2. Get user document from Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          await _auth.signOut();
          _showError('User data not found. Please contact support.');
          return;
        }

        final userData = doc.data()!;
        
        // 3. Check if user is blocked
        final isBlocked = userData['isBlocked'] ?? false;
        if (isBlocked) {
          await _auth.signOut();
          _showError('🚫 Your account has been blocked.\nPlease contact admin for support.');
          return;
        }

        // 4. Update online status
        await _firestore.collection('users').doc(user.uid).update({
          'online': true,
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // 5. Get role and navigate
        final roleString = userData['role'];
        final role = UserRole.values.firstWhere((e) => e.name == roleString);

        // 6. Check doctor profile completion
        if (role == UserRole.doctor) {
          final profileCompleted = userData['profileCompleted'] ?? false;
          _navigateDoctor(profileCompleted);
        } else {
          _navigateByRole(role);
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled';
      } else {
        errorMessage = e.message ?? 'Login failed';
      }
      _showError(errorMessage);
    } catch (e) {
      _showError('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ---------------- GOOGLE LOGIN WITH ROLE SELECTION & BLOCK CHECK ----------------
  Future<void> _signInWithGoogleWithRoleSelection() async {
    // Show dialog for role selection
    final UserRole? selectedRole = await _showRoleSelectionDialog();
    
    if (selectedRole == null) {
      return; // User cancelled
    }

    setState(() => _isLoading = true);
    
    try {
      final AuthService authService = AuthService();
      final UserCredential? credential = await authService.signInWithGoogle(role: selectedRole);

      if (credential == null || credential.user == null) {
        _showError('Google Sign-In cancelled');
        return;
      }

      final User user = credential.user!;
      
      // Check if user is blocked and get profile data
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        final userData = doc.data()!;
        final isBlocked = userData['isBlocked'] ?? false;
        
        if (isBlocked) {
          await _auth.signOut();
          _showError('🚫 Your account has been blocked.\nPlease contact admin for support.');
          return;
        }
        
        // Update online status
        await _firestore.collection('users').doc(user.uid).update({
          'online': true,
          'lastLogin': FieldValue.serverTimestamp(),
        });
        
        // Check doctor profile completion
        if (selectedRole == UserRole.doctor) {
          final profileCompleted = userData['profileCompleted'] ?? false;
          _navigateDoctor(profileCompleted);
        } else {
          _navigateByRole(selectedRole);
        }
      } else {
        // New user, navigate normally
        if (selectedRole == UserRole.doctor) {
          _navigateDoctor(false); // Profile not complete for new doctor
        } else {
          _navigateByRole(selectedRole);
        }
      }
    } catch (e) {
      _showError('Google Sign-In failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ---------------- ROLE SELECTION DIALOG ----------------
  Future<UserRole?> _showRoleSelectionDialog() async {
    return await showDialog<UserRole>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.teal.shade50,
                  Colors.blue.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle,
                  size: 60,
                  color: Colors.teal.shade700,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Your Role',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your role to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                // Doctor Role Button
                _buildRoleButton(
                  icon: Icons.medical_services_rounded,
                  label: 'Sign in as Doctor',
                  color: Colors.blue.shade700,
                  onTap: () => Navigator.of(context).pop(UserRole.doctor),
                ),
                const SizedBox(height: 12),
                // User Role Button
                _buildRoleButton(
                  icon: Icons.person_rounded,
                  label: 'Sign in as User',
                  color: Colors.green.shade700,
                  onTap: () => Navigator.of(context).pop(UserRole.user),
                ),
                const SizedBox(height: 16),
                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ---------------- ROLE NAVIGATION ----------------
  void _navigateByRole(UserRole role) {
    if (!mounted) return;
    
    Widget destination;
    if (role == UserRole.admin) {
      destination = const AdminDashboard();
    } else if (role == UserRole.doctor) {
      destination = const DoctorDashboardPage();
    } else {
      destination = UserDashboardPage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  /// ---------------- DOCTOR NAVIGATION WITH PROFILE CHECK ----------------
  void _navigateDoctor(bool profileCompleted) {
    if (!mounted) return;
    
    Widget destination;
    if (profileCompleted) {
      // Profile complete, go to dashboard
      destination = const DoctorDashboardPage();
    } else {
      // Profile incomplete, go to profile page to complete
      destination = const DoctorProfilePage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  /// ---------------- ERROR SNACKBAR ----------------
  void _showError(String msg) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFB2DFDB),
              const Color(0xFF80CBC4),
              Colors.teal.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with shadow
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/login/cow.png',
                        width: 100,
                        height: 100,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Welcome Text
                    Text(
                      'Welcome to',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'DignoVet',
                      style: TextStyle(
                        color: Colors.indigo[900],
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.5),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your trusted veterinary companion',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Login Form Container
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.teal.shade200,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Email Field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined, color: Colors.teal.shade600),
                              labelText: 'Email',
                              labelStyle: TextStyle(color: Colors.grey[700]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline, color: Colors.teal.shade600),
                              labelText: 'Password',
                              labelStyle: TextStyle(color: Colors.grey[700]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () => setState(() => _obscureText = !_obscureText),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Loading or Buttons
                          _isLoading
                              ? Column(
                                  children: [
                                    CircularProgressIndicator(
                                      color: Colors.teal.shade600,
                                      strokeWidth: 3,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Signing you in...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    // Email Sign In Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: _signIn,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal.shade600,
                                          foregroundColor: Colors.white,
                                          elevation: 2,
                                          shadowColor: Colors.teal.withOpacity(0.4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Divider
                                    Row(
                                      children: [
                                        Expanded(child: Divider(color: Colors.grey[400])),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            'OR',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(child: Divider(color: Colors.grey[400])),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Google Sign In Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: _signInWithGoogleWithRoleSelection,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black87,
                                          elevation: 2,
                                          shadowColor: Colors.grey.withOpacity(0.3),
                                          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.g_mobiledata, size: 32, color: Colors.red[700]),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Sign in with Google',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sign Up Link
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignupPage()),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.indigo[900],
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}