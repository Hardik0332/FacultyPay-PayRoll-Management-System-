import 'package:animations/animations.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notifications_page.dart';
import '../../widgets/notification_badge.dart';
import '../../theme/theme_manager.dart';

class AddAttendancePage extends StatefulWidget {
  const AddAttendancePage({super.key});

  @override
  State<AddAttendancePage> createState() => _AddAttendancePageState();
}

class _AddAttendancePageState extends State<AddAttendancePage> {
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;

  // Form State
  List<Map<String, dynamic>> lectures = [
    {'class': null, 'subject': null, 'customClass': null, 'customSubject': null}
  ];

  final Map<String, List<String>> courseCurriculum = {
    'BSC.CS': ['Java Programming', 'Data Structures', 'Python', 'Web Development', 'Operating Systems'],
    'BCA': ['C Programming', 'Database (DBMS)', 'Networking', 'Mathematics', 'Software Engineering'],
    'B.Sc IT': ['Cyber Security', 'Cloud Computing', 'IoT', 'Web Technologies'],
    'B.Com': ['Accounting', 'Economics', 'Business Law', 'Taxation'],
    'B.A': ['History', 'Political Science', 'English Literature', 'Sociology'],
  };

  // --- FIREBASE SUBMIT LOGIC ---
  Future<void> _submitAllAttendance() async {
    final colors = ThemeManager.instance.colors; // Grab colors for Snackbars

    for (var l in lectures) {
      if (l['class'] == null || l['subject'] == null) {
        _showSnackBar("Please complete all dropdowns", colors.error);
        return;
      }
      if (l['class'] == 'Other' && (l['customClass'] == null || l['customClass'].toString().trim().isEmpty)) {
        _showSnackBar("Please type your custom class name", colors.error);
        return;
      }
      if (l['subject'] == 'Other' && (l['customSubject'] == null || l['customSubject'].toString().trim().isEmpty)) {
        _showSnackBar("Please type your custom subject name", colors.error);
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Not logged in");

      final collection = FirebaseFirestore.instance.collection('attendance');
      final batch = FirebaseFirestore.instance.batch();

      Map<String, int> lectureCounts = {};

      for (var l in lectures) {
        String finalClass = l['class'] == 'Other' ? l['customClass'].toString().trim() : l['class'];
        String finalSubject = l['subject'] == 'Other' ? l['customSubject'].toString().trim() : l['subject'];

        String key = "$finalClass - $finalSubject";
        lectureCounts[key] = (lectureCounts[key] ?? 0) + 1;
      }

      for (var entry in lectureCounts.entries) {
        String subjectKey = entry.key;
        int count = entry.value;

        // Check for duplicates
        final existingCheck = await collection
            .where('uid', isEqualTo: user.uid)
            .where('date', isEqualTo: Timestamp.fromDate(selectedDate))
            .where('subject', isEqualTo: subjectKey)
            .get();

        if (existingCheck.docs.isNotEmpty) {
          if (mounted) _showSnackBar("Warning: $subjectKey was already submitted today!", colors.warning);
          setState(() => isLoading = false);
          return;
        }

        final docRef = collection.doc();
        batch.set(docRef, {
          'uid': user.uid,
          'date': Timestamp.fromDate(selectedDate),
          'subject': subjectKey,
          'lectures': count,
          'status': 'Pending',
          'submittedAt': Timestamp.now(),
        });
      }

      await batch.commit();

      if (mounted) {
        _showSnackBar("Attendance Submitted Successfully", colors.success);
        setState(() {
          lectures = [{'class': null, 'subject': null, 'customClass': null, 'customSubject': null}];
        });
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error: $e", colors.error);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _pickDate(AppColors colors, bool isDark) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(primary: colors.primary, onPrimary: Colors.white, surface: colors.card, onSurface: colors.textMain)
                : ColorScheme.light(primary: colors.primary, onPrimary: Colors.white, surface: colors.card, onSurface: colors.textMain),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: _buildHeader(colors, isDark),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildDateSelectorCard(colors, isDark),
                        ),
                        const SizedBox(height: 24),

                        // Main Content Area (Form & History)
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
                            decoration: BoxDecoration(
                              color: isDark ? colors.card : Colors.transparent, // Floating list on light mode
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                              boxShadow: isDark ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -5))] : [],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 120),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Record Lectures", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textMain)),
                                  const SizedBox(height: 4),
                                  Text("Select the class and subject for each lecture conducted.", style: TextStyle(color: colors.textMuted, fontSize: 13)),
                                  const SizedBox(height: 20),

                                  // Dynamic Lecture Forms
                                  ...lectures.asMap().entries.map((entry) => _buildLectureForm(entry.key, entry.value, colors, isDark)),

                                  // Add Another Lecture Button
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          lectures.add({'class': null, 'subject': null, 'customClass': null, 'customSubject': null});
                                        });
                                      },
                                      icon: Icon(Icons.add_circle_outline, color: colors.primary, size: 20),
                                      label: Text("Add Another Lecture", style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Submit Button
                                  _buildSubmitButton(colors),

                                  const SizedBox(height: 40),
                                  Container(height: 1, color: colors.textMain.withValues(alpha: 0.1)),
                                  const SizedBox(height: 30),

                                  // Recent Submissions Section
                                  Text("Recent Submissions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textMain)),
                                  const SizedBox(height: 16),

                                  // FIREBASE HISTORY INJECTED HERE
                                  _buildFirebaseHistoryList(colors, isDark),
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
            child: Text(
                "Log Hours",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colors.textMain, letterSpacing: -0.5),
                overflow: TextOverflow.ellipsis
            )
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
            const SizedBox(width: 12),

            Container(
              decoration: BoxDecoration(color: isDark ? Colors.transparent : colors.textMuted.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const NotificationBadge(),
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
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/faculty/profile');
                    },
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

  Widget _buildDateSelectorCard(AppColors colors, bool isDark) {
    return GestureDetector(
      onTap: () => _pickDate(colors, isDark),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.cardHighlight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? colors.textMain.withValues(alpha: 0.1) : Colors.transparent),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3))
              ),
              child: Icon(Icons.calendar_month, color: colors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("DATE OF LECTURES", style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(DateFormat('EEEE, MMM dd, yyyy').format(selectedDate), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textMain)),
                ],
              ),
            ),
            Icon(Icons.edit, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureForm(int index, Map<String, dynamic> lecture, AppColors colors, bool isDark) {
    List<String> classOptions = [...courseCurriculum.keys, 'Other'];
    List<String> availableSubjects = (lecture['class'] != null && lecture['class'] != 'Other') ? courseCurriculum[lecture['class']] ?? [] : [];
    List<String> subjectOptions = lecture['class'] != null ? [...availableSubjects, 'Other'] : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? colors.textMain.withValues(alpha: 0.05) : Colors.transparent),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Lecture ${index + 1}", style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold, fontSize: 14)),
              if (lectures.length > 1)
                GestureDetector(
                  onTap: () => setState(() => lectures.removeAt(index)),
                  child: Icon(Icons.delete_outline, color: colors.error, size: 20),
                )
            ],
          ),
          const SizedBox(height: 16),

          _buildDropdown("Class", lecture['class'], classOptions, colors, isDark, (val) {
            setState(() { lecture['class'] = val; lecture['subject'] = null; if (val != 'Other') lecture['customClass'] = null; });
          }),

          if (lecture['class'] == 'Other') ...[
            const SizedBox(height: 12),
            _buildTextField("Custom Class Name", colors, isDark, (val) => lecture['customClass'] = val, lecture['customClass']),
          ],

          const SizedBox(height: 16),

          _buildDropdown("Subject", lecture['subject'], subjectOptions, colors, isDark, hint: "Select Class first", (val) {
            setState(() { lecture['subject'] = val; if (val != 'Other') lecture['customSubject'] = null; });
          }),

          if (lecture['subject'] == 'Other') ...[
            const SizedBox(height: 12),
            _buildTextField("Custom Subject Name", colors, isDark, (val) => lecture['customSubject'] = val, lecture['customSubject']),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, AppColors colors, bool isDark, void Function(String?)? onChanged, {String? hint}) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: colors.card,
      style: TextStyle(color: colors.textMain, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textMuted),
        filled: true,
        fillColor: isDark ? colors.textMain.withValues(alpha: 0.03) : colors.bgTop,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? colors.textMain.withValues(alpha: 0.1) : Colors.transparent)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.textMain.withValues(alpha: 0.05))),
      ),
      disabledHint: hint != null ? Text(hint, style: TextStyle(color: colors.textMuted.withValues(alpha: 0.5))) : null,
      icon: Icon(Icons.arrow_drop_down, color: colors.textMuted),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(String label, AppColors colors, bool isDark, void Function(String) onChanged, String? initialValue) {
    return TextFormField(
      initialValue: initialValue,
      style: TextStyle(color: colors.textMain, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textMuted),
        filled: true,
        fillColor: isDark ? colors.textMain.withValues(alpha: 0.03) : colors.bgTop,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? colors.textMain.withValues(alpha: 0.1) : Colors.transparent)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary, width: 1.5)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildSubmitButton(AppColors colors) {
    return GestureDetector(
      onTap: isLoading ? null : _submitAllAttendance,
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
              : const Text("Submit Attendance", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),
    );
  }

  // --- FIREBASE HISTORY STREAM ---
  Widget _buildFirebaseHistoryList(AppColors colors, bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: colors.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading history", style: TextStyle(color: colors.error)));
        }

        final docs = snapshot.data?.docs.toList() ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text("No recent submissions.", style: TextStyle(color: colors.textMuted)),
          );
        }

        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          Timestamp? aTime = aData['submittedAt'] as Timestamp?;
          Timestamp? bTime = bData['submittedAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        final recentDocs = docs.take(10).toList();

        return Stack(
          children: [
            Positioned(
              left: 36, top: 30, bottom: 30,
              child: Container(width: 2, color: isDark ? colors.textMain.withValues(alpha: 0.1) : const Color(0xFF2F6B4F)),
            ),
            ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentDocs.length,
              itemBuilder: (context, index) {
                final data = recentDocs[index].data() as Map<String, dynamic>;
                final dateVal = data['date'] as Timestamp?;
                final date = dateVal?.toDate() ?? DateTime.now();
                final subject = data['subject'] ?? 'Unknown';
                final count = data['lectures'] ?? 0;
                final status = data['status'] ?? 'Pending';

                Color textColor = colors.warning;
                Color bgColor = colors.warningBg;
                IconData icon = Icons.history_edu;

                if (status == 'Verified' || status == 'Paid') {
                  textColor = colors.success;
                  bgColor = colors.successBg;
                  icon = Icons.check_circle;
                } else if (status == 'Rejected') {
                  textColor = colors.error;
                  bgColor = colors.error.withValues(alpha: 0.1);
                  icon = Icons.error;
                } else {
                  textColor = colors.processing;
                  bgColor = colors.processingBg;
                }

                return _buildSubmissionItem(
                    icon,
                    DateFormat('MMM dd, yyyy').format(date),
                    subject,
                    count,
                    status.toUpperCase(),
                    textColor,
                    bgColor,
                    colors,
                    isDark
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubmissionItem(IconData icon, String date, String subject, int count, String status, Color textColor, Color bgColor, AppColors colors, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? colors.textMain.withValues(alpha: 0.05) : Colors.transparent),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: isDark ? colors.textMain.withValues(alpha: 0.1) : colors.primary, shape: BoxShape.circle),
              child: Icon(icon, color: isDark ? colors.textMain : Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: TextStyle(color: colors.textMain, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text("$count Lecture(s) • $subject", style: TextStyle(color: colors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? textColor.withValues(alpha: 0.3) : Colors.transparent),
              ),
              child: Text(status, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}
