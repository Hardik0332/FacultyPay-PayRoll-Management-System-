import 'package:animations/animations.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/theme_manager.dart'; // ✅ Added ThemeManager

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? avatarBase64;
  String email = "";
  String role = "Admin";

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- FIREBASE LOGIC ---
  Future<void> _loadUserData() async {
    if (currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          nameController.text = data['name'] ?? 'Admin User';
          email = data['email'] ?? currentUser!.email ?? '';
          role = (data['role'] ?? 'admin').toString().toUpperCase();
          avatarBase64 = data['avatarBase64'];
          isLoading = false;
        });
      } else {
        setState(() {
          email = currentUser!.email ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final colors = ThemeManager.instance.colors;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: colors.error));
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    final colors = ThemeManager.instance.colors;

    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Name cannot be empty"), backgroundColor: colors.error));
      return;
    }

    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
        'name': nameController.text.trim(),
        'role': 'admin',
        'email': email,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Profile updated successfully!"), backgroundColor: colors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: colors.error));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    final colors = ThemeManager.instance.colors;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 50,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Str = base64Encode(bytes);
        setState(() {
          avatarBase64 = base64Str;
        });

        await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
          'avatarBase64': base64Str,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Profile picture updated!"), backgroundColor: colors.success));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error picking image: $e"), backgroundColor: colors.error));
      }
    }
  }

  // --- PASSWORD RESET LOGIC ---
  Future<void> _sendPasswordReset() async {
    final colors = ThemeManager.instance.colors;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Email address not found."), backgroundColor: colors.error));
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Reset Password", style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold)),
        content: Text("We will send a secure password reset link to $email.", style: TextStyle(color: colors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Send Email", style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password reset email sent to $email!"), backgroundColor: colors.success));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: colors.error));
        }
      }
    }
  }

  // --- LOGOUT LOGIC ---
  Future<void> _confirmLogout() async {
    final colors = ThemeManager.instance.colors;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Sign Out", style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to sign out of the Admin Portal?", style: TextStyle(color: colors.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text("Cancel", style: TextStyle(color: colors.textMuted))
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text("Sign Out", style: TextStyle(color: colors.error, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: ThemeManager.instance,
        builder: (context, child) {
          final colors = ThemeManager.instance.colors;
          final isDark = ThemeManager.instance.isDarkMode;

          return Stack(
            children: [
              // 1. Background Gradient (Dynamic)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.bgTop, colors.bgBottom],
                  ),
                ),
              ),

              // 2. Main Content
              SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: _buildHeader(colors, isDark),
                        ),

                        // Main Container
                        Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
                            ),
                            child: isLoading
                                ? Center(child: CircularProgressIndicator(color: colors.primary))
                                : Padding(
                              padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 120),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Avatar Section
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: colors.primary.withValues(alpha: 0.5), width: 2),
                                          ),
                                          child: CircleAvatar(
                                            radius: 50,
                                            backgroundColor: isDark ? const Color(0xFF4A5060) : colors.bgTop,
                                            backgroundImage: avatarBase64 != null && avatarBase64!.isNotEmpty ? MemoryImage(base64Decode(avatarBase64!)) : null,
                                            child: (avatarBase64 == null || avatarBase64!.isEmpty)
                                                ? Icon(Icons.person, color: colors.textMuted, size: 40)
                                                : null,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle, border: Border.all(color: colors.card, width: 3)),
                                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(role, style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                  const SizedBox(height: 32),

                                  // Form Section
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text("ACCOUNT DETAILS", style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  ),
                                  const SizedBox(height: 16),

                                  _buildEditableField("Full Name", Icons.person_outline, nameController, colors, isDark),
                                  const SizedBox(height: 16),
                                  _buildReadOnlyField("Email Address", email, Icons.email_outlined, colors, isDark),

                                  const SizedBox(height: 32),

                                  // Save Button
                                  _buildSaveButton(colors),

                                  const SizedBox(height: 40),
                                  Container(height: 1, color: colors.textMain.withValues(alpha: 0.05)),
                                  const SizedBox(height: 32),

                                  // Reset Password Button
                                  _buildResetPasswordButton(colors, isDark),
                                  const SizedBox(height: 16),

                                  // Logout Button
                                  GestureDetector(
                                    onTap: _confirmLogout,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        color: colors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.logout, color: colors.error, size: 20),
                                          const SizedBox(width: 8),
                                          Text("Sign Out", style: TextStyle(color: colors.error, fontSize: 15, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
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
          );
        }
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader(AppColors colors, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Admin Action", style: TextStyle(color: primaryRed, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text("My Profile", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colors.textMain, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Theme Toggle
            // Theme Toggle
            ThemeSwitcher(
              clipper: const ThemeSwitcherCircleClipper(),
              builder: (context) {
                return GestureDetector(
                  onTap: () {
                    ThemeManager.instance.toggleTheme();
                    final newColors = ThemeManager.instance.colors;
                    final newIsDark = ThemeManager.instance.isDarkMode;
                    ThemeSwitcher.of(context).changeTheme(
                      theme: ThemeData(
                        brightness: newIsDark ? Brightness.dark : Brightness.light,
                        primaryColor: newColors.primary,
                        scaffoldBackgroundColor: newIsDark ? Colors.black : newColors.bgBottom,
                        cardColor: newColors.card,
                        appBarTheme: AppBarTheme(
                          backgroundColor: newColors.card,
                          foregroundColor: newColors.textMain,
                        ),
                        useMaterial3: false,
                        pageTransitionsTheme: const PageTransitionsTheme(
                          builders: {
                            TargetPlatform.android: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.scaled),
                            TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.scaled),
                            TargetPlatform.windows: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.scaled),
                            TargetPlatform.macOS: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.scaled),
                            TargetPlatform.linux: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.scaled),
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? colors.textMain.withValues(alpha: 0.1) : colors.textMuted.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ThemeManager.instance.currentMode == AppThemeMode.system
                          ? Icons.brightness_auto
                          : (ThemeManager.instance.currentMode == AppThemeMode.light ? Icons.light_mode : Icons.dark_mode_outlined),
                      color: ThemeManager.instance.currentMode == AppThemeMode.light ? Colors.amber : colors.textMain,
                      size: 20,
                    ),
                  ),
                );
              }
            ),
          ],
        )
      ],
    );
  }

  Widget _buildEditableField(String label, IconData icon, TextEditingController controller, AppColors colors, bool isDark) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: colors.textMain, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textMuted),
        prefixIcon: Icon(icon, color: colors.textMuted, size: 20),
        filled: true,
        fillColor: isDark ? colors.textMain.withValues(alpha: 0.03) : colors.bgTop,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? colors.textMain.withValues(alpha: 0.1) : Colors.transparent)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary, width: 1.5)),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon, AppColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? colors.textMain.withValues(alpha: 0.02) : colors.bgTop,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? colors.textMain.withValues(alpha: 0.05) : Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.textMuted.withValues(alpha: 0.5), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: colors.textMuted, fontSize: 15)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppColors colors) {
    return GestureDetector(
      onTap: isSaving ? null : _updateProfile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSaving ? colors.primary.withValues(alpha: 0.5) : colors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _buildResetPasswordButton(AppColors colors, bool isDark) {
    return GestureDetector(
      onTap: _sendPasswordReset,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? colors.textMain.withValues(alpha: 0.2) : colors.textMuted.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_reset, color: colors.textMain.withValues(alpha: 0.8), size: 20),
            const SizedBox(width: 8),
            Text("Reset Password", style: TextStyle(color: colors.textMain.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}
