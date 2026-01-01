// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   static User? currentUser = FirebaseAuth.instance.currentUser;
//   final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

//   // Sign Up with Email & Password + Role
//   Future<User?> signUpWithEmail(String email, String password, UserRole role) async {
//     try {
//       UserCredential result = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       User? user = result.user;

//       if (user != null) {
//         // Save extra user info in Firestore
//         await _firestore.collection('users').doc(user.uid).set({
//           'email': email,
//           'role': role.name, // store enum as string
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//       }

//       return user;
//     } on FirebaseAuthException catch (e) {
//       print('Sign Up Error: ${e.message}');
//       return null;
//     } catch (e) {
//       print('Unknown Sign Up Error: $e');
//       return null;
//     }
//   }

//   // Sign In with Email & Password
//   Future<User?> signInWithEmail(String email, String password) async {
//     try {
//       UserCredential result = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return result.user;
//     } on FirebaseAuthException catch (e) {
//       print('Sign In Error: ${e.message}');
//       return null;
//     } catch (e) {
//       print('Unknown Sign In Error: $e');
//       return null;
//     }
//   }

//   // Sign In with Google (Official Firebase Implementation)
//   Future<UserCredential?> signInWithGoogle({UserRole? role}) async {
//     try {
//       // Trigger the authentication flow
//       final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

//       if (googleUser == null) {
//         // User canceled the sign-in
//         print('Google Sign In canceled by user');
//         return null;
//       }

//       // Obtain the auth details from the request
//       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

//       // Create a new credential
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.
//         idToken,
//         idToken: googleAuth.idToken,
//       );

//       // Once signed in, return the UserCredential
//       UserCredential userCredential = await _auth.signInWithCredential(credential);
//       User? user = userCredential.user;

//       if (user != null) {
//         // Check if user document already exists
//         DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

//         if (!userDoc.exists) {
//           // New user - create document with provided role or default to 'user'
//           await _firestore.collection('users').doc(user.uid).set({
//             'email': user.email,
//             'name': user.displayName,
//             'imageUrl': user.photoURL,
//             'role': role?.name ?? UserRole.user.name,
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//         } else {
//           // Existing user - optionally update their info
//           await _firestore.collection('users').doc(user.uid).update({
//             'name': user.displayName,
//             'imageUrl': user.photoURL,
//             'lastLogin': FieldValue.serverTimestamp(),
//           });
//         }
//       }

//       return userCredential;
//     } on FirebaseAuthException catch (e) {
//       print('Google Sign In Error: ${e.code} - ${e.message}');
//       return null;
//     } catch (e) {
//       print('Unknown Google Sign In Error: $e');
//       return null;
//     }
//   }

//   // Sign Out (handles both email and Google sign out)
//   Future<void> signOut() async {
//     try {
//       // Sign out from Google if the user signed in with Google

//         await _googleSignIn.signOut();
//             await _auth.signOut();
//     } catch (e) {
//       print('Sign Out Error: $e');
//     }
//   }

//   // Get current user's role
//   Future<UserRole?> getCurrentUserRole() async {
//     User? user = _auth.currentUser;
//     if (user == null) return null;

//     DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
//     if (doc.exists) {
//       String roleString = doc.get('role');
//       return UserRole.values.firstWhere((e) => e.name == roleString);
//     }
//     return null;
//   }

//   // Check if user is signed in with Google
//   Future<bool> isGoogleSignIn() async {
//     User? user = _auth.currentUser;
//     if (user == null) return false;

//     for (UserInfo userInfo in user.providerData) {
//       if (userInfo.providerId == 'google.com') {
//         return true;
//       }
//     }
//     return false;
//   }

//   // Stream to listen to auth state changes
//   Stream<User?> get authStateChanges => _auth.authStateChanges();

//   // Get current authenticated user
//   User? get currentAuthUser => _auth.currentUser;
// }

// enum UserRole {
//   admin,
//   doctor,
//   user,
// }

// class AuthGoogleService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   static User? currentUser = FirebaseAuth.instance.currentUser;

//   // 🔹 GOOGLE SIGN IN
//   Future<User?> signInWithGoogle({UserRole role = UserRole.user}) async {
//     try {
//       final GoogleSignInAccount? googleUser =
//           await _googleSignIn.();

//       if (googleUser == null) {
//         return null; // user canceled
//       }

//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.idToken,
//         idToken: googleAuth.idToken,
//       );

//       UserCredential result =
//           await _auth.signInWithCredential(credential);

//       User? user = result.user;

//       if (user != null) {
//         final docRef = _firestore.collection('users').doc(user.uid);
//         final doc = await docRef.get();

//         // 🔹 Firestore me user pehli baar login par add hoga
//         if (!doc.exists) {
//           await docRef.set({
//             'email': user.email,
//             'name': user.displayName,
//             'imageUrl': user.photoURL,
//             'role': role.name,
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//         }
//       }

//       return user;
//     } catch (e) {
//       print('Google Sign-In Error: $e');
//       return null;
//     }
//   }

//   // 🔹 SIGN OUT
//   Future<void> signOut() async {
//     await _googleSignIn.signOut();
//     await _auth.signOut();
//   }

//   // 🔹 GET ROLE
//   Future<UserRole?> getCurrentUserRole() async {
//     User? user = _auth.currentUser;
//     if (user == null) return null;

//     DocumentSnapshot doc =
//         await _firestore.collection('users').doc(user.uid).get();

//     if (doc.exists) {
//       String roleString = doc.get('role');
//       return UserRole.values.firstWhere(
//         (e) => e.name == roleString,
//       );
//     }
//     return null;
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Always read the latest signed-in user; avoids stale user after logout/login.
  static User? get currentUser => FirebaseAuth.instance.currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // Sign Up with Email & Password + Role
  Future<User?> signUpWithEmail(
    String email,
    String password,
    UserRole role,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Save extra user info in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'role': role.name, // store enum as string
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('Sign Up Error: ${e.message}');
      throw e; // Re-throw to handle in UI
    } catch (e) {
      print('Unknown Sign Up Error: $e');
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign In with Email & Password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      if (result.user != null) {
        await _updateLastLogin(result.user!.uid);
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Sign In Error: ${e.message}');
      throw e; // Re-throw to handle in UI
    } catch (e) {
      print('Unknown Sign In Error: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  // Alternative Google Sign In method (Simpler)
  Future<User?> signInWithGoogleSimpler({UserRole? role}) async {
    try {
      // Check if already signed in with Google
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Get authentication details
      final googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _handleGoogleUserData(user, role);
      }

      return user;
    } catch (e) {
      print('Google Sign In Error: $e');
      throw Exception('Google sign in failed: $e');
    }
  }

  // Sign In with Google (Official Firebase Implementation)
  Future<UserCredential?> signInWithGoogle({UserRole? role}) async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        print('Google Sign In canceled by user');
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user != null) {
        await _handleGoogleUserData(user, role);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Google Sign In Error: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('Unknown Google Sign In Error: $e');
      throw Exception('Google sign in failed: $e');
    }
  }

  // Helper method to handle Google user data
  Future<void> _handleGoogleUserData(User user, UserRole? role) async {
    // Check if user document already exists
    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      // New user - create document with provided role or default to 'user'
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName,
        'imageUrl': user.photoURL,
        'role': role?.name ?? UserRole.user.name,
        'provider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      // Existing user - update their info
      await _firestore.collection('users').doc(user.uid).update({
        'name': user.displayName,
        'imageUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  // Helper method to update last login
  Future<void> _updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // Sign Out (handles both email and Google sign out)
  Future<void> signOut() async {
    try {
      // Check if user signed in with Google
      if (await isGoogleSignIn()) {
        await _googleSignIn.signOut();
      }

      await _auth.signOut();
    } catch (e) {
      print('Sign Out Error: $e');
      throw Exception('Sign out failed: $e');
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  // Get current user's role
  Future<UserRole?> getCurrentUserRole() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('role')) {
          String roleString = data['role'];
          return UserRole.values.firstWhere(
            (e) => e.name == roleString,
            orElse: () => UserRole.user,
          );
        }
      }
      return UserRole.user; // Default role
    } catch (e) {
      print('Error getting user role: $e');
      return UserRole.user; // Default role on error
    }
  }

  // Check if user is signed in with Google
  Future<bool> isGoogleSignIn() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    for (UserInfo userInfo in user.providerData) {
      if (userInfo.providerId == 'google.com') {
        return true;
      }
    }
    return false;
  }

  // Get current user data from Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Stream to listen to user document changes
  Stream<DocumentSnapshot> userDocumentStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // Get current authenticated user
  User? get currentAuthUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Password reset error: ${e.message}');
      throw e;
    } catch (e) {
      print('Unknown password reset error: $e');
      throw Exception('Password reset failed: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      // Update in Firebase Auth
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);

      // Update in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        if (displayName != null) 'name': displayName,
        if (photoURL != null) 'imageUrl': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Profile update error: $e');
      throw Exception('Profile update failed: $e');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete from Firebase Auth
      await user.delete();

      // Sign out from Google if applicable
      if (await isGoogleSignIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      print('Account deletion error: $e');
      throw Exception('Account deletion failed: $e');
    }
  }
}

enum UserRole { admin, doctor, user }
