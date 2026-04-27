import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  final Color successGreen = const Color(0xFF4ADE80);
  final Color pendingOrange = const Color(0xFFFBBF24);
  final Color verifiedBlue = const Color(0xFF60A5FA);

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: primaryRed));
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Name cannot be empty"), backgroundColor: primaryRed));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Profile updated successfully!"), backgroundColor: successGreen));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: primaryRed));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _pickImage() async {
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Profile picture updated!"), backgroundColor: successGreen));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error picking image: $e"), backgroundColor: primaryRed));
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2E39),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Sign Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to sign out of the Admin Portal?", style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text("Cancel", style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text("Sign Out", style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold))
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
    return Stack( // ✅ REMOVED SCAFFOLD, wrapped natively in Stack
      children: [
        // 1. Background Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3B4154), Color(0xFF1E212A)],
            ),
          ),
        ),

        // 2. Main Content
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: _buildHeader(),
              ),

              // Main Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF242832),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: isLoading
                      ? Center(child: CircularProgressIndicator(color: primaryRed))
                      : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 120), // ✅ Preserved 120px padding
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
                                  border: Border.all(color: verifiedBlue.withValues(alpha: 0.5), width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: const Color(0xFF4A5060),
                                  backgroundImage: avatarBase64 != null && avatarBase64!.isNotEmpty ? MemoryImage(base64Decode(avatarBase64!)) : null,
                                  child: (avatarBase64 == null || avatarBase64!.isEmpty)
                                      ? const Icon(Icons.person, color: Colors.white, size: 40)
                                      : null,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: verifiedBlue, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF242832), width: 3)),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(role, style: TextStyle(color: verifiedBlue, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        const SizedBox(height: 32),

                        // Form Section
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("ACCOUNT DETAILS", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                        const SizedBox(height: 16),

                        _buildEditableField("Full Name", Icons.person_outline, nameController),
                        const SizedBox(height: 16),
                        _buildReadOnlyField("Email Address", email, Icons.email_outlined),

                        const SizedBox(height: 32),

                        // Save Button
                        _buildSaveButton(),

                        const SizedBox(height: 40),
                        Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                        const SizedBox(height: 32),

                        // Logout Button
                        GestureDetector(
                          onTap: _confirmLogout,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: primaryRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: primaryRed.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, color: primaryRed, size: 20),
                                const SizedBox(width: 8),
                                Text("Sign Out", style: TextStyle(color: primaryRed, fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Admin Action", style: TextStyle(color: primaryRed, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              const Text("My Profile", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, IconData icon, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
        filled: true,
        fillColor: const Color(0xFF2A2E39),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: verifiedBlue, width: 1.5)),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: isSaving ? null : _updateProfile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSaving ? verifiedBlue.withValues(alpha: 0.5) : verifiedBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: verifiedBlue.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}