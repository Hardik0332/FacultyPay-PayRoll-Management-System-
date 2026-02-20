import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../widgets/app_sidebars.dart';

class AddFacultyPage extends StatefulWidget {
  const AddFacultyPage({super.key});

  @override
  State<AddFacultyPage> createState() => _AddFacultyPageState();
}

class _AddFacultyPageState extends State<AddFacultyPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  String? selectedDepartment;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
        title: const Text("Add Faculty"),
        elevation: 0,
      ),
      drawer: isDesktop
          ? null
          : const Drawer(
        child: AdminSidebar(activeRoute: '/admin/add-faculty'),
      ),
      body: Row(
        children: [
          if (isDesktop) const AdminSidebar(activeRoute: '/admin/add-faculty'),

          // MAIN CONTENT
          Expanded(
            // ✅ ONLY ADDED REFRESH INDICATOR HERE
            child: RefreshIndicator(
              color: theme.primaryColor,
              backgroundColor: theme.cardColor,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 600));
                nameController.clear();
                emailController.clear();
                passwordController.clear();
                rateController.clear();
                setState(() {
                  selectedDepartment = null;
                });
              },
              child: SingleChildScrollView(
                // ✅ ADDED PHYSICS FOR SCROLLING
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 40 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Add Faculty Member", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),

                    Container(
                      padding: EdgeInsets.all(isDesktop ? 32 : 20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Full Name"),
                          TextField(controller: nameController, decoration: _inputDeco("e.g. Dr. Sarah Connor")),
                          const SizedBox(height: 24),

                          _buildLabel("Email Address"),
                          TextField(controller: emailController, decoration: _inputDeco("faculty@university.edu", icon: Icons.email_outlined)),
                          const SizedBox(height: 24),

                          _buildLabel("Set Password"),
                          TextField(controller: passwordController, obscureText: true, decoration: _inputDeco("Login password", icon: Icons.lock_outline)),
                          const SizedBox(height: 24),

                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildRateField()),
                                const SizedBox(width: 24),
                                Expanded(child: _buildDeptField(theme)),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRateField(),
                                const SizedBox(height: 24),
                                _buildDeptField(theme),
                              ],
                            ),

                          const SizedBox(height: 40),
                          const Divider(),
                          const SizedBox(height: 20),

                          // Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/admin/dashboard'), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: isLoading ? null : _saveFaculty,
                                icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                                label: Text(isLoading ? "Saving..." : "Save Faculty", style: const TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff45a182),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Hourly Rate"),
        TextField(
          controller: rateController,
          keyboardType: TextInputType.number,
          decoration: _inputDeco("0.00", prefix: "₹ ", suffix: "/hr"),
        ),
      ],
    );
  }

  Widget _buildDeptField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Department"),
        DropdownButtonFormField<String>(
          value: selectedDepartment,
          dropdownColor: theme.cardColor,
          items: const [
            DropdownMenuItem(value: "cs", child: Text("Computer Science")),
            DropdownMenuItem(value: "eng", child: Text("Engineering")),
            DropdownMenuItem(value: "sci", child: Text("Science")),
            DropdownMenuItem(value: "arts", child: Text("Arts")),
            DropdownMenuItem(value: "bus", child: Text("Business")),
          ],
          onChanged: (v) => setState(() => selectedDepartment = v),
          decoration: _inputDeco("Select Dept"),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  InputDecoration _inputDeco(String hint, {IconData? icon, String? prefix, String? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      prefixText: prefix,
      suffixText: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Future<void> _saveFaculty() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty || rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
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
        'createdAt': Timestamp.now(),
      });

      await tempApp.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faculty Added Successfully!")));
        Navigator.pushReplacementNamed(context, '/admin/view-faculty');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}