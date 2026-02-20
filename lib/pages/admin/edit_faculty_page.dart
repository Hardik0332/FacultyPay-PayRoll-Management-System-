import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/app_sidebars.dart';

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
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController rateController;
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
    selectedDepartment = widget.facultyData['department'];
  }

  Future<void> updateFaculty() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
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
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Faculty updated successfully")),
        );
        Navigator.pop(context); // go back to View Faculty
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
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
        title: const Text("Edit Faculty"),
        elevation: 0,
      ),
      drawer: isDesktop
          ? null
          : const Drawer(
        child: AdminSidebar(activeRoute: '/admin/view-faculty'),
      ),
      body: Row(
        children: [
          if (isDesktop) const AdminSidebar(activeRoute: '/admin/view-faculty'),

          Expanded(
            // ✅ ONLY ADDED REFRESH INDICATOR HERE
            child: RefreshIndicator(
              color: theme.primaryColor,
              backgroundColor: theme.cardColor,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 600));
                setState(() {
                  _initializeForm();
                });
              },
              child: SingleChildScrollView(
                // ✅ ADDED PHYSICS FOR SCROLLING
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 40 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Back Button
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text("Edit Faculty Member", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // FORM CONTAINER
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

                          _buildLabel("Email Address (Cannot be changed)"),
                          TextField(controller: emailController, readOnly: true, decoration: _inputDeco("faculty@university.edu", icon: Icons.email_outlined)),
                          const SizedBox(height: 24),

                          // RESPONSIVE ROW FOR RATE AND DEPARTMENT
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildRateField()),
                                const SizedBox(width: 24),
                                Expanded(child: _buildDeptField(theme)), // Pass theme
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRateField(),
                                const SizedBox(height: 24),
                                _buildDeptField(theme), // Pass theme
                              ],
                            ),

                          const SizedBox(height: 40),
                          const Divider(),
                          const SizedBox(height: 20),

                          // Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: isLoading ? null : updateFaculty,
                                icon: isLoading ? const SizedBox() : const Icon(Icons.save),
                                label: Text(isLoading ? "Saving..." : "Update Faculty"),
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

  // Helpers for Styling
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
}