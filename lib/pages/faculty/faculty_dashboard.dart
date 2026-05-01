import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../theme/theme_manager.dart';
import '../../widgets/notification_badge.dart';

import 'package:animations/animations.dart'; // ✅ Added morph animations
class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // ✅ 1. Create variables to hold your streams
  late Stream<DocumentSnapshot> _userStream;
  late Stream<QuerySnapshot> _attendanceStream;

  @override
  void initState() {
    super.initState();
    _setupPushNotifications();

    // ✅ 2. Initialize the streams ONCE when the page loads.
    // Now, when the theme changes, the data stays instantly available!
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .snapshots();

    _attendanceStream = FirebaseFirestore.instance
        .collection('attendance')
        .where('uid', isEqualTo: currentUser?.uid)
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<void> _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      if (token != null && currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Just grab the colors normally
    final colors = ThemeManager.instance.colors;
    final isDark = ThemeManager.instance.isDarkMode;

    return Stack(
      children: [
        // 1. Exact Subtle Gradient Background
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
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: StreamBuilder<DocumentSnapshot>(
              stream: _userStream, // ✅ 3. Use the cached stream here
              builder: (context, userSnap) {
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
                      // HEADER
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: _buildHeader(avatarBase64, colors, isDark),
                      ),

                      // MASTER CARD
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildMasterCard(name, hourlyRate, colors, isDark),
                      ),

                      const SizedBox(height: 32),

                      // FLOATING TITLE
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Recent Salary Records",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textMain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // FLOATING LIST
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildFirebaseSalaryList(colors, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader(String? avatarBase64, AppColors colors, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            "FacultyPay",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: colors.textMain,
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ THEME TOGGLE
            ThemeSwitcher(
              clipper: const ThemeSwitcherCircleClipper(),
              builder: (context) {
                return GestureDetector(
                  onTap: () {
                    ThemeManager.instance.toggleTheme();
                    final newColors = ThemeManager.instance.colors;
                    final newIsDark = ThemeManager.instance.isDarkMode;

                    final newTheme = ThemeData(
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
                          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.scaled,
                          ),
                          TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.scaled,
                          ),
                          TargetPlatform.windows: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.scaled,
                          ),
                          TargetPlatform.macOS: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.scaled,
                          ),
                          TargetPlatform.linux: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.scaled,
                          ),
                        },
                      ),
                    );

                    ThemeSwitcher.of(context).changeTheme(theme: newTheme);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colors.textMain.withValues(alpha: 0.1)
                          : colors.textMuted.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ThemeManager.instance.currentMode == AppThemeMode.system
                          ? Icons.brightness_auto
                          : (ThemeManager.instance.currentMode == AppThemeMode.light
                          ? Icons.light_mode
                          : Icons.dark_mode_outlined),
                      color: ThemeManager.instance.currentMode == AppThemeMode.light
                          ? Colors.amber
                          : colors.textMain,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),

            // Notification Badge
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.transparent : colors.textMuted.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const NotificationBadge(),
            ),
            const SizedBox(width: 12),

            // Profile Avatar
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/faculty/profile'),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: isDark ? colors.textMain.withValues(alpha: 0.15) : colors.primary,
                backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty
                    ? MemoryImage(base64Decode(avatarBase64))
                    : null,
                child: (avatarBase64 == null || avatarBase64.isEmpty)
                    ? Icon(
                  Icons.person,
                  color: isDark ? colors.textMain : Colors.white,
                  size: 20,
                )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMasterCard(String name, double hourlyRate, AppColors colors, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _attendanceStream, // ✅ 4. Use the cached stream here
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

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? colors.cardHighlight : colors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? colors.textMain.withValues(alpha: 0.1) : Colors.transparent,
            ),
            boxShadow: isDark
                ? []
                : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                    Text("Good Morning,", style: TextStyle(color: colors.textMuted, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textMain),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 24),
                    Text("TOTAL EARNINGS", style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "₹${earnings.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: colors.primary),
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
                              Text("TOTAL LECTURES", style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text("$totalLectures", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textMain)),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("HOURLY RATE", style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text("₹${hourlyRate.toStringAsFixed(0)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textMain)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 90,
                alignment: Alignment.bottomRight,
                child: Image.asset(
                  isDark ? 'assets/images/bank.png' : 'assets/images/bank_light.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFirebaseSalaryList(AppColors colors, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _attendanceStream, // ✅ 5. Use the cached stream here
      builder: (context, snapshot) {
        // Now it won't hit this waiting state when changing themes!
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: colors.primary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text("No records found.", style: TextStyle(color: colors.textMuted))),
          );
        }

        return Stack(
          children: [
            Positioned(
              left: 36,
              top: 30,
              bottom: 30,
              child: Container(
                width: 2,
                color: isDark ? colors.textMain.withValues(alpha: 0.1) : const Color(0xFF2F6B4F),
              ),
            ),
            Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                DateTime date = (data['date'] as Timestamp).toDate();
                String status = data['status'] ?? 'Pending';
                int lecturesCount = data['lectures'] ?? 0;
                String subject = data['subject'] ?? 'Unknown';

                Color textColor = colors.warning;
                Color bgColor = colors.warningBg;
                IconData icon = Icons.pending_actions;

                if (status.toLowerCase() == 'paid' || status.toLowerCase() == 'verified') {
                  textColor = colors.success;
                  bgColor = colors.successBg;
                  icon = Icons.check_circle;
                } else if (status.toLowerCase() == 'rejected') {
                  textColor = colors.error;
                  bgColor = colors.error.withValues(alpha: 0.1);
                  icon = Icons.error;
                } else {
                  textColor = colors.processing;
                  bgColor = colors.processingBg;
                }

                return _buildSalaryItem(
                  icon,
                  DateFormat('MMM dd, yyyy').format(date),
                  "$lecturesCount Lecture(s) • $subject",
                  status.toUpperCase(),
                  textColor,
                  bgColor,
                  colors,
                  isDark,
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSalaryItem(IconData icon, String title, String details, String status, Color textColor, Color bgColor, AppColors colors, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? colors.textMain.withValues(alpha: 0.05) : Colors.transparent,
          ),
          boxShadow: isDark
              ? []
              : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? colors.textMain.withValues(alpha: 0.1) : colors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDark ? colors.textMain : Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: colors.textMain, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(details, style: TextStyle(color: colors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
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