import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

class AdminVerifyAttendancePage extends StatefulWidget {
  const AdminVerifyAttendancePage({super.key});

  @override
  State<AdminVerifyAttendancePage> createState() => _AdminVerifyAttendancePageState();
}

class _AdminVerifyAttendancePageState extends State<AdminVerifyAttendancePage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  final Color successGreen = const Color(0xFF4ADE80);
  final Color pendingOrange = const Color(0xFFFBBF24);
  final Color verifiedBlue = const Color(0xFF60A5FA);

  String _currentFilter = 'Pending';
  String? _searchUid;

  // --- FIREBASE ACTION LOGIC ---
  Future<void> _updateLogStatus(String docId, String newStatus, String facultyName, String uid, String subject, int count) async {
    try {
      await FirebaseFirestore.instance.collection('attendance').doc(docId).update({
        'status': newStatus,
      });

      final notifService = NotificationService();
      if (newStatus == 'Verified') {
        await notifService.sendLogApprovedNotification(uid: uid, count: count, subject: subject);
      } else if (newStatus == 'Rejected') {
        await notifService.sendLogRejectedNotification(uid: uid, subject: subject);
      }

      if (mounted) {
        Color snackColor = newStatus == 'Verified' ? verifiedBlue : (newStatus == 'Rejected' ? primaryRed : successGreen);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Log marked as $newStatus for $facultyName"), backgroundColor: snackColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: primaryRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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

              // Main List Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF242832),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 16),
                        child: _buildFilterTabs(),
                      ),

                      Expanded(
                        child: _buildAttendanceList(),
                      ),
                    ],
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
              Text(_searchUid == null ? "Verify Logs" : "Filtered Logs", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              // ✅ FIXED SEARCH CALL
              onTap: () async {
                final String? selectedUid = await showSearch<String>(
                    context: context,
                    delegate: AttendanceSearchDelegate()
                );
                if (selectedUid != null && selectedUid.isNotEmpty) {
                  setState(() {
                    _searchUid = selectedUid;
                  });
                }
              },
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.search, color: Colors.white, size: 20)
              ),
            ),

            if (_searchUid != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchUid = null;
                  });
                },
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryRed.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Icon(Icons.close, color: primaryRed, size: 20)
                ),
              ),
            ],

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
                    onTap: () => Navigator.pushReplacementNamed(context, '/admin/profile'),
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

  Widget _buildFilterTabs() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF2A2E39), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(
        children: [
          _buildTab("Pending", pendingOrange),
          _buildTab("Verified", verifiedBlue),
          _buildTab("Paid", successGreen),
          _buildTab("All", Colors.white),
        ],
      ),
    );
  }

  Widget _buildTab(String title, Color activeColor) {
    bool isActive = _currentFilter == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentFilter = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isActive ? activeColor.withValues(alpha: 0.5) : Colors.transparent),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(color: isActive ? activeColor : Colors.white.withValues(alpha: 0.5), fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    Query query = FirebaseFirestore.instance.collection('attendance');

    if (_currentFilter != 'All') {
      query = query.where('status', isEqualTo: _currentFilter);
    }

    if (_searchUid != null) {
      query = query.where('uid', isEqualTo: _searchUid);
    }

    return RefreshIndicator(
      color: primaryRed,
      backgroundColor: const Color(0xFF2A2E39),
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 1200));
        setState(() {});
      },
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryRed));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading data", style: TextStyle(color: primaryRed)));
          }

          List<QueryDocumentSnapshot> docs = snapshot.data!.docs.toList();

          if (docs.isEmpty) {
            return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.check_circle_outline, size: 60, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Center(child: Text("No logs found.", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.bold))),
                ]
            );
          }

          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            Timestamp? aTime = aData['date'] as Timestamp?;
            Timestamp? bTime = bData['date'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String uid = data['uid'] ?? '';
              final String subject = data['subject'] ?? '-';
              final int count = data['lectures'] ?? 0;
              final String status = data['status'] ?? 'Pending';

              final dateVal = data['date'];
              DateTime date = (dateVal is Timestamp) ? dateVal.toDate() : DateTime.now();
              final String formattedDate = DateFormat('MMM dd, yyyy').format(date);

              return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                  builder: (context, userSnap) {
                    String name = "Loading...";
                    String? avatarBase64;
                    bool isDeleted = false;

                    if (userSnap.connectionState == ConnectionState.done) {
                      if (!userSnap.hasData || !userSnap.data!.exists) {
                        name = "Deleted Faculty";
                        isDeleted = true;
                      } else {
                        final userData = userSnap.data!.data() as Map<String, dynamic>?;
                        name = userData?['name'] ?? 'Unknown';
                        avatarBase64 = userData?['avatarBase64'];
                      }
                    }

                    return _buildLogCard(doc.id, name, subject, count, formattedDate, status, avatarBase64, isDeleted, uid);
                  }
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLogCard(String docId, String name, String subject, int count, String date, String status, String? avatarBase64, bool isDeleted, String uid) {
    Color statusColor = pendingOrange;
    if (status == 'Verified') statusColor = verifiedBlue;
    if (status == 'Paid') statusColor = successGreen;
    if (status == 'Rejected') statusColor = primaryRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2E39),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF4A5060),
                  backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
                  child: (avatarBase64 == null || avatarBase64.isEmpty)
                      ? Icon(isDeleted ? Icons.person_off : Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(color: isDeleted ? primaryRed : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("$count Lecture(s) • $subject", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text("Date: $date", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                )
              ],
            ),

            if (status == 'Pending' && !isDeleted) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _updateLogStatus(docId, "Rejected", name, uid, subject, count),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: primaryRed.withValues(alpha: 0.5)),
                        ),
                        child: Center(child: Text("Reject", style: TextStyle(color: primaryRed, fontSize: 13, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _updateLogStatus(docId, "Verified", name, uid, subject, count),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: verifiedBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: verifiedBlue.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, color: verifiedBlue, size: 16),
                            const SizedBox(width: 6),
                            Text("Approve", style: TextStyle(color: verifiedBlue, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}

// ✅ FIXED: Extending SearchDelegate<String> and returning empty string instead of null
class AttendanceSearchDelegate extends SearchDelegate<String> {
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
        close(context, ''); // ✅ Fixes Type Error
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
        child: Text("Search a faculty name to filter their logs...", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
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
                close(context, data['uid'] ?? docs[index].id); // ✅ Returns strict String
              },
            );
          },
        );
      },
    );
  }
}