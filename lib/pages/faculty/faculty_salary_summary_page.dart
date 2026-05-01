import 'package:animations/animations.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'notifications_page.dart';
import '../../widgets/notification_badge.dart';
import '../../theme/theme_manager.dart';
// Make sure you have these imports pointing to your actual service files!
import '../../services/report_service.dart';
import '../../services/receipt_service.dart';
class FacultySalaryHistoryPage extends StatefulWidget {
  const FacultySalaryHistoryPage({super.key});
  @override
  State<FacultySalaryHistoryPage> createState() => _FacultySalaryHistoryPageState();
}
class _FacultySalaryHistoryPageState extends State<FacultySalaryHistoryPage> {
  int _currentTabIndex = 0; // 0: All, 1: Completed, 2: Pending
  final User? currentUser = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Center(child: Text("Not logged in"));
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, child) {
        final colors = ThemeManager.instance.colors;
        final isDark = ThemeManager.instance.isDarkMode;
        return Stack(
          children: [
            // 1. Background Gradient (Dynamic)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.bgTop, colors.bgBottom],
                ),
              ),
            ),
            // 2. Centered Content Container
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) return Center(child: CircularProgressIndicator(color: colors.primary));
                    final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                    final double hourlyRate = (userData['hourlyRate'] is int)
                        ? (userData['hourlyRate'] as int).toDouble()
                        : (userData['hourlyRate'] as double? ?? 0.0);
                    final String name = userData['name'] ?? 'Faculty Member';
                    final String dept = userData['department'] ?? 'General';
                    final String? avatarBase64 = userData['avatarBase64'];
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('attendance')
                          .where('uid', isEqualTo: currentUser!.uid)
                          .orderBy('date', descending: true)
                          .snapshots(),
                      builder: (context, attendanceSnap) {
                        if (attendanceSnap.connectionState == ConnectionState.waiting && !attendanceSnap.hasData) {
                          return Center(child: CircularProgressIndicator(color: colors.primary));
                        }
                        final docs = attendanceSnap.data?.docs ?? [];
                        // --- CALCULATIONS ---
                        double totalEarnedYTD = 0;
                        double pendingPayment = 0;
                        Map<String, List<QueryDocumentSnapshot>> groupedData = {};
                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          int lectures = data['lectures'] ?? 0;
                          String status = data['status'] ?? 'Pending';
                          Timestamp ts = data['date'];
                          String monthKey = DateFormat('MMMM yyyy').format(ts.toDate());
                          // Group by Month
                          if (!groupedData.containsKey(monthKey)) groupedData[monthKey] = [];
                          groupedData[monthKey]!.add(doc);
                          // Totals
                          if (status == 'Paid' || status == 'Completed') {
                            totalEarnedYTD += (lectures * hourlyRate);
                          } else if (status == 'Verified' || status == 'Pending') {
                            pendingPayment += (lectures * hourlyRate);
                          }
                        }
                        return SafeArea(
                          bottom: false,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                child: _buildHeader(name, dept, hourlyRate, docs, avatarBase64, colors, isDark),
                              ),
                              // Master Card
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildMasterCard(totalEarnedYTD, pendingPayment, colors, isDark),
                              ),
                              const SizedBox(height: 32),
                              // Main List Container
                              Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDark ? colors.card : Colors.transparent, // Floating in light mode
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                                    boxShadow: isDark ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -5))] : [],
                                  ),
                                  child: Column(
                                    children: [
                                      // Segmented Tabs
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 16),
                                        child: _buildSegmentedTabs(colors, isDark),
                                      ),
                                      // History List
                                      Padding(
                                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120), // Clearance for floating nav bar
                                        child: Stack(
                                              children: [
                                                Positioned(
                                                    left: 36, top: 30, bottom: 30,
                                                    child: Container(width: 2, color: isDark ? colors.textMain.withValues(alpha: 0.1) : const Color(0xFFDDEBE3))
                                                ),
                                                Column(
                                                  children: _buildMonthlyList(groupedData, hourlyRate, name, dept, colors, isDark),
                                                ),
                                              ],
                                            ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  // --- HEADER (WITH PRINT SERVICE & THEME TOGGLE) ---
  Widget _buildHeader(String name, String dept, double hourlyRate, List<QueryDocumentSnapshot> docs, String? avatarBase64, AppColors colors, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Text(
                "FacultyPay",
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
            // Print Button
            GestureDetector(
              onTap: () {
                if (docs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("No records to print"), backgroundColor: colors.warning));
                  return;
                }
                double totalPaid = 0.0;
                for (var doc in docs) {
                  if (doc['status'] == 'Paid' || doc['status'] == 'Completed') totalPaid += (doc['lectures'] as int) * hourlyRate;
                }
                ReportService.printHistoryReport(
                  title: "Faculty Statement",
                  subtitle: "Full History of Lectures and Payment Status",
                  docs: docs,
                  isAdminReport: false,
                  singleFacultyName: name,
                  singleFacultyDept: dept,
                  singleFacultyRate: hourlyRate,
                  totalAmountPaid: totalPaid,
                );
              },
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isDark ? colors.textMain.withValues(alpha: 0.15) : colors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.print, color: isDark ? Colors.white : colors.primary, size: 20)
              ),
            ),
            const SizedBox(width: 12),
            // Notification Badge
            Container(
              decoration: BoxDecoration(color: isDark ? Colors.transparent : colors.textMuted.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const NotificationBadge(),
            ),
            const SizedBox(width: 12),
            // Avatar
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/faculty/profile');
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: isDark ? colors.textMain.withValues(alpha: 0.15) : colors.primary,
                backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
                child: (avatarBase64 == null || avatarBase64.isEmpty) ? Icon(Icons.person, color: isDark ? colors.textMain : Colors.white, size: 20) : null,
              ),
            ),
          ],
        )
      ],
    );
  }
  // --- MASTER CARD ---
  Widget _buildMasterCard(double totalEarned, double pendingPayment, AppColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardHighlight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? colors.textMain.withValues(alpha: 0.1) : Colors.transparent),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Payments", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textMain)),
                const SizedBox(height: 4),
                Text("Overview of recent faculty distributions.", style: TextStyle(color: colors.textMuted, fontSize: 13)),
                const SizedBox(height: 24),
                Text("TOTAL DISBURSED (YTD)", style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text("₹${totalEarned.toStringAsFixed(2)}", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: colors.primary))
                ),
                const SizedBox(height: 24),
                Text("NEXT PAYOUT", style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    // We simulate the next payout date or show pending
                    child: Text(pendingPayment > 0 ? "Pending: ₹${pendingPayment.toStringAsFixed(0)}" : "Up to date", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textMain))
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Image Swap based on theme
          Container(
            width: 100,
            alignment: Alignment.bottomRight,
            child: Image.asset(isDark ? 'assets/images/bank.png' : 'assets/images/bank_light.png', fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
  // --- TABS ---
  Widget _buildSegmentedTabs(AppColors colors, bool isDark) {
    return Container(
      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          _buildTab("All Payments", 0, colors, isDark),
          const SizedBox(width: 8),
          _buildTab("Completed", 1, colors, isDark),
          const SizedBox(width: 8),
          _buildTab("Pending", 2, colors, isDark),
        ],
      ),
    );
  }
  Widget _buildTab(String title, int index, AppColors colors, bool isDark) {
    bool isActive = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? colors.primary : (isDark ? Colors.transparent : colors.card),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isActive ? colors.primary : (isDark ? colors.textMain.withValues(alpha: 0.2) : colors.textMain.withValues(alpha: 0.05))),
            boxShadow: (!isDark && !isActive) ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
                color: isActive ? Colors.white : colors.textMuted,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13
            ),
          ),
        ),
      ),
    );
  }
  // --- MONTHLY LIST BUILDER ---
  List<Widget> _buildMonthlyList(Map<String, List<QueryDocumentSnapshot>> groupedData, double hourlyRate, String facultyName, String department, AppColors colors, bool isDark) {
    List<Widget> items = [];
    for (var entry in groupedData.entries) {
      String month = entry.key;
      List<QueryDocumentSnapshot> docs = entry.value;
      int totalLectures = 0;
      double totalAmount = 0;
      bool hasPending = false;
      bool hasVerified = false;
      bool isAllPaid = true;
      for (var doc in docs) {
        int l = doc['lectures'] as int? ?? 0;
        totalLectures += l;
        totalAmount += (l * hourlyRate);
        String status = doc['status'];
        if (status == 'Pending') { hasPending = true; isAllPaid = false; }
        if (status == 'Verified') { hasVerified = true; isAllPaid = false; }
      }
      String statusText = "PROCESSING";
      Color textColor = colors.processing;
      Color bgColor = colors.processingBg;
      IconData icon = Icons.pending_actions;
      if (isAllPaid) {
        statusText = "COMPLETED";
        textColor = colors.success;
        bgColor = colors.successBg;
        icon = Icons.check_circle;
      } else if (hasVerified) {
        statusText = "APPROVED";
        textColor = colors.processing;
        bgColor = colors.processingBg;
        icon = Icons.verified;
      } else if (hasPending) {
        statusText = "PENDING";
        textColor = colors.warning;
        bgColor = colors.warningBg;
        icon = Icons.hourglass_empty;
      }
      // Tab Filtering Logic
      if (_currentTabIndex == 1 && !isAllPaid) continue; // Show only Paid
      if (_currentTabIndex == 2 && isAllPaid) continue; // Show only Pending/Approved
      items.add(
          _buildTransactionItem(
            icon: icon,
            title: "$month Salary",
            amount: "₹${totalAmount.toStringAsFixed(2)}",
            status: statusText,
            textColor: textColor,
            bgColor: bgColor,
            isCompleted: isAllPaid,
            docs: docs,
            facultyName: facultyName,
            department: department,
            hourlyRate: hourlyRate,
            month: month,
            totalLectures: totalLectures,
            totalAmount: totalAmount,
            colors: colors,
            isDark: isDark,
          )
      );
    }
    if (items.isEmpty) {
      return [Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: Text("No records found for this filter.", style: TextStyle(color: colors.textMuted))))];
    }
    return items;
  }
  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String amount,
    required String status,
    required Color textColor,
    required Color bgColor,
    required bool isCompleted,
    required List<QueryDocumentSnapshot> docs,
    required String facultyName,
    required String department,
    required double hourlyRate,
    required String month,
    required int totalLectures,
    required double totalAmount,
    required AppColors colors,
    required bool isDark,
  }) {
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
                decoration: BoxDecoration(
                    color: isCompleted ? colors.primary : (isDark ? colors.textMain.withValues(alpha: 0.1) : colors.textMain.withValues(alpha: 0.05)),
                    shape: BoxShape.circle
                ),
                child: Icon(icon, color: isCompleted ? Colors.white : colors.textMain, size: 20)
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: colors.textMain, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(amount, style: TextStyle(color: colors.textMain, fontSize: 19, fontWeight: FontWeight.bold)),
                      if (isCompleted) ...[
                        const SizedBox(width: 12),
                        // RECEIPT DOWNLOAD BUTTON
                        GestureDetector(
                          onTap: () {
                            List<List<String>> receiptDetails = [];
                            for (var doc in docs) {
                              final d = doc.data() as Map<String, dynamic>;
                              DateTime dt = (d['date'] as Timestamp).toDate();
                              int lecs = d['lectures'] as int;
                              double rowTotal = lecs * hourlyRate;
                              receiptDetails.add([
                                DateFormat('dd MMM yyyy').format(dt),
                                d['subject'] ?? '-',
                                lecs.toString(),
                                "₹ ${hourlyRate.toStringAsFixed(2)}",
                                "₹ ${rowTotal.toStringAsFixed(2)}"
                              ]);
                            }
                            ReceiptService.printReceipt(
                              facultyName: facultyName,
                              department: department,
                              month: month,
                              totalLectures: totalLectures,
                              ratePerLecture: hourlyRate,
                              totalAmount: totalAmount,
                              paymentDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                              receiptId: "SLIP-${month.replaceAll(' ', '-')}",
                              lectureDetails: receiptDetails,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: isDark ? colors.textMain.withValues(alpha: 0.1) : colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.download, color: isDark ? colors.textMain : colors.primary, size: 16),
                          ),
                        )
                      ]
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? textColor.withValues(alpha: 0.3) : Colors.transparent)
              ),
              child: Text(status, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}
