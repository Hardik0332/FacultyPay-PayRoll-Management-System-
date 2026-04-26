import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  int _currentNavIndex = 0; // Starts on DASHBOARD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          // 2. Fixed Background Content (Header, Master Card & Actions)
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: primaryRed,
              backgroundColor: const Color(0xFF242832),
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 1200));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: _buildHeader(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildMasterCard(),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildQuickActions(context),
                    ),
                    // Give space so the bottom sheet can rest below
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),

          // 3. THE DRAGGABLE BOTTOM SHEET (Pending Approvals from Firestore)
          DraggableScrollableSheet(
            initialChildSize: 0.48,
            minChildSize: 0.48,
            maxChildSize: 0.88,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF242832),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -5))
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 120), // Padding for the floating nav bar
                  physics: const ClampingScrollPhysics(),
                  children: [
                    // --- DRAG HANDLE ---
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(top: 16, bottom: 20),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),

                    // --- PENDING LIST HEADER ---
                    StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('attendance').where('status', isEqualTo: 'Pending').snapshots(),
                        builder: (context, snapshot) {
                          int pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Pending Verifications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: primaryRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                                  child: Text("$pendingCount Pending", style: TextStyle(color: primaryRed, fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          );
                        }
                    ),
                    const SizedBox(height: 20),

                    // --- ACTUAL PENDING LIST FROM FIREBASE ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        children: [
                          Positioned(left: 35, top: 30, bottom: 30, child: Container(width: 1.5, color: pendingOrange.withValues(alpha: 0.4))),
                          _buildPendingFirebaseList(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 4. Floating Bottom Navigation (Crystal Clear Glass)
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: _buildFloatingBottomNav(),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS & LOGIC MAPPINGS ---

  Widget _buildHeader() {
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
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.search, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.settings, color: Colors.white, size: 20)),
          ],
        )
      ],
    );
  }

  // This replaces your old _PendingSalaryCard and _StatCard by grouping them beautifully
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

              // 1. Pending Payments Logic (Verified Attendance * Hourly Rate)
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
                      return Text("₹${totalPendingAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white));
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  // 2. Active Faculty Count
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

                  // 3. Pending Logs Count
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

  // Quick actions directly mapped to your exact Navigator paths
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionCard(Icons.verified, "Verify\nLogs", verifiedBlue, () {
          Navigator.pushReplacementNamed(context, '/admin/view-attendance');
        }),
        _buildActionCard(Icons.account_balance, "Process\nPayments", successGreen, () {
          Navigator.pushReplacementNamed(context, '/admin/calculate-salary');
        }),
        _buildActionCard(Icons.person_add, "Add\nFaculty", Colors.purpleAccent, () {
          Navigator.pushReplacementNamed(context, '/admin/add-faculty');
        }),
        _buildActionCard(Icons.receipt_long, "Generate\nReports", Colors.orangeAccent, () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reports routing coming soon")));
        }),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 55, height: 55,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600, height: 1.2)),
        ],
      ),
    );
  }

  // List of actual pending items from Firebase
  Widget _buildPendingFirebaseList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('status', isEqualTo: 'Pending')
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(child: Text("No pending logs! You are all caught up.", style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String uid = data['uid'];
            final String subject = data['subject'] ?? 'Unknown';
            final int count = data['lectures'] ?? 0;
            final DateTime date = (data['date'] as Timestamp).toDate();
            final String formattedDate = "${date.day}/${date.month}/${date.year}";

            // To get the name, we use a FutureBuilder for each item
            return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                builder: (context, userSnap) {
                  String name = "Loading...";
                  if (userSnap.hasData && userSnap.data!.exists) {
                    name = userSnap.data!['name'] ?? "Unknown Faculty";
                  }

                  return _buildApprovalItem(name, subject, count, formattedDate, doc.id);
                }
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildApprovalItem(String name, String subject, int count, String date, String docId) {
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
                child: const Icon(Icons.person, color: Colors.white, size: 20)
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text("$count Lecture(s) • $subject", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            // Re-routes to your Verification Page exactly as requested
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/admin/view-attendance');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                    color: verifiedBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: verifiedBlue.withValues(alpha: 0.5))
                ),
                child: Row(
                  children: [
                    Icon(Icons.check, color: verifiedBlue, size: 16),
                    const SizedBox(width: 4),
                    Text("Verify", style: TextStyle(color: verifiedBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FLOATING NAV (ADMIN SPECIFIC) ---
  Widget _buildFloatingBottomNav() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.03),
                  Colors.transparent
                ]
            ),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.dashboard, "DASH", 0),
              _buildNavItem(Icons.checklist, "APPROVE", 1),
              _buildNavItem(Icons.group, "FACULTY", 2),
              _buildNavItem(Icons.payments, "PAYOUTS", 3),
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
        onTap: () {
          setState(() => _currentNavIndex = index);
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (isActive)
                Container(margin: const EdgeInsets.only(top: 4), height: 3, width: 20, decoration: BoxDecoration(color: primaryRed, borderRadius: BorderRadius.circular(2)))
            ],
          ),
        ),
      ),
    );
  }
}