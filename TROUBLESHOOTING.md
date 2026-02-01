# 🔧 ITM Connect Troubleshooting Guide

## Issue 1: Noto Fonts Missing

### ✅ **FIXED**
- Added `google_fonts` package fonts to `pubspec.yaml`
- Noto Sans font family configured
- Noto Serif Display font family configured

### What was done:
```yaml
fonts:
  - family: NotoSans
    fonts:
      - asset: packages/google_fonts/fonts/NotoSans-Regular.ttf
      - asset: packages/google_fonts/fonts/NotoSans-Bold.ttf
  - family: NotoSerifDisplay
    fonts:
      - asset: packages/google_fonts/fonts/NotoSerifDisplay-Regular.ttf
```

### To verify fix:
```bash
flutter pub get
flutter run -d chrome  # or flutter run -d web
```

---

## Issue 2: Firebase Admin Login Not Working

### Possible Causes:

#### ❌ **Cause 1: Admin Account Doesn't Exist**
- **Solution:** Create admin account in Firebase Console
  1. Go to [Firebase Console](https://console.firebase.google.com)
  2. Select **ITM Connect** project
  3. Go to **Authentication**
  4. Click **Add User**
  5. Enter: `admin@example.com` / `Admin@123456`

#### ❌ **Cause 2: Wrong Email/Password Format**
- **Check:**
  - Email must be valid format: `admin@example.com`
  - Password must be at least 6 characters
  - No extra spaces before/after

#### ❌ **Cause 3: Firebase Project Configuration Issue**
- **Check:**
  1. Verify `google-services.json` is in `android/app/`
  2. Verify `lib/firebase_options.dart` has correct config
  3. Check Firebase project ID matches

### ✅ **How to Debug:**

**Add console logs to login screen:**
```dart
void _handleLogin() async {
  print('🔍 Email: ${_emailController.text.trim()}');
  print('🔍 Password length: ${_passwordController.text.length}');
  
  // ... rest of code
}
```

**Check browser console (F12):**
- Open Chrome DevTools
- Go to **Console** tab
- Look for Firebase errors
- Check Network tab for failed requests

### ✅ **Test Steps:**

1. **Start the app:**
   ```bash
   flutter run -d chrome
   ```

2. **Navigate to Admin Login**
   - URL: `http://localhost:49805/admin-login` (or similar)

3. **Enter test credentials:**
   - Email: `admin@example.com`
   - Password: `Admin@123456`

4. **Watch for errors:**
   - Check app for error message
   - Check browser console (F12)
   - Check Flutter console output

---

## Issue 3: Firebase Connection Issues

### Check Firebase Configuration

**File:** `lib/firebase_options.dart`
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: '1:PROJECT_ID:web:APP_ID',
  messagingSenderId: 'MESSAGING_SENDER_ID',
  projectId: 'itm-connect-c864a',
  authDomain: 'itm-connect-c864a.firebaseapp.com',
  storageBucket: 'itm-connect-c864a.appspot.com',
);
```

**Verify in Firebase Console:**
- Project ID matches
- API key is valid
- Auth domain is correct

---

## Common Error Messages & Fixes

| Error | Cause | Solution |
|-------|-------|----------|
| "User not found" | Admin account not created | Create account in Firebase Console |
| "Incorrect password" | Wrong password entered | Check password is correct |
| "Invalid email format" | Email validation failed | Use format: `admin@example.com` |
| "Could not find Noto fonts" | Fonts not configured | Run `flutter pub get` |
| "Firebase not initialized" | firebase_core not initialized | Ensure `Firebase.initializeApp()` in main.dart |
| "Permission denied" | Firestore rules deny access | Check Firestore security rules |

---

## 🚀 Quick Fix Checklist

- [ ] Run `flutter pub get`
- [ ] Run `flutter clean`
- [ ] Verify admin account exists in Firebase
- [ ] Check email/password are correct
- [ ] Verify `google-services.json` exists
- [ ] Verify `firebase_options.dart` has correct config
- [ ] Check browser console for errors (F12)
- [ ] Restart Flutter dev server

---

## 📋 Test Admin Credentials

```
Email:    admin@example.com
Password: Admin@123456
```

**Create these in Firebase:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select "ITM Connect" project
3. Go to Authentication
4. Create user with above credentials

---

## 🔐 Security Note

⚠️ Test credentials above are for **development only**.

**For Production:**
- Use strong, unique passwords
- Enable 2-Factor Authentication
- Don't commit credentials to version control
- Use environment variables for sensitive data

---

## 📞 Need More Help?

If issues persist, check:

1. **Flutter Logs:**
   ```bash
   flutter logs
   ```

2. **Browser Console:**
   - Press F12 → Console tab
   - Look for red error messages

3. **Firebase Rules:**
   - Go to Firestore Database
   - Check Security Rules
   - Look for access denied errors

4. **Network Tab:**
   - Press F12 → Network tab
   - Look for failed requests to Firebase
   - Check for CORS or SSL errors

