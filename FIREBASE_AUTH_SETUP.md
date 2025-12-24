# Firebase Authentication Setup Guide

**Status:** ✅ Code Complete - Firebase Configuration Needed  
**Date:** 2025-12-24  
**Feature:** Persistent Login with Firebase Auth

---

## 🎯 WHAT WAS IMPLEMENTED

### 1. **Firebase Authentication Service** ✅
**File:** `lib/services/auth_service.dart`

**Features:**
- Email/Password signup
- Email/Password login
- Automatic session persistence
- User profile storage in Firestore
- Error handling with user-friendly messages
- Auth state change listener

### 2. **Auth Gate Widget** ✅
**File:** `lib/auth_gate.dart`

**Features:**
- Automatic login check on app start
- Loading screen while checking auth status
- Redirect to home if authenticated
- Redirect to login if not authenticated

### 3. **Main App Integration** ✅
**File:** `lib/main.dart`

**Changes:**
- Firebase initialization
- AuthService provider added
- Splash screen + auth check flow
- Persistent login implementation

### 4. **Dependencies Added** ✅
**File:** `pubspec.yaml`

```yaml
firebase_core: ^3.15.2
firebase_auth: ^5.7.0
cloud_firestore: ^5.6.12
```

---

## 🔧 FIREBASE CONFIGURATION REQUIRED

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "Bangladesh Weather App"
4. Disable Google Analytics (optional)
5. Click "Create project"

### Step 2: Add Android App

1. In Firebase Console, click "Add app" → Android
2. **Android package name:** `com.example.weather_app`
   - Find this in `android/app/build.gradle` under `applicationId`
3. **App nickname:** Weather BD
4. Click "Register app"
5. **Download `google-services.json`**
6. Place it in: `android/app/google-services.json`

### Step 3: Update Android Configuration

#### File: `android/build.gradle`
Add this to dependencies section:
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### File: `android/app/build.gradle`
Add at the bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

Also ensure `minSdkVersion` is at least 21:
```gradle
defaultConfig {
    minSdkVersion 21  // Change from 16 if needed
}
```

### Step 4: Enable Authentication in Firebase

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Click "Sign-in method" tab
4. Enable "Email/Password"
5. Click "Save"

### Step 5: Create Firestore Database

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Select "Start in test mode" (for development)
4. Choose location: `asia-south1` (India - closest to Bangladesh)
5. Click "Enable"

### Step 6: Set Firestore Security Rules

In Firestore → Rules tab, use these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 📱 HOW IT WORKS

### User Flow

```
App Start
    ↓
Splash Screen (2 seconds)
    ↓
Check Firebase Auth Status
    ↓
    ├─→ User Logged In? → Main App (Home Screen)
    └─→ Not Logged In? → Login Screen
```

### Signup Flow

```
User enters email + password + name
    ↓
AuthService.signUp()
    ↓
Firebase creates account
    ↓
User profile saved to Firestore
    ↓
Auto-login → Main App
```

### Login Flow

```
User enters email + password
    ↓
AuthService.signIn()
    ↓
Firebase verifies credentials
    ↓
Session saved locally (automatic)
    ↓
Redirect to Main App
```

### Persistent Login

```
User closes app
    ↓
User reopens app
    ↓
Splash Screen
    ↓
AuthService.checkAuthStatus()
    ↓
Firebase.currentUser exists?
    ↓
YES → Auto-login → Main App ✅
NO → Login Screen
```

---

## 🔐 SECURITY FEATURES

### What's Secure ✅

1. **Passwords Never Stored Locally**
   - Firebase handles all password hashing
   - Passwords never touch your device storage

2. **Secure Session Tokens**
   - Firebase uses encrypted tokens
   - Tokens auto-refresh
   - Tokens stored securely by Firebase SDK

3. **User Data Protection**
   - Firestore rules prevent unauthorized access
   - Users can only read/write their own data

4. **Email Verification** (Optional - can be added)
   ```dart
   await user.sendEmailVerification();
   ```

---

## 🧪 TESTING CHECKLIST

### Before Firebase Configuration
- [x] Code implemented
- [x] Dependencies added
- [x] AuthService created
- [x] AuthGate created
- [x] Main.dart updated

### After Firebase Configuration
- [ ] `google-services.json` added
- [ ] Android build.gradle updated
- [ ] Firebase Auth enabled
- [ ] Firestore database created
- [ ] Security rules set

### Testing Scenarios
- [ ] **Signup:** Create new account
- [ ] **Login:** Sign in with existing account
- [ ] **Persistent Login:** Close app, reopen → should auto-login
- [ ] **Logout:** Sign out → should go to login screen
- [ ] **Wrong Password:** Should show error message
- [ ] **Existing Email:** Should show "email already in use"

---

## 🚀 NEXT STEPS (In Order)

### 1. Configure Firebase (15 minutes)
- Create Firebase project
- Add Android app
- Download `google-services.json`
- Update build.gradle files
- Enable Authentication
- Create Firestore database

### 2. Update Login Screen (5 minutes)
Connect login screen to AuthService:
```dart
final authService = Provider.of<AuthService>(context);

// On login button press
final success = await authService.signIn(
  email: emailController.text,
  password: passwordController.text,
);

if (success) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => MainWrapper()),
  );
} else {
  // Show error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(authService.errorMessage ?? 'Login failed')),
  );
}
```

### 3. Update Signup Screen (5 minutes)
Connect signup screen to AuthService:
```dart
final authService = Provider.of<AuthService>(context);

// On signup button press
final success = await authService.signUp(
  email: emailController.text,
  password: passwordController.text,
  name: nameController.text,
);

if (success) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => MainWrapper()),
  );
}
```

### 4. Add Logout Button (2 minutes)
In settings or profile screen:
```dart
ElevatedButton(
  onPressed: () async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  },
  child: Text('Logout'),
)
```

### 5. Test End-to-End
- Run app: `flutter run`
- Create account
- Close app completely
- Reopen app
- **Expected:** Should open directly to home screen ✅

---

## 📊 USER DATA STRUCTURE

### Firestore Collection: `users`

```javascript
{
  "uid": "firebase_user_id",
  "email": "user@example.com",
  "name": "MD. Rasel",
  "createdAt": Timestamp,
  "isPremium": false,
  "mode": "general",  // worker | farmer | student | general
  "location": "Dhaka, Bangladesh"
}
```

### Accessing User Data

```dart
final authService = Provider.of<AuthService>(context);
final profile = await authService.getUserProfile();

print(profile['name']);      // "MD. Rasel"
print(profile['isPremium']); // false
print(profile['mode']);      // "general"
```

### Updating User Data

```dart
await authService.updateUserProfile({
  'isPremium': true,
  'mode': 'farmer',
  'location': 'Sylhet, Bangladesh'
});
```

---

## 🔄 MIGRATION FROM OLD AUTH

### Old System (ProfileService)
```dart
// Old way
profile.setLoggedIn(true);
profile.updateName(name);
```

### New System (AuthService)
```dart
// New way
await authService.signIn(email: email, password: password);
// Name and data automatically synced with Firebase
```

### Gradual Migration
You can keep both systems temporarily:
1. Use AuthService for authentication
2. Sync data to ProfileService for existing features
3. Gradually migrate features to use Firestore directly

---

## ⚠️ COMMON ISSUES & SOLUTIONS

### Issue: "Firebase not initialized"
**Solution:** Ensure `await Firebase.initializeApp()` is called in `main()`

### Issue: "google-services.json not found"
**Solution:** Download from Firebase Console and place in `android/app/`

### Issue: "minSdkVersion too low"
**Solution:** Set `minSdkVersion 21` in `android/app/build.gradle`

### Issue: "User stays logged in after uninstall"
**Solution:** This is expected. Firebase clears data on uninstall.

### Issue: "Can't create account - email already exists"
**Solution:** Use different email or reset password

---

## 📞 SUPPORT

**Developer:** MD. Rasel  
**Email:** raselofficial89@gmail.com

**Firebase Documentation:**
- [Flutter Firebase Setup](https://firebase.google.com/docs/flutter/setup)
- [Firebase Auth](https://firebase.google.com/docs/auth)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)

---

## ✅ COMPLETION CHECKLIST

### Code Implementation
- [x] AuthService created
- [x] AuthGate created
- [x] Main.dart updated
- [x] Dependencies added
- [x] Documentation complete

### Firebase Setup
- [ ] Firebase project created
- [ ] Android app added
- [ ] google-services.json downloaded
- [ ] Build.gradle updated
- [ ] Authentication enabled
- [ ] Firestore database created
- [ ] Security rules configured

### Integration
- [ ] Login screen connected
- [ ] Signup screen connected
- [ ] Logout button added
- [ ] End-to-end testing complete

---

**Status:** Code complete ✅ - Firebase configuration needed ⚠️

**Next Action:** Follow Step 1-6 in "FIREBASE CONFIGURATION REQUIRED" section above.

---

*End of Firebase Authentication Setup Guide*
