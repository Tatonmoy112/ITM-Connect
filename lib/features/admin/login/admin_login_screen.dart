import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itm_connect/features/admin/dashboard/admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _isLoading = false;
  int _failedLoginAttempts = 0;
  DateTime? _lockoutTime;
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// ✅ SECURITY: Comprehensive email validation (RFC 5322 simplified)
  bool _isValidEmail(String email) {
    if (email.isEmpty || email.length > 254) return false;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailRegex.hasMatch(email);
  }

  /// ✅ SECURITY: Password strength validation
  bool _isStrongPassword(String password) {
    if (password.isEmpty) return false;
    if (password.length < 6) return false;
    return true;
  }

  /// ✅ SECURITY: Check for SQL injection attempts (for password only)
  bool _isSuspiciousInput(String input) {
    if (input.isEmpty) return false;
    
    final suspiciousPatterns = [
      RegExp(r"('|(\\-\\-)|(;))", caseSensitive: false),  // SQL injection
      RegExp(r"(select|insert|update|delete|drop|create|alter|exec|union)", caseSensitive: false),
      RegExp(r"(<script|javascript:|onerror|onclick|onload)", caseSensitive: false),  // XSS
      RegExp(r"(\\\x00|\\\x1a|\\\n|\\\r)", caseSensitive: false), // Null bytes
    ];
    
    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(input)) return true;
    }
    return false;
  }

  /// ✅ SECURITY: Check if account is locked due to failed attempts
  bool _isAccountLocked() {
    if (_lockoutTime == null) return false;
    
    final now = DateTime.now();
    if (now.difference(_lockoutTime!).inSeconds < _lockoutDuration.inSeconds) {
      return true;
    } else {
      // Reset lockout
      _lockoutTime = null;
      _failedLoginAttempts = 0;
      return false;
    }
  }

  /// ✅ SECURITY: Get remaining lockout time
  int _getRemainingLockoutSeconds() {
    if (_lockoutTime == null) return 0;
    
    final now = DateTime.now();
    final elapsed = now.difference(_lockoutTime!).inSeconds;
    final remaining = _lockoutDuration.inSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  void _handleLogin() async {
    // ✅ SECURITY: Check if account is locked
    if (_isAccountLocked()) {
      final remainingSeconds = _getRemainingLockoutSeconds();
      final minutes = (remainingSeconds / 60).ceil();
      
      if (mounted) {
        setState(() {
          _errorMessage = '❌ Too many failed attempts. Try again in $minutes minute(s).';
          _isLoading = false;
        });
      }
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = _emailController.text.trim().toLowerCase();
        final password = _passwordController.text;

        // ✅ SECURITY: Validate email format
        if (!_isValidEmail(email)) {
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'Invalid email format',
          );
        }

        // ✅ SECURITY: Check for SQL injection / XSS attempts (password only)
        if (_isSuspiciousInput(password)) {
          throw FirebaseAuthException(
            code: 'suspicious-input',
            message: 'Invalid characters detected in password',
          );
        }

        // ✅ SECURITY: Check password strength
        if (!_isStrongPassword(password)) {
          throw FirebaseAuthException(
            code: 'weak-password',
            message: 'Password must be at least 6 characters',
          );
        }

        // Firebase Authentication
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // ✅ SECURITY: Reset failed login attempts on success
        _failedLoginAttempts = 0;
        _lockoutTime = null;

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        // ✅ SECURITY: Increment failed login attempts
        _failedLoginAttempts++;
        
        if (_failedLoginAttempts >= _maxLoginAttempts) {
          _lockoutTime = DateTime.now();
        }

        String errorMsg = 'Login failed';
        if (e.code == 'user-not-found') {
          errorMsg = 'Invalid credentials. Please check your email.';
        } else if (e.code == 'wrong-password') {
          errorMsg = 'Invalid credentials. Please check your password.';
        } else if (e.code == 'invalid-email') {
          errorMsg = 'Invalid email format.';
        } else if (e.code == 'user-disabled') {
          errorMsg = '⚠️ This account has been disabled for security reasons.';
        } else if (e.code == 'too-many-requests') {
          errorMsg = '❌ Too many login attempts. Please try again later.';
          _lockoutTime = DateTime.now();
        } else if (e.code == 'suspicious-input') {
          errorMsg = '⚠️ ${e.message}';
        } else if (e.code == 'weak-password') {
          errorMsg = '⚠️ ${e.message}';
        }

        if (mounted) {
          setState(() {
            _errorMessage = errorMsg;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            // ✅ SECURITY: Don't expose full error details to user
            _errorMessage = 'An error occurred. Please try again later.';
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget buildAnimatedLogoIcon() {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.white, // ✅ Soft white background
      child: Icon(
        Icons.school,
        size: 32,
        color: Colors.teal.shade700, // ✅ Teal color
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.school,
            size: 20,
            color: Colors.teal.shade700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.teal),
            onPressed: () {
              // Direct navigation to user home screen (no dialog needed on login page)
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenWidth < 600 ? double.infinity : 500,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Teal Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Admin Login',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Secure access panel',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: const Icon(
                                  Icons.school,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Form Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Email',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailController,
                                  autofillHints: const [AutofillHints.email],
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: 'admin@example.com',
                                    prefixIcon: const Icon(Icons.email),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter email';
                                    }
                                    if (!_isValidEmail(value.trim())) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Password',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  autofillHints: const [AutofillHints.password],
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    icon: _isLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.login, size: 18),
                                    label: Text(_isLoading ? 'Logging in...' : 'Login'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isLoading ? Colors.grey : Colors.teal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Footer
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '© 2025 ITM Connect. All rights reserved.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
