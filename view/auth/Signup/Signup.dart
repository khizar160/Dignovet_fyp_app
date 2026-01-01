// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/view/auth/login/login.dart';
// import 'package:flutter_application_1/view/Doctor/DoctorDashboard.dart';
// import 'package:flutter_application_1/view/User/UserDashboard.dart';
// import 'package:flutter_application_1/view/Admin/AdminDashboard.dart';
// enum UserRole {
//   admin,
//   doctor,
//   user,
// }


// class SignupPage extends StatefulWidget {
//   const SignupPage({super.key});

//   @override
//   SignupPageState createState() => SignupPageState();
// }
// class SignupPageState extends State<SignupPage> {
//   final _formKey = GlobalKey<FormState>();
//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   bool _agreeToTerms = false;
//   bool _isDoctor = false;

//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   bool _isLoading = false;

//   void _signUp() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (_passwordController.text != _confirmPasswordController.text) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Passwords do not match')),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       // Create user in Firebase Auth
//       UserCredential result = await _auth.createUserWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );

//       User? user = result.user;

//       if (user != null) {
//         // Determine role
//         UserRole role = _isDoctor ? UserRole.doctor : UserRole.user;

//         // Save user info in Firestore
//         await _firestore.collection('users').doc(user.uid).set({
//           'uid': user.uid,
//           'name': _nameController.text.trim(),
//           'email': _emailController.text.trim(),
//           'phone': _phoneController.text.trim(),
//           'role': role.name,
//           'createdAt': FieldValue.serverTimestamp(),
//         });

//         // Navigate based on role
//         if (role == UserRole.doctor) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const DoctorDashboardPage()),
//           );
//         } else if (role == UserRole.admin) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const AdminDashboard()),
//           );
//         } else {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) =>  UserDashboardPage()),
//           );
//         }
//       }
//     } on FirebaseAuthException catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(e.message ?? 'Signup failed')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFB2DFDB),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const SizedBox(height: 20),
//                 Text(
//                   'Welcome to Diagnovet',
//                   style: TextStyle(
//                     color: Colors.indigo[900],
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 40),
//                 Container(
//                   width: MediaQuery.of(context).size.width * 0.9,
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: Colors.blue[300]!, width: 2),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 8,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         Text(
//                           'Sign Up',
//                           style: TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.teal[800],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 24),

//                         // Full Name
//                         TextFormField(
//                           controller: _nameController,
//                           decoration: InputDecoration(
//                             prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
//                             labelText: 'Full Name',
//                             filled: true,
//                             fillColor: Colors.grey[100],
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                           validator: (value) =>
//                               value == null || value.isEmpty ? 'Please enter your full name' : null,
//                         ),
//                         const SizedBox(height: 16),

//                         // Email
//                         TextFormField(
//                           controller: _emailController,
//                           keyboardType: TextInputType.emailAddress,
//                           decoration: InputDecoration(
//                             prefixIcon: Icon(Icons.mail_outline, color: Colors.grey[600]),
//                             labelText: 'Email',
//                             filled: true,
//                             fillColor: Colors.grey[100],
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) return 'Please enter your email';
//                             if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//                               return 'Please enter a valid email';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 16),

//                         // Phone
//                         TextFormField(
//                           controller: _phoneController,
//                           keyboardType: TextInputType.phone,
//                           decoration: InputDecoration(
//                             prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[600]),
//                             labelText: 'Phone Number',
//                             filled: true,
//                             fillColor: Colors.grey[100],
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                           validator: (value) =>
//                               value == null || value.isEmpty ? 'Please enter your phone number' : null,
//                         ),
//                         const SizedBox(height: 16),

//                         // Password
//                         TextFormField(
//                           controller: _passwordController,
//                           obscureText: _obscurePassword,
//                           decoration: InputDecoration(
//                             prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
//                             labelText: 'Password',
//                             filled: true,
//                             fillColor: Colors.grey[100],
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide.none,
//                             ),
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                 _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                                 color: Colors.grey[600],
//                               ),
//                               onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                             ),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) return 'Please enter a password';
//                             if (value.length < 6) return 'Password must be at least 6 characters';
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 16),

//                         // Confirm Password
//                         TextFormField(
//                           controller: _confirmPasswordController,
//                           obscureText: _obscureConfirmPassword,
//                           decoration: InputDecoration(
//                             prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
//                             labelText: 'Confirm Password',
//                             filled: true,
//                             fillColor: Colors.grey[100],
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide.none,
//                             ),
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                 _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
//                                 color: Colors.grey[600],
//                               ),
//                               onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
//                             ),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) return 'Please confirm your password';
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 20),

//                         // Terms & Role Checkbox
//                         Column(
//                           children: [
//                             Row(
//                               children: [
//                                 Checkbox(
//                                   value: _agreeToTerms,
//                                   onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
//                                   activeColor: const Color(0xFF80CBC4),
//                                 ),
//                                 const Text('I agree to Terms & Conditions', style: TextStyle(fontSize: 14)),
//                               ],
//                             ),
//                             Row(
//                               children: [
//                                 Checkbox(
//                                   value: _isDoctor,
//                                   onChanged: (val) => setState(() => _isDoctor = val ?? false),
//                                   activeColor: const Color(0xFF80CBC4),
//                                 ),
//                                 const Text('Sign up as Doctor', style: TextStyle(fontSize: 14)),
//                               ],
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 24),

//                         // Signup Button
//                         _isLoading
//                             ? const Center(child: CircularProgressIndicator())
//                             : ElevatedButton(
//                                 onPressed: _agreeToTerms ? _signUp : null,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF80CBC4),
//                                   disabledBackgroundColor: Colors.grey[400],
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(30),
//                                   ),
//                                   padding: const EdgeInsets.symmetric(vertical: 16),
//                                 ),
//                                 child: const Text(
//                                   'Sign Up',
//                                   style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Sign In link
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text('Already have an account? '),
//                     InkWell(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => const LoginPage()),
//                         );
//                       },
//                       child: Text(
//                         'Sign In',
//                         style: TextStyle(
//                           color: Colors.blue[700],
//                           fontWeight: FontWeight.bold,
//                           decoration: TextDecoration.underline,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//               ],
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
import 'package:flutter_application_1/view/auth/login/login.dart';
import 'package:flutter_application_1/view/Doctor/DoctorDashboard.dart';
import 'package:flutter_application_1/view/User/UserDashboard.dart';
import 'package:flutter_application_1/view/Admin/AdminDashboard.dart';

enum UserRole {
  admin,
  doctor,
  user,
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  SignupPageState createState() => SignupPageState();
}

class SignupPageState extends State<SignupPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isDoctor = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = result.user;

      if (user != null) {
        UserRole role = _isDoctor ? UserRole.doctor : UserRole.user;

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': role.name,
          'isBlocked': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showSnackBar('Account created successfully!', const Color(0xFF00796B));

        await Future.delayed(const Duration(milliseconds: 500));

        if (role == UserRole.doctor) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DoctorDashboardPage()),
          );
        } else if (role == UserRole.admin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => UserDashboardPage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for this email';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      _showSnackBar(message, Colors.red);
    } catch (e) {
      _showSnackBar('An error occurred. Please try again', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.red ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00796B),
              const Color(0xFF4DB6AC),
              const Color(0xFF80CBC4),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildSignupCard(),
                    const SizedBox(height: 24),
                    _buildSignInLink(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.pets,
            size: 50,
            color: Color(0xFF00796B),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Welcome to DignoVet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Create your account to get started',
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignupCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in your details below',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _buildTextField(
              controller: _nameController,
              icon: Icons.person_outline_rounded,
              label: 'Full Name',
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter your full name' : null,
            ),
            const SizedBox(height: 18),
            _buildTextField(
              controller: _emailController,
              icon: Icons.mail_outline_rounded,
              label: 'Email Address',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your email';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildTextField(
              controller: _phoneController,
              icon: Icons.phone_outlined,
              label: 'Phone Number',
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter your phone number' : null,
            ),
            const SizedBox(height: 18),
            _buildPasswordField(
              controller: _passwordController,
              label: 'Password',
              obscureText: _obscurePassword,
              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter a password';
                if (value.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              obscureText: _obscureConfirmPassword,
              onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please confirm your password';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildCheckboxes(),
            const SizedBox(height: 28),
            _buildSignUpButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          child: Icon(icon, color: const Color(0xFF00796B), size: 22),
        ),
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF00796B), size: 22),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey[600],
            size: 22,
          ),
          onPressed: onToggle,
        ),
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildCheckboxes() {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: _agreeToTerms ? const Color(0xFF00796B).withOpacity(0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _agreeToTerms ? const Color(0xFF00796B) : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _agreeToTerms ? const Color(0xFF00796B) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _agreeToTerms ? const Color(0xFF00796B) : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: _agreeToTerms
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'I agree to Terms & Conditions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => setState(() => _isDoctor = !_isDoctor),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: _isDoctor ? const Color(0xFF00796B).withOpacity(0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDoctor ? const Color(0xFF00796B) : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _isDoctor ? const Color(0xFF00796B) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isDoctor ? const Color(0xFF00796B) : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: _isDoctor
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Sign up as a Doctor',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00796B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    size: 18,
                    color: Color(0xFF00796B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _agreeToTerms
            ? const LinearGradient(
                colors: [Color(0xFF00796B), Color(0xFF4DB6AC)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: _agreeToTerms ? null : Colors.grey[300],
        boxShadow: _agreeToTerms
            ? [
                BoxShadow(
                  color: const Color(0xFF00796B).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: _agreeToTerms && !_isLoading ? _signUp : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Already have an account? ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  color: Color(0xFF00796B),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}