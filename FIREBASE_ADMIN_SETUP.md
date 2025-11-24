# 🔐 Firebase Admin Account Setup Guide

## How to Create Test Admin Credentials in Firebase

### Step 1: Go to Firebase Console
1. Visit [Firebase Console](https://console.firebase.google.com)
2. Select your **ITM Connect** project
3. Go to **Authentication** (left sidebar)

### Step 2: Create Admin User
1. Click **Add User** or **Create user**
2. Enter these test credentials:
   ```
   Email: admin@example.com
   Password: Admin@123456
   ```
   (Use a strong password with uppercase, lowercase, numbers, and symbols)

3. Click **Create User**

### Step 3: Create Firestore Admin Document
1. Go to **Firestore Database** (left sidebar)
2. Click **Start Collection** or add to existing `admins` collection
3. Create a document with ID: `{uid-of-created-user}`
4. Add these fields:
   ```json
   {
     "email": "admin@example.com",
     "role": "admin",
     "name": "Administrator",
     "createdAt": "2025-11-24"
   }
   ```

### Step 4: Test Login
Use these credentials in your app:
- **Email:** `admin@example.com`
- **Password:** `Admin@123456`

---

## Alternative: Use Firebase CLI

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Create user via CLI
firebase auth:import users.json --hash-algo=bcrypt
```

---

## Common Issues & Solutions

### ❌ "User not found" error
- **Solution:** Make sure user is created in Firebase Authentication
- Check email spelling (case-sensitive in some cases)

### ❌ "Wrong password" error
- **Solution:** Double-check password capitalization
- Firebase passwords are case-sensitive

### ❌ "Invalid email" error
- **Solution:** Use format: `example@domain.com`
- Make sure it's a valid email format

---

## 🔒 Security Tips

⚠️ **For Production:**
- Never use simple passwords like `password123`
- Use strong passwords: 12+ characters, mixed case, numbers, symbols
- Implement 2-Factor Authentication (2FA)
- Add rate limiting to login attempts
- Monitor failed login attempts

---

## 📱 Test Login Page

Once admin account is created, test with:

**URL:** `http://localhost:49805` (or your dev server)

**Navigate to:** Admin Login Page

**Enter:**
- Email: `admin@example.com`
- Password: `Admin@123456`

**Expected:** Should redirect to Admin Dashboard

