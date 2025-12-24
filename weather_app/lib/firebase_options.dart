// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        // Use Web options for Windows Desktop (Standard for signInWithProvider)
        return web;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDgTfh97X9p1mTlLa6b3BYGOxOk5K6D-Ug', // Corrected Web Key
    appId: '1:669799446176:web:652b32d65df0108eca3bc5', // Updated from User Input
    messagingSenderId: '669799446176',
    projectId: 'sira-weather-forcasting-app',
    authDomain: 'sira-weather-forcasting-app.firebaseapp.com',
    storageBucket: 'sira-weather-forcasting-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDxfvFMuPcvb7UAUKSa9zIlbd1DZ5yZSLU', // Reverted to correct Android Key
    appId: '1:669799446176:android:2a98c4665d8a1873ca3bc5',
    messagingSenderId: '669799446176',
    projectId: 'sira-weather-forcasting-app',
    storageBucket: 'sira-weather-forcasting-app.firebasestorage.app',
  );
}
