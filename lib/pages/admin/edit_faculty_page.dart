import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/theme_manager.dart'; // ✅ Added ThemeManager

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

  Future<void> updateFaculty(AppColors colors) async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Please fill all required fields"), backgroundColor: colors.error));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Faculty updated successfully"), backgroundColor: colors.success));
        Navigator.pop(context); // Go back to View Faculty
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

          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                backgroundColor: colors.bgBottom,
                body: Stack(
                  children: [
                    // 1. Background Gradient
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
                                    color: colors.card,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                                    boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
                                  ),
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 80),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Edit Faculty Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textMain)),
                                        const SizedBox(height: 4),
                                        Text("Update information for ${widget.facultyData['name']}.", style: TextStyle(color: colors.textMuted, fontSize: 13)),
                                        const SizedBox(height: 24),

                                        // Forms
                                        _buildEditableField("Full Name", Icons.person_outline, nameController, "e.g. Dr. Sarah Connor", colors, isDark),
                                        const SizedBox(height: 16),
                                        _buildEditableField("Email Address (Cannot be changed)", Icons.email_outlined, emailController, "faculty@university.edu", colors, isDark, isReadOnly: true),

                                        const SizedBox(height: 32),
                                        Container(height: 1, color: colors.textMain.withValues(alpha: 0.1)),
                                        const SizedBox(height: 24),

                                        const Text("Payment & Department", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                ),
              ),
            ),
          );
        }
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader(AppColors colors, bool isDark) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: isDark ? colors.textMain.withValues(alpha: 0.05) : colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)
            ),
            child: Icon(Icons.arrow_back_ios_new, color: colors.textMain, size: 18),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Admin Action", style: TextStyle(color: primaryRed, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text("Edit Profile", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colors.textMain, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        // Sun/Moon Toggle
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
      ],
    );
  }

  Widget _buildEditableField(String label, IconData icon, TextEditingController controller, String hint, AppColors colors, bool isDark, {bool isReadOnly = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          keyboardType: keyboardType,
          style: TextStyle(color: isReadOnly ? colors.textMuted : colors.textMain, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: colors.textMuted, size: 20),
            filled: true,
            fillColor: isReadOnly
                ? (isDark ? colors.textMain.withValues(alpha: 0.02) : colors.bgBottom)
                : (isDark ? colors.textMain.withValues(alpha: 0.03) : colors.bgTop),
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
          value: selectedDepartment,
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
      onTap: isLoading ? null : () => updateFaculty(colors),
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
              : const Text("Update Faculty", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),
    );
  }
}