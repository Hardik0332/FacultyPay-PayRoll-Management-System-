import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/theme_manager.dart'; // ✅ Import ThemeManager

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool rememberMe = false;
  bool _obscurePassword = true; // ✅ State for password visibility

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  // ✅ Remember Me Logic (Works perfectly with SharedPreferences)
  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final bool remembered = prefs.getBool('remember_me') ?? false;
    if (remembered) {
      setState(() {
        rememberMe = true;
        emailController.text = prefs.getString('remembered_email') ?? '';
        passwordController.text = prefs.getString('remembered_password') ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: ThemeManager.instance,
        builder: (context, child) {
          final colors = ThemeManager.instance.colors;
          final isDark = ThemeManager.instance.isDarkMode;

          return Scaffold(
            body: Stack(
              children: [
                // 1. Dynamic Background Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colors.bgTop, colors.bgBottom],
                    ),
                  ),
                ),

                // 2. Login Card (Theme Toggle Button Removed)
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Frosted Effect
                        child: Container(
                          width: 400,
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: isDark ? colors.card.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8), // Glass Card
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
                            boxShadow: isDark
                                ? [const BoxShadow(color: Colors.black38, blurRadius: 32, offset: Offset(0, 8))]
                                : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 32, offset: const Offset(0, 8))],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon Header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.school, size: 40, color: colors.primary),
                              ),
                              const SizedBox(height: 24),
                              Text("FacultyPay", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colors.textMain)),
                              const SizedBox(height: 8),
                              Text(
                                "Secure access to your academic\nfinancial dashboard.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colors.textMuted, fontSize: 14),
                              ),
                              const SizedBox(height: 40),

                              // EMAIL FIELD
                              _buildLabel("Institution Email", colors),
                              TextField(
                                controller: emailController,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(color: colors.textMain),
                                decoration: _glassInputDecoration("faculty@university.edu", colors, isDark),
                              ),
                              const SizedBox(height: 20),

                              // PASSWORD FIELD (Visibility Toggle intact)
                              _buildLabel("Password", colors),
                              TextField(
                                controller: passwordController,
                                obscureText: _obscurePassword, // Dynamic visibility
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  if (!isLoading) _handleEmailLogin(colors);
                                },
                                style: TextStyle(color: colors.textMain),
                                decoration: _glassInputDecoration("••••••••", colors, isDark).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: colors.textMuted,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // REMEMBER ME & FORGOT PASSWORD
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: rememberMe,
                                          onChanged: (val) => setState(() => rememberMe = val ?? false),
                                          fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? colors.primary : Colors.transparent),
                                          side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text("Remember me", style: TextStyle(color: colors.textMuted, fontSize: 13)),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () => _showForgotPasswordDialog(colors, isDark),
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                    child: Text("Forgot password?", style: TextStyle(color: colors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // SIGN IN BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    shadowColor: colors.primary.withValues(alpha: 0.5),
                                    elevation: 8,
                                  ),
                                  onPressed: isLoading ? null : () => _handleEmailLogin(colors),
                                  child: isLoading
                                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                      : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // DIVIDER
                              Row(
                                children: [
                                  Expanded(child: Divider(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text("OR SIGN IN WITH", style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  ),
                                  Expanded(child: Divider(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1))),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // SSO BUTTONS
                              _buildSSOButton("Google", "assets/images/google.png", () => _signInWithGoogle(colors), colors, isDark),
                              const SizedBox(height: 16),
                              _buildSSOButton("Microsoft", "assets/images/microsoft.png", () => _signInWithMicrosoft(colors), colors, isDark),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  // --- UI HELPERS ---
  Widget _buildLabel(String text, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: TextStyle(color: colors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }

  InputDecoration _glassInputDecoration(String hint, AppColors colors, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.5)),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    );
  }

  Widget _buildSSOButton(String provider, String iconPath, VoidCallback action, AppColors colors, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: isLoading ? null : action,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, height: 20, width: 20, errorBuilder: (_, __, ___) => Icon(Icons.language, color: colors.textMain)),
            const SizedBox(width: 12),
            Text(provider, style: TextStyle(color: colors.textMain, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // --- AUTHENTICATION LOGIC ---
  Future<void> _handleEmailLogin(AppColors colors) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter both email and password", colors.warning);
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

      // ✅ Process Remember Me
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('remembered_email', email);
        await prefs.setString('remembered_password', password);
      } else {
        await prefs.setBool('remember_me', false);
        await prefs.remove('remembered_email');
        await prefs.remove('remembered_password');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => isLoading = false);
      _showError(e.code, colors);
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      _showError(e.toString(), colors);
    }
  }

  void _showForgotPasswordDialog(AppColors colors, bool isDark) {
    final TextEditingController resetEmailController = TextEditingController(text: emailController.text.trim());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold, color: colors.textMain)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter your email address to receive a reset link.", style: TextStyle(color: colors.textMuted)),
              const SizedBox(height: 20),
              TextField(
                controller: resetEmailController,
                style: TextStyle(color: colors.textMain),
                decoration: _glassInputDecoration("Email", colors, isDark),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: colors.textMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(context);
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  _showSnackBar("Reset link sent! Please check your email.", colors.success);
                } on FirebaseAuthException catch (e) {
                  _showSnackBar(_getFriendlyErrorMessage(e.code), colors.error);
                }
              },
              child: const Text("Send Link", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signInWithGoogle(AppColors colors) async {
    setState(() => isLoading = true);
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await GoogleSignIn.instance.initialize(
          serverClientId: '1085093252774-4ee6ucv8alpslq5jvklba1pokdi2m68c.apps.googleusercontent.com',
        );
        final GoogleSignInAccount? gUser = await GoogleSignIn.instance.authenticate();
        if (gUser == null) {
          if (mounted) setState(() => isLoading = false);
          _showError("popup-closed-by-user", colors);
          return;
        }
        final GoogleSignInAuthentication gAuth = gUser.authentication;
        final credential = GoogleAuthProvider.credential(idToken: gAuth.idToken);
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      if (e is FirebaseAuthException) {
        _showError(e.code, colors);
      } else {
        _showError("popup-closed-by-user", colors);
      }
    }
  }

  Future<void> _signInWithMicrosoft(AppColors colors) async {
    setState(() => isLoading = true);
    try {
      final provider = OAuthProvider('microsoft.com');
      provider.setCustomParameters({'prompt': 'select_account'});
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      if (e is FirebaseAuthException) {
        _showError(e.code, colors);
      } else {
        _showError("popup-closed-by-user", colors);
      }
    }
  }

  void _showError(String code, AppColors colors) {
    if (!mounted) return;
    setState(() => isLoading = false);
    _showSnackBar(_getFriendlyErrorMessage(code), colors.error);
  }

  void _showSnackBar(String message, Color bgColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getFriendlyErrorMessage(String code) {
    if (code.contains('user-not-found') || code.contains('invalid-credential')) return "No account found for that email/password.";
    if (code.contains('wrong-password')) return "Incorrect password. Please try again.";
    if (code.contains('invalid-email')) return "Please enter a valid email address.";
    if (code.contains('popup-closed-by-user') || code.contains('cancelled')) return "Sign-in was cancelled.";
    if (code.contains('too-many-requests')) return "Too many failed attempts. Please try resetting your password.";
    return "Authentication Failed: $code";
  }
}