import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint("Login Error: $e");
      return null;
    }
  }

  // ✅ Register new user with email, password, and role
  Future<User?> registerUser(String email, String password, String role) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ Store user details in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role.toLowerCase(), // Convert role to lowercase
      });

      debugPrint("User registered: $email with role: ${role.toLowerCase()}");
      return userCredential.user;
    } catch (e) {
      debugPrint("Registration Error: $e");
      return null;
    }
  }

  // ✅ Better — uses UID (safest)
  Future<String> getUserRoleByUID(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return (userDoc.data() as Map<String, dynamic>)['role'] ?? 'voter';
      }
    } catch (e) {
      debugPrint("Error fetching role by UID: $e");
    }
    return 'voter'; // Default fallback
  }




  // ✅ Logout function
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint("User logged out successfully.");
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  // ✅ Get currently signed-in user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}