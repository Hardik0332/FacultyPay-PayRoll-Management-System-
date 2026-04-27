import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'notifications_page.dart';
import '../../widgets/notification_badge.dart';

class FacultyProfilePage extends StatefulWidget {
  const FacultyProfilePage({super.key});

  @override
  State<FacultyProfilePage> createState() => _FacultyProfilePageState();
}

class _FacultyProfilePageState extends State<FacultyProfilePage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  final Color successGreen = const Color(0xFF4CAF50);

  // --- FIREBASE STATE & CONTROLLERS ---
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController upiController = TextEditingController();

  String? avatarBase64;
  final ImagePicker _picker = ImagePicker();

  // Read-only fields
  String email = "";
  String department = "N/A";
  double hourlyRate = 0.0;

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
          nameController.text = data['name'] ?? '';
          upiController.text = data['upiId'] ?? '';
          email = data['email'] ?? '';
          department = data['department'] ?? 'N/A';
          avatarBase64 = data['avatarBase64'];
          hourlyRate = (data['hourlyRate'] is int)
              ? (data['hourlyRate'] as int).toDouble()
              : (data['hourlyRate'] as double? ?? 0.0);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading profile: $e"), backgroundColor: primaryRed));
      }
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
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'name': nameController.text.trim(),
        'upiId': upiController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Profile updated successfully!"), backgroundColor: successGreen));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating profile: $e"), backgroundColor: primaryRed));
      }
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

        await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
          'avatarBase64': base64Str,
        });

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

  // --- LOGOUT LOGIC ---
  Future<void> _logout() async {
    // Show confirmation dialog before logging out
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2E39),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Log Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to log out of FacultyPay?", style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Log Out", style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Replace '/login' with the actual route name of your Login Screen
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF282C37),
      body: Stack(
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: _buildHeader(),
                ),

                // --- THE PROFILE CARD ---
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF242832),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: isLoading
                        ? Center(child: CircularProgressIndicator(color: primaryRed))
                        : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar Hero Section
                          _buildAvatarSection(),
                          const SizedBox(height: 40),

                          // Editable Details
                          const Text("Editable Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 16),
                          _buildEditableField("Full Name", Icons.person_outline, nameController),
                          const SizedBox(height: 16),
                          _buildEditableField("UPI ID (For Payments)", Icons.qr_code, upiController),

                          const SizedBox(height: 40),
                          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 30),

                          // Read-Only College Details
                          Row(
                            children: [
                              const Text("College Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text("LOCKED", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildReadOnlyField("Email Address", email, Icons.email_outlined),
                          const SizedBox(height: 16),

                          // Side-by-side Read-Only fields
                          Row(
                            children: [
                              Expanded(child: _buildReadOnlyField("Department", department.toUpperCase(), Icons.business)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildReadOnlyField("Hourly Rate", "₹${hourlyRate.toStringAsFixed(2)} / hr", Icons.payments_outlined)),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // Buttons Area
                          _buildSaveButton(),
                          const SizedBox(height: 16),
                          _buildLogoutButton(), // <-- New Logout Button added here
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Bottom Navigation handled by wrapper
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text("My Profile", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5), overflow: TextOverflow.ellipsis)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---> CLICKABLE NOTIFICATION BUTTON <---
            const NotificationBadge(),
          ],
        )
      ],
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Outer Glow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: primaryRed.withValues(alpha: 0.3), blurRadius: 30)],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: const Color(0xFF3B4154),
                  backgroundImage: avatarBase64 != null && avatarBase64!.isNotEmpty
                      ? MemoryImage(base64Decode(avatarBase64!))
                      : null,
                  child: (avatarBase64 == null || avatarBase64!.isEmpty)
                      ? const Icon(Icons.person, size: 55, color: Colors.white)
                      : null,
                ),
              ),
              // Camera Edit Button (Wired to Firebase)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF242832), width: 3),
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("Tap to change picture", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, IconData icon, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
            filled: true,
            fillColor: const Color(0xFF2A2E39),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryRed, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(value, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
              ),
              Icon(Icons.lock_outline, size: 14, color: Colors.white.withValues(alpha: 0.2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: isSaving ? null : _updateProfile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSaving ? primaryRed.withValues(alpha: 0.5) : primaryRed,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: primaryRed.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryRed.withValues(alpha: 0.5), width: 1.5), // Subtle red outline
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: primaryRed, size: 20),
            const SizedBox(width: 8),
            Text("Log Out", style: TextStyle(color: primaryRed, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}