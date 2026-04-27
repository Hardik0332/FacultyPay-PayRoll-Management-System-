import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditFacultyPage extends StatefulWidget {
  final String facultyId;
  final Map<String, dynamic> facultyData;

  const EditFacultyPage({
    super.key,
    required this.facultyId,
    required this.facultyData,
  });

  @override
  State<EditFacultyPage> createState() => _EditFacultyPageState();
}

class _EditFacultyPageState extends State<EditFacultyPage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  final Color successGreen = const Color(0xFF4ADE80);
  final Color verifiedBlue = const Color(0xFF60A5FA);

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController rateController;
  late TextEditingController upiController;
  String? selectedDepartment;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    nameController = TextEditingController(text: widget.facultyData['name']);
    emailController = TextEditingController(text: widget.facultyData['email']);
    rateController = TextEditingController(text: widget.facultyData['hourlyRate'].toString());
    upiController = TextEditingController(text: widget.facultyData['upiId'] ?? '');
    selectedDepartment = widget.facultyData['department'];
  }

  Future<void> updateFaculty() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Please fill all required fields"), backgroundColor: primaryRed));
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.facultyId)
          .update({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'hourlyRate': double.parse(rateController.text),
        'department': selectedDepartment,
        'upiId': upiController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Faculty updated successfully"), backgroundColor: successGreen));
        Navigator.pop(context); // Go back to View Faculty
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: primaryRed));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // ✅ Scaffold kept for back-navigation support
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
                      // Extra bottom padding helps ensure the Save button isn't covered by the keyboard
                      padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Edit Faculty Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text("Update information for ${widget.facultyData['name']}.", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                          const SizedBox(height: 24),

                          // Forms
                          _buildEditableField("Full Name", Icons.person_outline, nameController, "e.g. Dr. Sarah Connor"),
                          const SizedBox(height: 16),
                          _buildEditableField("Email Address (Cannot be changed)", Icons.email_outlined, emailController, "faculty@university.edu", isReadOnly: true),

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
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Admin Action", style: TextStyle(color: verifiedBlue, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              const Text("Edit Profile", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, IconData icon, TextEditingController controller, String hint, {bool isReadOnly = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          keyboardType: keyboardType,
          style: TextStyle(color: isReadOnly ? Colors.white.withValues(alpha: 0.5) : Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
            filled: true,
            fillColor: isReadOnly ? Colors.white.withValues(alpha: 0.02) : const Color(0xFF2A2E39),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: verifiedBlue, width: 1.5)),
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
          isExpanded: true, // ✅ FIXED OVERFLOW: Forces the dropdown to stay inside its boundaries
          dropdownColor: const Color(0xFF2A2E39),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.5)),
          items: const [
            // ✅ FIXED OVERFLOW: Added TextOverflow.ellipsis
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
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: verifiedBlue, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: isLoading ? null : updateFaculty,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isLoading ? verifiedBlue.withValues(alpha: 0.5) : verifiedBlue,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: verifiedBlue.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Update Faculty", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),
    );
  }
}