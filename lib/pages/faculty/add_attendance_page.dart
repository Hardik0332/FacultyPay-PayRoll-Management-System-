import 'dart:ui';
import 'dart:convert'; // Added to decode the base64 image
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notifications_page.dart';

class AddAttendancePage extends StatefulWidget {
  const AddAttendancePage({super.key});

  @override
  State<AddAttendancePage> createState() => _AddAttendancePageState();
}

class _AddAttendancePageState extends State<AddAttendancePage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  final Color successGreen = const Color(0xFF4ADE80);
  final Color pendingOrange = const Color(0xFFFBBF24);
  final Color verifiedBlue = const Color(0xFF60A5FA);

  int _currentNavIndex = 1; // STAFF / ATTENDANCE tab
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
    for (var l in lectures) {
      if (l['class'] == null || l['subject'] == null) {
        _showSnackBar("Please complete all dropdowns", primaryRed);
        return;
      }
      if (l['class'] == 'Other' && (l['customClass'] == null || l['customClass'].toString().trim().isEmpty)) {
        _showSnackBar("Please type your custom class name", primaryRed);
        return;
      }
      if (l['subject'] == 'Other' && (l['customSubject'] == null || l['customSubject'].toString().trim().isEmpty)) {
        _showSnackBar("Please type your custom subject name", primaryRed);
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
          if (mounted) _showSnackBar("Warning: $subjectKey was already submitted today!", pendingOrange);
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
        _showSnackBar("Attendance Submitted Successfully", successGreen);
        setState(() {
          lectures = [{'class': null, 'subject': null, 'customClass': null, 'customSubject': null}];
        });
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error: $e", primaryRed);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryRed,
              onPrimary: Colors.white,
              surface: const Color(0xFF282C37),
              onSurface: Colors.white,
            ),
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
    return Scaffold(
      backgroundColor: const Color(0xFF282C37),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3B4154), Color(0xFF1E212A)],
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: _buildHeader(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildDateSelectorCard(),
                ),
                const SizedBox(height: 24),

                // Main Content Area (Form & History)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF242832),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120), // Space for bottom nav
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Record Lectures", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text("Select the class and subject for each lecture conducted.", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                          const SizedBox(height: 20),

                          // Dynamic Lecture Forms
                          ...lectures.asMap().entries.map((entry) => _buildLectureForm(entry.key, entry.value)),

                          // Add Another Lecture Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  lectures.add({'class': null, 'subject': null, 'customClass': null, 'customSubject': null});
                                });
                              },
                              icon: Icon(Icons.add_circle_outline, color: primaryRed, size: 20),
                              label: Text("Add Another Lecture", style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold)),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Submit Button
                          _buildSubmitButton(),

                          const SizedBox(height: 40),
                          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 30),

                          // Recent Submissions Section
                          const Text("Recent Submissions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 16),

                          // FIREBASE HISTORY INJECTED HERE
                          _buildFirebaseHistoryList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Bottom Navigation
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: _buildFloatingBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text("Log Hours", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5), overflow: TextOverflow.ellipsis)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---> CLICKABLE NOTIFICATION BUTTON <---
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryRed, shape: BoxShape.circle),
                child: const Icon(Icons.notifications, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            // UPDATED: Added StreamBuilder to fetch avatar
            StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
                builder: (context, snapshot) {
                  String? avatarBase64;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    avatarBase64 = data?['avatarBase64'];
                  }
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
                    child: (avatarBase64 == null || avatarBase64.isEmpty) ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
                  );
                }
            ),
          ],
        )
      ],
    );
  }

  Widget _buildDateSelectorCard() {
    return GestureDetector(
      onTap: _pickDate,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primaryRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: primaryRed.withValues(alpha: 0.5))),
                  child: Icon(Icons.calendar_month, color: primaryRed, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("DATE OF LECTURES", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(DateFormat('EEEE, MMM dd, yyyy').format(selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                Icon(Icons.edit, color: Colors.white.withValues(alpha: 0.5), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLectureForm(int index, Map<String, dynamic> lecture) {
    List<String> classOptions = [...courseCurriculum.keys, 'Other'];
    List<String> availableSubjects = (lecture['class'] != null && lecture['class'] != 'Other') ? courseCurriculum[lecture['class']] ?? [] : [];
    List<String> subjectOptions = lecture['class'] != null ? [...availableSubjects, 'Other'] : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2E39),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Lecture ${index + 1}", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.bold, fontSize: 14)),
              if (lectures.length > 1)
                GestureDetector(
                  onTap: () => setState(() => lectures.removeAt(index)),
                  child: Icon(Icons.delete_outline, color: primaryRed.withValues(alpha: 0.8), size: 20),
                )
            ],
          ),
          const SizedBox(height: 16),

          _buildDropdown("Class", lecture['class'], classOptions, (val) {
            setState(() { lecture['class'] = val; lecture['subject'] = null; if (val != 'Other') lecture['customClass'] = null; });
          }),

          if (lecture['class'] == 'Other') ...[
            const SizedBox(height: 12),
            _buildTextField("Custom Class Name", (val) => lecture['customClass'] = val, lecture['customClass']),
          ],

          const SizedBox(height: 16),

          _buildDropdown("Subject", lecture['subject'], subjectOptions, hint: "Select Class first", (val) {
            setState(() { lecture['subject'] = val; if (val != 'Other') lecture['customSubject'] = null; });
          }),

          if (lecture['subject'] == 'Other') ...[
            const SizedBox(height: 12),
            _buildTextField("Custom Subject Name", (val) => lecture['customSubject'] = val, lecture['customSubject']),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, void Function(String?)? onChanged, {String? hint}) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF2A2E39),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryRed, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      disabledHint: hint != null ? Text(hint, style: TextStyle(color: Colors.white.withValues(alpha: 0.3))) : null,
      icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.5)),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(String label, void Function(String) onChanged, String? initialValue) {
    return TextFormField(
      initialValue: initialValue,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryRed, width: 1.5)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: isLoading ? null : _submitAllAttendance,
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
              : const Text("Submit Attendance", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),
    );
  }

  // --- FIREBASE HISTORY STREAM ---
  Widget _buildFirebaseHistoryList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryRed));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading history", style: TextStyle(color: primaryRed)));
        }

        final docs = snapshot.data?.docs.toList() ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text("No recent submissions.", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          );
        }

        // Matching your old code's logic to sort by submittedAt manually
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          Timestamp? aTime = aData['submittedAt'] as Timestamp?;
          Timestamp? bTime = bData['submittedAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        final recentDocs = docs.take(10).toList();

        // Used shrinkWrap: true and NeverScrollableScrollPhysics so it scrolls perfectly inside the main page
        return ListView.builder(
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

            Color statusColor = pendingOrange;
            if (status == 'Verified') statusColor = verifiedBlue;
            if (status == 'Paid') statusColor = successGreen;

            return _buildSubmissionItem(
              DateFormat('MMM dd, yyyy').format(date),
              subject,
              count,
              status,
              statusColor,
            );
          },
        );
      },
    );
  }

  Widget _buildSubmissionItem(String date, String subject, int count, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF2A2E39), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(color: Color(0xFF4A5060), shape: BoxShape.circle),
              child: const Icon(Icons.history_edu, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text("$count Lecture(s) • $subject", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
              child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBottomNav() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home, "HOME", 0),
              _buildNavItem(Icons.edit_document, "LOG", 1),
              _buildNavItem(Icons.account_balance_wallet, "PAY", 2),
              _buildNavItem(Icons.person, "MY PROFILE", 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _currentNavIndex == index;
    final color = isActive ? primaryRed : Colors.white.withValues(alpha: 0.4);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentNavIndex = index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                  label,
                  style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis
              ),
              if (isActive)
                Container(
                    margin: const EdgeInsets.only(top: 4),
                    height: 3,
                    width: 20,
                    decoration: BoxDecoration(
                        color: primaryRed,
                        borderRadius: BorderRadius.circular(2)
                    )
                )
            ],
          ),
        ),
      ),
    );
  }
}