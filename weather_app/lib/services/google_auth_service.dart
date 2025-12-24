import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      GoogleSignIn googleSignIn;

      if (kIsWeb) {
        // Web: requires clientId
        googleSignIn = GoogleSignIn(
          clientId: '669799446176-j1huep63hd7t1e7kcpb0pcruc037s588.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Desktop: MUST have explicit clientId
        print("Initializing Desktop Google Sign In...");
        googleSignIn = GoogleSignIn(
          clientId: '669799446176-j1huep63hd7t1e7kcpb0pcruc037s588.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );
      } else {
        // Mobile (Android/iOS): Uses google-services.json / GoogleService-Info.plist
        print("Initializing Mobile Google Sign In...");
        googleSignIn = GoogleSignIn();
      }

      // Trigger the sign-in flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print("Google Sign In was aborted by user.");
        return null;
      }

      print("Google User found: ${googleUser.email}");

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      return await _auth.signInWithCredential(credential);

    } catch (e) {
      print("Google Sign-In error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Create a specific instance for sign out to match sign in config if possible, 
      // or just use default. GoogleSignIn().signOut() usually works globally.
      await GoogleSignIn().signOut();
    } catch (e) {
      print("Error signing out from Google: $e");
    }

    if (Firebase.apps.isNotEmpty) {
      await _auth.signOut();
    }
  }
}
