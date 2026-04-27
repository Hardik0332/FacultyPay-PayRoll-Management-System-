import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'notifications_page.dart';
import '../../widgets/notification_badge.dart';

import 'add_attendance_page.dart';
import 'faculty_salary_summary_page.dart';
import 'faculty_profile_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward();
    super.initState();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(index: widget.index, children: widget.children),
    );
  }
}

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key, required int initialIndex});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  int _currentNavIndex = 0;

  late final List<Widget> _pages = [
    _FacultyDashboardHomeContent(
      onAvatarTap: () {
        setState(() {
          _currentNavIndex = 3;
        });
      },
    ),
    const AddAttendancePage(),
    const FacultySalaryHistoryPage(),
    const FacultyProfilePage(),
  ];

  // =================================================================
  // ✅ NEW CODE: This is exactly where the Push Notification setup goes!
  // =================================================================
  @override
  void initState() {
    super.initState();
    _setupPushNotifications();
  }

  Future<void> _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Ask the user for permission (Required for iOS and newer Androids)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get the unique FCM token for this specific phone
      String? token = await messaging.getToken();

      if (token != null) {
        String uid = FirebaseAuth.instance.currentUser!.uid;

        // 3. Save this token to their Firestore profile so the Admin can find it!
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    }
  }
  // =================================================================

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFFE05B5C);

    return PopScope(
      canPop: _currentNavIndex == 0,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (!didPop) {
          setState(() {
            _currentNavIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF282C37),
        body: Stack(
          children: [
            // The pages with smooth transition
            FadeIndexedStack(index: _currentNavIndex, children: _pages),

            // Floating Navigation Bar (Crystal Clear Glass)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  // 1. DECREASED BLUR so the background is clearer
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          // 2. INCREASED TRANSPARENCY (almost completely clear)
                          Colors.white.withValues(alpha: 0.03),
                          Colors.transparent, // 0.0 alpha
                        ],
                      ),
                      borderRadius: BorderRadius.circular(40),
                      // Delicate border to define the edge of the glass
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(Icons.home, "HOME", 0, primaryRed),
                        _buildNavItem(
                          Icons.edit_document,
                          "LOG",
                          1,
                          primaryRed,
                        ),
                        _buildNavItem(
                          Icons.account_balance_wallet,
                          "PAY",
                          2,
                          primaryRed,
                        ),
                        _buildNavItem(
                          Icons.person,
                          "MY PROFILE",
                          3,
                          primaryRed,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon,
      String label,
      int index,
      Color primaryRed,
      ) {
    bool isActive = _currentNavIndex == index;
    final color = isActive ? primaryRed : Colors.white.withValues(alpha: 0.4);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentNavIndex = index;
          });
        },
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
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  width: 20,
                  decoration: BoxDecoration(
                    color: primaryRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------
// DASHBOARD CONTENT
// --------------------------------------------------------
class _FacultyDashboardHomeContent extends StatefulWidget {
  final VoidCallback onAvatarTap;
  const _FacultyDashboardHomeContent({required this.onAvatarTap});

  @override
  State<_FacultyDashboardHomeContent> createState() =>
      _FacultyDashboardHomeContentState();
}

class _FacultyDashboardHomeContentState
    extends State<_FacultyDashboardHomeContent> {
  final Color primaryRed = const Color(0xFFE05B5C);
  final Color successGreen = const Color(0xFF4ADE80);
  final Color pendingOrange = const Color(0xFFFBBF24);
  final Color verifiedBlue = const Color(0xFF60A5FA);

  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors
          .transparent, // Background handled by parent, but we add gradient
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

          // 2. FIREBASE BOUND TOP AREA (Header & Master Card)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser?.uid)
                .snapshots(),
            builder: (context, userSnap) {
              // Default Fallbacks
              String name = "Faculty Member";
              String? avatarBase64;
              double hourlyRate = 0.0;

              if (userSnap.hasData && userSnap.data!.exists) {
                final data = userSnap.data!.data() as Map<String, dynamic>?;
                if (data != null) {
                  name = data['name'] ?? name;
                  avatarBase64 = data['avatarBase64'];
                  hourlyRate = (data['hourlyRate'] is int)
                      ? (data['hourlyRate'] as int).toDouble()
                      : (data['hourlyRate'] as double? ?? 0.0);
                }
              }

              return SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: _buildHeader(avatarBase64),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildMasterCard(name, hourlyRate),
                    ),
                  ],
                ),
              );
            },
          ),

          // 3. THE DRAGGABLE BOTTOM SHEET (With Firebase History)
          DraggableScrollableSheet(
            initialChildSize: 0.58,
            minChildSize: 0.58,
            maxChildSize: 0.88,
            snap: true,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF242832),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // --- DRAG HANDLE AREA ---
                    SingleChildScrollView(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 16, bottom: 20),
                        color: Colors.transparent,
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // --- FIREBASE SALARY LIST ---
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 120,
                        ),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          const Text(
                            "Recent Salary Records",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFirebaseSalaryList(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String? avatarBase64) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            "FacultyPay",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---> CLICKABLE NOTIFICATION BUTTON <---
            const NotificationBadge(),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.onAvatarTap,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty
                    ? MemoryImage(base64Decode(avatarBase64))
                    : null,
                child: (avatarBase64 == null || avatarBase64.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMasterCard(String name, double hourlyRate) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int totalLectures = 0;
        int verifiedLectures = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final count = data['lectures'] as int? ?? 0;
            final status = data['status'] ?? 'Pending';

            totalLectures += count;
            if (status == 'Verified' || status == 'Paid') {
              verifiedLectures += count;
            }
          }
        }

        double earnings = verifiedLectures * hourlyRate;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Good Morning,",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "TOTAL EARNINGS",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "₹${earnings.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: successGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "TOTAL LECTURES",
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$totalLectures",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 32),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "HOURLY RATE",
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "₹${hourlyRate.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Image.asset(
                      'assets/images/bank.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFirebaseSalaryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: currentUser?.uid)
          .orderBy('date', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryRed));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                "No attendance records found.",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
          );
        }

        return Stack(
          children: [
            Positioned(
              left: 35,
              top: 30,
              bottom: 30,
              child: Container(
                width: 1.5,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                DateTime date = (data['date'] as Timestamp).toDate();
                String status = data['status'] ?? 'Pending';
                int lecturesCount = data['lectures'] ?? 0;
                String subject = data['subject'] ?? 'Unknown';

                Color statusColor = pendingOrange;
                IconData icon = Icons.pending_actions;

                if (status.toLowerCase() == 'paid') {
                  statusColor = successGreen;
                  icon = Icons.check_circle;
                } else if (status.toLowerCase() == 'verified') {
                  statusColor = verifiedBlue;
                  icon = Icons.verified;
                }

                return _buildSalaryItem(
                  icon,
                  DateFormat('MMM dd, yyyy').format(date),
                  "$lecturesCount Lecture(s) • $subject",
                  status.toUpperCase(),
                  statusColor,
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSalaryItem(
      IconData icon,
      String title,
      String details,
      String status,
      Color statusColor,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2E39),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFF4A5060),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}