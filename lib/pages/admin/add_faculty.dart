import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../theme/theme_manager.dart'; // ✅ Added ThemeManager

class AdminAddFacultyPage extends StatefulWidget {
  const AdminAddFacultyPage({super.key});

  @override
  State<AdminAddFacultyPage> createState() => _AdminAddFacultyPageState();
}

class _AdminAddFacultyPageState extends State<AdminAddFacultyPage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  // --- CONTROLLERS & STATE ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController upiController = TextEditingController();
  String? selectedDepartment;
  bool isLoading = false;

  // --- FIREBASE SUBMIT LOGIC ---
  Future<void> _saveFaculty(AppColors colors) async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty || rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Please fill all required fields"), backgroundColor: colors.error));
      return;
    }

    setState(() => isLoading = true);

    try {
      FirebaseApp tempApp;
      try {
        tempApp = Firebase.app('tempRegApp');
      } catch (e) {
        tempApp = await Firebase.initializeApp(name: 'tempRegApp', options: Firebase.app().options);
      }

      UserCredential cred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': 'faculty',
        'department': selectedDepartment,
        'hourlyRate': double.parse(rateController.text),
        'upiId': upiController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      await tempApp.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Faculty Added Successfully!"), backgroundColor: colors.success));
        nameController.clear();
        emailController.clear();
        passwordController.clear();
        rateController.clear();
        upiController.clear();
        setState(() => selectedDepartment = null);

        // Redirect to View Faculty after adding
        Navigator.pushReplacementNamed(context, '/admin/view-faculty');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: colors.error));
    } finally {
      if (mounted) setState(() => isLoading = false);
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
              // Background Gradient (Dynamic)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.bgTop, colors.bgBottom],
                  ),
                ),
              ),

              SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: _buildHeader(colors, isDark),
                        ),

                        // Main Form Container
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colors.card, // ✅ DYNAMIC
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
                            ),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 120),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Faculty Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textMain)),
                                  const SizedBox(height: 4),
                                  Text("Onboard a new faculty member to the system.", style: TextStyle(color: colors.textMuted, fontSize: 13)),
                                  const SizedBox(height: 24),

                                  // Forms
                                  _buildEditableField("Full Name", Icons.person_outline, nameController, "e.g. Dr. Sarah Connor", colors, isDark),
                                  const SizedBox(height: 16),
                                  _buildEditableField("Email Address", Icons.email_outlined, emailController, "faculty@university.edu", colors, isDark, keyboardType: TextInputType.emailAddress),
                                  const SizedBox(height: 16),
                                  _buildEditableField("Set Password", Icons.lock_outline, passwordController, "Login password", colors, isDark, isPassword: true),

                                  const SizedBox(height: 32),
                                  Container(height: 1, color: colors.textMain.withValues(alpha: 0.1)),
                                  const SizedBox(height: 24),

                                  Text("Payment & Department", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textMain)),
                                  const SizedBox(height: 16),

                                  Row(
                                    children: [
                                      Expanded(child: _buildEditableField("Hourly Rate", Icons.currency_rupee, rateController, "0.00", colors, isDark, keyboardType: TextInputType.number)),
                                      const SizedBox(width: 16),
                                      Expanded(child: _buildDepartmentDropdown(colors, isDark)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  _buildEditableField("UPI ID (Optional)", Icons.qr_code, upiController, "e.g. john@ybl", colors, isDark),

                                  const SizedBox(height: 40),

                                  // Save Button
                                  _buildSaveButton(colors),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
    );
  }

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
              Text("Add Faculty", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colors.textMain, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Theme Toggle
            // Theme Toggle
            GestureDetector(
              onTap: () => ThemeManager.instance.toggleTheme(),
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
            ),
            const SizedBox(width: 12),

            // Floating dialog search
            GestureDetector(
              onTap: () async {
                final String? selectedUid = await showDialog<String>(
                  context: context,
                  builder: (context) => const FacultySearchDialog(),
                );

                if (selectedUid != null && mounted) {
                  Navigator.pushReplacementNamed(context, '/admin/view-faculty');
                }
              },
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isDark ? colors.textMain.withValues(alpha: 0.15) : colors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.search, color: isDark ? Colors.white : colors.primary, size: 20)
              ),
            ),
            const SizedBox(width: 12),
            StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
                builder: (context, snapshot) {
                  String? avatarBase64;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    avatarBase64 = data?['avatarBase64'];
                  }
                  return GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/admin/profile'),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: isDark ? colors.textMain.withValues(alpha: 0.15) : colors.primary,
                      backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
                      child: (avatarBase64 == null || avatarBase64.isEmpty) ? Icon(Icons.person, color: isDark ? colors.textMain : Colors.white, size: 20) : null,
                    ),
                  );
                }
            ),
          ],
        )
      ],
    );
  }

  Widget _buildEditableField(String label, IconData icon, TextEditingController controller, String hint, AppColors colors, bool isDark, {bool isPassword = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: TextStyle(color: colors.textMain, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: colors.textMuted, size: 20),
            filled: true,
            fillColor: isDark ? colors.textMain.withValues(alpha: 0.03) : colors.bgTop,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? colors.textMain.withValues(alpha: 0.1) : Colors.transparent)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown(AppColors colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Department", style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedDepartment,
          isExpanded: true,
          dropdownColor: colors.card,
          style: TextStyle(color: colors.textMain, fontSize: 15),
          icon: Icon(Icons.arrow_drop_down, color: colors.textMuted),
          items: const [
            DropdownMenuItem(value: "cs", child: Text("Computer Science", overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(value: "eng", child: Text("Engineering", overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(value: "sci", child: Text("Science", overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(value: "arts", child: Text("Arts", overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(value: "bus", child: Text("Business", overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => selectedDepartment = v),
          decoration: InputDecoration(
            hintText: "Select",
            hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.5)),
            prefixIcon: Icon(Icons.business, color: colors.textMuted, size: 20),
            filled: true,
            fillColor: isDark ? colors.textMain.withValues(alpha: 0.03) : colors.bgTop,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? colors.textMain.withValues(alpha: 0.1) : Colors.transparent)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(AppColors colors) {
    return GestureDetector(
      onTap: isLoading ? null : () => _saveFaculty(colors),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isLoading ? colors.primary.withValues(alpha: 0.5) : colors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Save Faculty", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),
    );
  }
}

// ============================================================================
// THE BEAUTIFUL FLOATING SEARCH DIALOG (Matches the Dashboard!)
// ============================================================================
class FacultySearchDialog extends StatefulWidget {
  const FacultySearchDialog({super.key});

  @override
  State<FacultySearchDialog> createState() => _FacultySearchDialogState();
}

class _FacultySearchDialogState extends State<FacultySearchDialog> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: ThemeManager.instance,
        builder: (context, child) {
          final colors = ThemeManager.instance.colors;
          final isDark = ThemeManager.instance.isDarkMode;

          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? colors.textMain.withValues(alpha: 0.1) : Colors.transparent),
                  boxShadow: isDark
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))]
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 15))],
                ),
                child: Column(
                  children: [
                    // Search Input Bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        autofocus: true,
                        style: TextStyle(color: colors.textMain, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "Search faculty by name or email...",
                          hintStyle: TextStyle(color: colors.textMuted),
                          prefixIcon: Icon(Icons.search, color: colors.textMuted),
                          filled: true,
                          fillColor: isDark ? colors.bgBottom : colors.bgTop,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        onChanged: (val) {
                          setState(() {
                            query = val;
                          });
                        },
                      ),
                    ),

                    Container(height: 1, color: colors.textMain.withValues(alpha: 0.05)),

                    // Search Results
                    Expanded(
                      child: query.isEmpty
                          ? Center(
                        child: Text("Type to search...", style: TextStyle(color: colors.textMuted, fontSize: 14)),
                      )
                          : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'faculty').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator(color: colors.primary));
                          }

                          final docs = snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = (data['name'] ?? '').toString().toLowerCase();
                            final email = (data['email'] ?? '').toString().toLowerCase();
                            final q = query.toLowerCase();
                            return name.contains(q) || email.contains(q);
                          }).toList();

                          if (docs.isEmpty) {
                            return Center(
                              child: Text("No faculty found matching '$query'.", style: TextStyle(color: colors.textMuted)),
                            );
                          }

                          return ListView.builder(
                            itemCount: docs.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'Unknown';
                              final email = data['email'] ?? 'No email';
                              final avatarBase64 = data['avatarBase64'];

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDark ? colors.textMain.withValues(alpha: 0.15) : colors.primary.withValues(alpha: 0.1),
                                  backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
                                  child: (avatarBase64 == null || avatarBase64.isEmpty) ? Icon(Icons.person, color: isDark ? colors.textMain : colors.primary) : null,
                                ),
                                title: Text(name, style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold)),
                                subtitle: Text(email, style: TextStyle(color: colors.textMuted)),
                                onTap: () {
                                  Navigator.pop(context, data['uid'] ?? docs[index].id);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}