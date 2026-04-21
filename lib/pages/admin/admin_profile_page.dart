import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/app_sidebars.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final TextEditingController nameController = TextEditingController();

  // Read-only fields
  String email = "";
  String role = "Admin";

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

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
          isLoading = false;
        });
      } else {
        // Fallback if document doesn't fully exist yet
        setState(() {
          email = currentUser!.email ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading profile: $e")));
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name cannot be empty")));
      return;
    }

    setState(() => isSaving = true);

    try {
      // Use set with SetOptions(merge: true) to ensure we don't overwrite other fields
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
        'name': nameController.text.trim(),
        'role': 'admin', // Enforce admin role
        'email': email,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
        title: const Text("Admin Profile"),
        elevation: 0,
      ),
      drawer: isDesktop
          ? null
          : const Drawer(
        child: AdminSidebar(activeRoute: '/admin/profile'),
      ),
      body: Row(
        children: [
          // ✅ Admin Sidebar for Desktop
          if (isDesktop) const AdminSidebar(activeRoute: '/admin/profile'),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 40 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Admin Profile", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Manage your system administrator details.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),

                  Container(
                    padding: EdgeInsets.all(isDesktop ? 32 : 20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- EDITABLE FIELDS ---
                        const Text("Editable Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        _buildLabel("Full Name"),
                        TextField(controller: nameController, decoration: _inputDeco("Your Name", icon: Icons.person_outline)),
                        const SizedBox(height: 32),

                        // --- READ-ONLY FIELDS ---
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text("System Details (Read-Only)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 16),

                        if (isDesktop)
                          Row(
                            children: [
                              Expanded(child: _buildReadOnlyField("Email Address", email, Icons.email_outlined)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildReadOnlyField("System Role", role, Icons.security)),
                            ],
                          )
                        else ...[
                          _buildReadOnlyField("Email Address", email, Icons.email_outlined),
                          const SizedBox(height: 16),
                          _buildReadOnlyField("System Role", role, Icons.security),
                        ],

                        const SizedBox(height: 40),

                        // --- SAVE BUTTON ---
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: isSaving ? null : _updateProfile,
                            icon: isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save),
                            label: const Text("Save Changes", style: TextStyle(fontSize: 16, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff45a182),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  InputDecoration _inputDeco(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Text(value, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}