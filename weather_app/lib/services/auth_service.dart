import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  User? get currentUser => _user ?? _auth?.currentUser;
  bool get isAuthenticated => currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isConfigured => _initialized; // New getter

  AuthService() {
    _tryInitialize();
  }

  void _tryInitialize() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _auth = FirebaseAuth.instance;
        _firestore = FirebaseFirestore.instance;
        _initialized = true;
        
        // Listen to auth state changes
        _auth?.authStateChanges().listen((User? user) {
          _user = user;
          notifyListeners();
        });
      }
    } catch (e) {
      print("Firebase not initialized in AuthService: $e");
    }
  }

  // Check if Firebase is initialized. Returns false if not.
  bool _checkInitialized() {
    if (!_initialized) {
      _tryInitialize();
    }
    // If still not initialized, we will fallback to demo mode logic in the caller
    return _initialized; 
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    // Demo Mode Fallback
    if (!_checkInitialized()) {
      print("⚠️ Firebase not initialized. Performing Demo SignUp.");
      _isLoading = true;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      _isLoading = false;
      notifyListeners();
      return true; // Pretend it worked
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Create user account
      final UserCredential userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create user profile in Firestore
      await _firestore!.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'isPremium': false,
        'mode': 'general',
        'location': 'Dhaka, Bangladesh',
      });

      _user = userCredential.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    // Demo Mode Fallback
    if (!_checkInitialized()) {
      print("⚠️ Firebase not initialized. Performing Demo Login.");
      _isLoading = true;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      _isLoading = false;
      notifyListeners();
      return true; // Pretend it worked
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final UserCredential userCredential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    // Demo Mode Cleanup
    if (!_checkInitialized()) {
      _user = null;
      notifyListeners();
      return; 
    }
    
    // Real Logout
    if (_auth == null) return;
    try {
      await GoogleSignIn().signOut();
      await _auth!.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  /// Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null || _firestore == null) return null;

    try {
      final doc = await _firestore!.collection('users').doc(currentUser!.uid).get();
      return doc.data();
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Update user profile data
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (currentUser == null || _firestore == null) return;

    try {
      await _firestore!.collection('users').doc(currentUser!.uid).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  /// Check if user is logged in (for auto-login)
  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    // Wait a bit to check Firebase auth state
    await Future.delayed(const Duration(milliseconds: 500));

    // Try to ensure initialization
    _tryInitialize();
    
    if (_auth != null) {
      _user = _auth!.currentUser;
    }
    
    _isLoading = false;
    notifyListeners();

    return isAuthenticated;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get user-friendly error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
