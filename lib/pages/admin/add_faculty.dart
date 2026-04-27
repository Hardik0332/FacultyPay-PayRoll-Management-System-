import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminAddFacultyPage extends StatefulWidget {
  const AdminAddFacultyPage({super.key});

  @override
  State<AdminAddFacultyPage> createState() => _AdminAddFacultyPageState();
}

class _AdminAddFacultyPageState extends State<AdminAddFacultyPage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  final Color successGreen = const Color(0xFF4ADE80);
  final Color pendingOrange = const Color(0xFFFBBF24);
  final Color verifiedBlue = const Color(0xFF60A5FA);

  // --- CONTROLLERS & STATE ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController upiController = TextEditingController();
  String? selectedDepartment;
  bool isLoading = false;

  // --- FIREBASE SUBMIT LOGIC ---
  Future<void> _saveFaculty() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty || rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Please fill all required fields"), backgroundColor: primaryRed));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Faculty Added Successfully!"), backgroundColor: successGreen));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: primaryRed));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack( // ✅ REMOVED SCAFFOLD, wrapped in Stack
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

              // Main Form Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF242832),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    // ✅ CRITICAL FIX: 120px bottom padding to clear the nav bar!
                    padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Faculty Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text("Onboard a new faculty member to the system.", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                        const SizedBox(height: 24),

                        // Forms
                        _buildEditableField("Full Name", Icons.person_outline, nameController, "e.g. Dr. Sarah Connor"),
                        const SizedBox(height: 16),
                        _buildEditableField("Email Address", Icons.email_outlined, emailController, "faculty@university.edu", keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        _buildEditableField("Set Password", Icons.lock_outline, passwordController, "Login password", isPassword: true),

                        const SizedBox(height: 32),
                        Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 24),

                        const Text("Payment & Department", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(child: _buildEditableField("Hourly Rate", Icons.currency_rupee, rateController, "0.00", keyboardType: TextInputType.number)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDepartmentDropdown()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildEditableField("UPI ID (Optional)", Icons.qr_code, upiController, "e.g. john@ybl"),

                        const SizedBox(height: 40),

                        // Save Button
                        _buildSaveButton(),
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
              const Text("Add Faculty", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ FIXED SEARCH BUTTON
            GestureDetector(
              onTap: () {
                showSearch(context: context, delegate: FacultySearchDelegate());
              },
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.search, color: Colors.white, size: 20)
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
                    onTap: () => Navigator.pushReplacementNamed(context, '/admin/profile'), // ✅ FIXED ROUTE
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
                      child: (avatarBase64 == null || avatarBase64.isEmpty) ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
                    ),
                  );
                }
            ),
          ],
        )
      ],
    );
  }

  Widget _buildEditableField(String label, IconData icon, TextEditingController controller, String hint, {bool isPassword = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
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

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Department", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedDepartment,
          isExpanded: true,
          dropdownColor: const Color(0xFF2A2E39),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.5)),
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
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            prefixIcon: Icon(Icons.business, color: Colors.white.withValues(alpha: 0.5), size: 20),
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

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: isLoading ? null : _saveFaculty,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isLoading ? primaryRed.withValues(alpha: 0.5) : primaryRed,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: primaryRed.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
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

// ✅ NEW: Added FacultySearchDelegate to allow searching from the Add Faculty Page
class FacultySearchDelegate extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF242832),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      scaffoldBackgroundColor: const Color(0xFF282C37),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            query = '';
          },
        )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(
        child: Text("Search existing faculty...", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'faculty').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE05B5C)));
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
            child: Text("No faculty found matching '$query'.", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unknown';
            final email = data['email'] ?? 'No email';
            final avatarBase64 = data['avatarBase64'];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
                child: (avatarBase64 == null || avatarBase64.isEmpty) ? const Icon(Icons.person, color: Colors.white) : null,
              ),
              title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
              onTap: () {
                close(context, data['uid'] ?? docs[index].id);
              },
            );
          },
        );
      },
    );
  }
}