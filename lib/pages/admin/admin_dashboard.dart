import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/theme_manager.dart'; // ✅ IMPORT THE THEME MANAGER
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:animations/animations.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final Color primaryRed = const Color(0xFFE05B5C);
  @override
  Widget build(BuildContext context) {
    // ✅ WRAP IN ANIMATED BUILDER
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, child) {
        final colors = ThemeManager.instance.colors;
        final isDark = ThemeManager.instance.isDarkMode;

        return Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.bgTop, colors.bgBottom],
                ),
              ),
            ),

            // Main Scrollable Content
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: colors.primary,
                backgroundColor: colors.card,
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 1200));
                  setState(() {});
                },
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: _buildHeader(context, colors, isDark),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildMasterCard(colors, isDark),
                          ),
                          const SizedBox(height: 32),

                          // Quick Actions Title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textMain, letterSpacing: 0.5)),
                          ),
                          const SizedBox(height: 16),

                          // Vertical List of Actions
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildQuickActionsList(context, colors, isDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- UI COMPONENTS & LOGIC MAPPINGS ---

  Widget _buildHeader(BuildContext context, AppColors colors, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Admin Portal", style: TextStyle(color: primaryRed, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text("Command Center", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colors.textMain, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ THEME TOGGLE SWITCH
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
                        appBarTheme: AppBarTheme(backgroundColor: newColors.card, foregroundColor: newColors.textMain),
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

            // SEARCH BUTTON
            GestureDetector(
              onTap: () async {
                final String? selectedUid = await showDialog<String>(
                  context: context,
                  builder: (context) => const FacultySearchDialog(),
                );

                if (selectedUid != null && context.mounted) {
                  Navigator.pushReplacementNamed(context, '/admin/view-faculty');
                }
              },
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isDark ? colors.textMain.withValues(alpha: 0.15) : colors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.search, color: isDark ? Colors.white : colors.primary, size: 20)
              ),
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

  Widget _buildMasterCard(AppColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardHighlight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? colors.textMain.withValues(alpha: 0.1) : Colors.transparent),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("CURRENT MONTH LIABILITY", style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('attendance').where('status', isEqualTo: 'Verified').snapshots(),
            builder: (context, attendanceSnap) {
              if (!attendanceSnap.hasData) return Text("₹...", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: primaryRed));

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
                    child: Text("₹${totalPendingAmount.toStringAsFixed(2)}", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: colors.primary)),
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
                    Text("ACTIVE FACULTY", style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'faculty').snapshots(),
                        builder: (context, snapshot) {
                          String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
                          return Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textMain));
                        }
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: colors.textMain.withValues(alpha: 0.1)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("PENDING LOGS", style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('attendance').where('status', isEqualTo: 'Pending').snapshots(),
                          builder: (context, snapshot) {
                            String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
                            return Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.warning));
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
    );
  }

  // --- EXTENDED QUICK ACTIONS LIST ---
  Widget _buildQuickActionsList(BuildContext context, AppColors colors, bool isDark) {
    return Column(
      children: [
        _buildActionListTile(
            Icons.verified, "Verify Logs", "Review and approve faculty attendance", colors.processing, colors, isDark,
                () => Navigator.pushReplacementNamed(context, '/admin/view-attendance')
        ),
        _buildActionListTile(
            Icons.account_balance, "Process Payments", "Calculate and clear verified logs", colors.success, colors, isDark,
                () => Navigator.pushReplacementNamed(context, '/admin/calculate-salary')
        ),
        _buildActionListTile(
            Icons.people, "View Faculty", "See all registered faculty members", const Color(0xFF06B6D4), colors, isDark, // Cyan variant
                () => Navigator.pushReplacementNamed(context, '/admin/view-faculty')
        ),
        _buildActionListTile(
            Icons.person_add, "Add Faculty", "Onboard new faculty members", const Color(0xFFA855F7), colors, isDark, // Purple variant
                () => Navigator.pushReplacementNamed(context, '/admin/add-faculty')
        ),
        _buildActionListTile(
            Icons.receipt_long, "Generate Reports", "Export monthly liability and slips", colors.warning, colors, isDark,
                () => Navigator.pushReplacementNamed(context, '/admin/reports')
        ),
        _buildActionListTile(
            Icons.person, "My Profile", "Manage your admin account details", const Color(0xFFEC4899), colors, isDark, // Pink variant
                () => Navigator.pushReplacementNamed(context, '/admin/profile')
        ),
      ],
    );
  }

  Widget _buildActionListTile(IconData icon, String title, String subtitle, Color accentColor, AppColors colors, bool isDark, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? colors.textMain.withValues(alpha: 0.05) : Colors.transparent),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: colors.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: colors.textMuted.withValues(alpha: 0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FLOATING SEARCH DIALOG (THEMED)
// ============================================================================
class FacultySearchDialog extends StatefulWidget {
  const FacultySearchDialog({super.key});

  @override
  State<FacultySearchDialog> createState() => _FacultySearchDialogState();
}

class _FacultySearchDialogState extends State<FacultySearchDialog> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: ThemeManager.instance,
        builder: (context, child) {
          final colors = ThemeManager.instance.colors;
          final isDark = ThemeManager.instance.isDarkMode;

          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? colors.textMain.withValues(alpha: 0.1) : Colors.transparent),
                  boxShadow: isDark
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))]
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 15))],
                ),
                child: Column(
                  children: [
                    // Search Input Bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        autofocus: true,
                        style: TextStyle(color: colors.textMain, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "Search faculty by name or email...",
                          hintStyle: TextStyle(color: colors.textMuted),
                          prefixIcon: Icon(Icons.search, color: colors.textMuted),
                          filled: true,
                          fillColor: isDark ? colors.bgBottom : colors.bgTop,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        onChanged: (val) {
                          setState(() {
                            query = val;
                          });
                        },
                      ),
                    ),

                    Container(height: 1, color: colors.textMain.withValues(alpha: 0.05)),

                    // Search Results
                    Expanded(
                      child: query.isEmpty
                          ? Center(
                        child: Text("Type to search...", style: TextStyle(color: colors.textMuted, fontSize: 14)),
                      )
                          : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'faculty').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator(color: colors.primary));
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
                              child: Text("No faculty found matching '$query'.", style: TextStyle(color: colors.textMuted)),
                            );
                          }

                          return ListView.builder(
                            itemCount: docs.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'Unknown';
                              final email = data['email'] ?? 'No email';
                              final avatarBase64 = data['avatarBase64'];

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDark ? colors.textMain.withValues(alpha: 0.15) : colors.primary.withValues(alpha: 0.1),
                                  backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
                                  child: (avatarBase64 == null || avatarBase64.isEmpty) ? Icon(Icons.person, color: isDark ? colors.textMain : colors.primary) : null,
                                ),
                                title: Text(name, style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold)),
                                subtitle: Text(email, style: TextStyle(color: colors.textMuted)),
                                onTap: () {
                                  Navigator.pop(context, data['uid'] ?? docs[index].id);
                                },
                              );
                            },
                          );
                        },
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
}