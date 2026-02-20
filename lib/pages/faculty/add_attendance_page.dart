import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_sidebars.dart';

class FacultyAddAttendancePage extends StatefulWidget {
  const FacultyAddAttendancePage({super.key});

  @override
  State<FacultyAddAttendancePage> createState() => _FacultyAddAttendancePageState();
}

class _FacultyAddAttendancePageState extends State<FacultyAddAttendancePage> {
  DateTime? selectedDate;
  bool isLoading = false;

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

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
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
        title: const Text("Add Attendance"),
        elevation: 0,
      ),
      drawer: isDesktop
          ? null
          : const Drawer(
        child: FacultySidebar(activeRoute: '/faculty/add-attendance'),
      ),
      body: Row(
        children: [
          if (isDesktop) const FacultySidebar(activeRoute: '/faculty/add-attendance'),

          Expanded(
            // ✅ REFRESH INDICATOR APPLIED HERE
            child: RefreshIndicator(
              color: theme.primaryColor,
              backgroundColor: theme.cardColor,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 1200));
                // Optional: Force a state rebuild if you want the date to reset, etc.
                setState(() {});
              },
              child: SingleChildScrollView(
                // ✅ ALWAYS SCROLLABLE
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 40 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Record Daily Attendance", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Select your class and subject for each lecture conducted.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 32),

                    // --- FORM CONTAINER ---
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
                          const Text("Date of Lectures *", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.withOpacity(0.4)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedDate == null ? "Select Date" : DateFormat('EEEE, MMM dd, yyyy').format(selectedDate!),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text("Lecture Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),

                          ...lectures.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> lecture = entry.value;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 12, right: 16),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), shape: BoxShape.circle),
                                    child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Expanded(child: _buildLectureFields(index, lecture, theme, isDesktop)),
                                  if (lectures.length > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4, left: 8),
                                      child: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => setState(() => lectures.removeAt(index)),
                                      ),
                                    )
                                ],
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => setState(() => lectures.add({'class': null, 'subject': null, 'customClass': null, 'customSubject': null})),
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xff45a182)),
                            label: const Text("Add Another Lecture", style: TextStyle(color: Color(0xff45a182), fontWeight: FontWeight.bold)),
                          ),

                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),

                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff45a182),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              ),
                              icon: isLoading ? const SizedBox() : const Icon(Icons.check_circle),
                              label: Text(isLoading ? "Submitting..." : "Submit Attendance", style: const TextStyle(fontSize: 16, color: Colors.white)),
                              onPressed: isLoading ? null : _submitAllAttendance,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    const Text("Recent Submissions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildRecentSubmissions(theme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildLectureFields(int index, Map<String, dynamic> lecture, ThemeData theme, bool isDesktop) {
    List<String> availableSubjects = (lecture['class'] != null && lecture['class'] != 'Other')
        ? courseCurriculum[lecture['class']] ?? []
        : [];

    List<String> classOptions = [...courseCurriculum.keys, 'Other'];
    List<String> subjectOptions = lecture['class'] != null ? [...availableSubjects, 'Other'] : [];

    Widget classDropdown = DropdownButtonFormField<String>(
      value: lecture['class'],
      dropdownColor: theme.cardColor,
      decoration: const InputDecoration(labelText: "Class", border: OutlineInputBorder()),
      items: classOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (val) {
        setState(() {
          lecture['class'] = val;
          lecture['subject'] = null;
          if (val != 'Other') lecture['customClass'] = null;
        });
      },
    );

    Widget subjectDropdown = DropdownButtonFormField<String>(
      value: lecture['subject'],
      dropdownColor: theme.cardColor,
      decoration: const InputDecoration(labelText: "Subject", border: OutlineInputBorder()),
      disabledHint: const Text("Select Class first"),
      items: subjectOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: lecture['class'] == null ? null : (val) {
        setState(() {
          lecture['subject'] = val;
          if (val != 'Other') lecture['customSubject'] = null;
        });
      },
    );

    Widget customClassField = lecture['class'] == 'Other' ? Padding(
      padding: EdgeInsets.only(top: isDesktop ? 16 : 0, bottom: isDesktop ? 0 : 16),
      child: TextFormField(
        initialValue: lecture['customClass'],
        decoration: const InputDecoration(labelText: "Enter Custom Class Name", border: OutlineInputBorder()),
        onChanged: (val) => lecture['customClass'] = val,
      ),
    ) : const SizedBox.shrink();

    Widget customSubjectField = lecture['subject'] == 'Other' ? Padding(
      padding: EdgeInsets.only(top: isDesktop ? 16 : 0),
      child: TextFormField(
        initialValue: lecture['customSubject'],
        decoration: const InputDecoration(labelText: "Enter Custom Subject Name", border: OutlineInputBorder()),
        onChanged: (val) => lecture['customSubject'] = val,
      ),
    ) : const SizedBox.shrink();

    if (isDesktop) {
      return Column(
        children: [
          Row(children: [Expanded(child: classDropdown), const SizedBox(width: 16), Expanded(child: subjectDropdown)]),
          if (lecture['class'] == 'Other' || lecture['subject'] == 'Other')
            Row(
              children: [
                Expanded(child: customClassField),
                if (lecture['class'] == 'Other' && lecture['subject'] == 'Other') const SizedBox(width: 16),
                Expanded(child: customSubjectField),
              ],
            ),
        ],
      );
    } else {
      return Column(
        children: [
          classDropdown,
          const SizedBox(height: 16),
          if (lecture['class'] == 'Other') customClassField,
          subjectDropdown,
          if (lecture['subject'] == 'Other') const SizedBox(height: 16),
          if (lecture['subject'] == 'Other') customSubjectField,
        ],
      );
    }
  }

  Widget _buildRecentSubmissions(ThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text("Error loading history", style: TextStyle(color: theme.textTheme.bodyLarge?.color));
        }

        final docs = snapshot.data?.docs.toList() ?? [];
        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
            child: const Text("No recent submissions.", style: TextStyle(color: Colors.grey)),
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

        final recentDocs = docs.take(5).toList();

        return Column(
          children: recentDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dateVal = data['date'] as Timestamp?;
            final date = dateVal?.toDate() ?? DateTime.now();
            final subject = data['subject'] ?? 'Unknown';
            final lectures = data['lectures'] ?? 0;
            final status = data['status'] ?? 'Pending';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text("$lectures Lecture(s) • $subject", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: status == 'Verified' ? Colors.green.withOpacity(0.1) : (status == 'Paid' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                          color: status == 'Verified' ? Colors.green : (status == 'Paid' ? Colors.blue : Colors.orange),
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // --- LOGIC ---

  Future<void> _submitAllAttendance() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a date")));
      return;
    }

    for (var l in lectures) {
      if (l['class'] == null || l['subject'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please complete all dropdowns")));
        return;
      }
      if (l['class'] == 'Other' && (l['customClass'] == null || l['customClass'].toString().trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please type your custom class name")));
        return;
      }
      if (l['subject'] == 'Other' && (l['customSubject'] == null || l['customSubject'].toString().trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please type your custom subject name")));
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

        final existingCheck = await collection
            .where('uid', isEqualTo: user.uid)
            .where('date', isEqualTo: Timestamp.fromDate(selectedDate!))
            .where('subject', isEqualTo: subjectKey)
            .get();

        if (existingCheck.docs.isNotEmpty) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Warning: $subjectKey was already submitted today!")));
          setState(() => isLoading = false);
          return;
        }

        final docRef = collection.doc();
        batch.set(docRef, {
          'uid': user.uid,
          'date': Timestamp.fromDate(selectedDate!),
          'subject': subjectKey,
          'lectures': count,
          'status': 'Pending',
          'submittedAt': Timestamp.now(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Attendance Submitted Successfully")));
        setState(() {
          lectures = [{'class': null, 'subject': null, 'customClass': null, 'customSubject': null}];
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}