import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final Color primaryRed = const Color(0xFFE05B5C);
  final Color successGreen = const Color(0xFF4ADE80);
  final Color pendingOrange = const Color(0xFFFBBF24);
  final Color verifiedBlue = const Color(0xFF60A5FA);

  @override
  Widget build(BuildContext context) {
    return Stack( // ✅ ADDED: Stack to hold the gradient and content
      children: [
        // ✅ ADDED: Restored the beautiful Background Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3B4154), Color(0xFF1E212A)],
            ),
          ),
        ),

        // Main Scrollable Content
        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: primaryRed,
            backgroundColor: const Color(0xFF242832),
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 1200));
              setState(() {}); // Force rebuild streams
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              // ✅ ADDED: 120px bottom padding so content isn't hidden behind the floating nav
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: _buildHeader(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildMasterCard(),
                  ),
                  const SizedBox(height: 32),

                  // Quick Actions Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 16),

                  // Vertical List of Actions (Long Rectangles)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildQuickActionsList(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- UI COMPONENTS & LOGIC MAPPINGS ---

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Admin Portal", style: TextStyle(color: primaryRed, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              const Text("Command Center", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                showSearch(context: context, delegate: FacultySearchDelegate());
              },
              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.search, color: Colors.white, size: 20)),
            ),
            const SizedBox(width: 12),

            // LIVE AVATAR
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
                      Navigator.pushReplacementNamed(context, '/admin/profile');
                    },
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

  Widget _buildMasterCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryRed.withValues(alpha: 0.3)), // Subtle red border for Admin
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("CURRENT MONTH LIABILITY", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 4),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('attendance').where('status', isEqualTo: 'Verified').snapshots(),
                builder: (context, attendanceSnap) {
                  if (!attendanceSnap.hasData) return const Text("₹...", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white));

                  Map<String, int> pendingLecturesPerUser = {};
                  for (var doc in attendanceSnap.data!.docs) {
                    String uid = doc['uid'];
                    int lectures = doc['lectures'];
                    pendingLecturesPerUser[uid] = (pendingLecturesPerUser[uid] ?? 0) + lectures;
                  }

                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'faculty').get(),
                    builder: (context, usersSnap) {
                      double totalPendingAmount = 0.0;
                      if (usersSnap.hasData) {
                        for (var userDoc in usersSnap.data!.docs) {
                          String uid = userDoc.id;
                          if (pendingLecturesPerUser.containsKey(uid)) {
                            var rawRate = userDoc['hourlyRate'];
                            double rate = (rawRate is int) ? rawRate.toDouble() : (rawRate as double? ?? 0.0);
                            totalPendingAmount += pendingLecturesPerUser[uid]! * rate;
                          }
                        }
                      }
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text("₹${totalPendingAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ACTIVE FACULTY", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'faculty').snapshots(),
                            builder: (context, snapshot) {
                              String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
                              return Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white));
                            }
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("PENDING LOGS", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('attendance').where('status', isEqualTo: 'Pending').snapshots(),
                              builder: (context, snapshot) {
                                String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
                                return Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: pendingOrange));
                              }
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- EXTENDED QUICK ACTIONS LIST ---
  Widget _buildQuickActionsList(BuildContext context) {
    return Column(
      children: [
        _buildActionListTile(
            Icons.verified, "Verify Logs", "Review and approve faculty attendance", verifiedBlue,
                () => Navigator.pushReplacementNamed(context, '/admin/view-attendance')
        ),
        _buildActionListTile(
            Icons.account_balance, "Process Payments", "Calculate and clear verified logs", successGreen,
                () => Navigator.pushReplacementNamed(context, '/admin/calculate-salary')
        ),
        _buildActionListTile(
            Icons.people, "View Faculty", "See all registered faculty members", Colors.cyanAccent,
                () => Navigator.pushReplacementNamed(context, '/admin/view-faculty')
        ),
        _buildActionListTile(
            Icons.person_add, "Add Faculty", "Onboard new faculty members", Colors.purpleAccent,
                () => Navigator.pushReplacementNamed(context, '/admin/add-faculty')
        ),
        _buildActionListTile(
            Icons.receipt_long, "Generate Reports", "Export monthly liability and slips", Colors.orangeAccent,
                () => Navigator.pushReplacementNamed(context, '/admin/reports')
        ),
        _buildActionListTile(
            Icons.person, "My Profile", "Manage your admin account details", Colors.pinkAccent,
                () => Navigator.pushReplacementNamed(context, '/admin/profile')
        ),
      ],
    );
  }

  Widget _buildActionListTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2E39),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }

}

class FacultySearchDelegate extends SearchDelegate<String?> {
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
        close(context, null);
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
        child: Text("Search faculty by name or email...", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
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
                // Return result or navigate
                close(context, data['uid'] ?? docs[index].id);
              },
            );
          },
        );
      },
    );
  }
}