import 'dart:ui';
import 'dart:convert'; // Added to decode the base64 image
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'notifications_page.dart';
import '../../widgets/notification_badge.dart';

// Make sure you have these imports pointing to your actual service files!
import '../../services/report_service.dart';
import '../../services/receipt_service.dart';

class FacultySalaryHistoryPage extends StatefulWidget {
  const FacultySalaryHistoryPage({super.key});

  @override
  State<FacultySalaryHistoryPage> createState() => _FacultySalaryHistoryPageState();
}

class _FacultySalaryHistoryPageState extends State<FacultySalaryHistoryPage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  final Color successGreen = const Color(0xFF4ADE80);
  final Color pendingOrange = const Color(0xFFFBBF24);
  final Color processingBlue = const Color(0xFF60A5FA);

  int _currentTabIndex = 0; // 0: All, 1: Completed, 2: Pending
  int _currentNavIndex = 2; // "PAY" tab

  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Not logged in")));

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

          // 2. FIREBASE DATA STREAM
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());

              final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
              final double hourlyRate = (userData['hourlyRate'] is int)
                  ? (userData['hourlyRate'] as int).toDouble()
                  : (userData['hourlyRate'] as double? ?? 0.0);
              final String name = userData['name'] ?? 'Faculty Member';
              final String dept = userData['department'] ?? 'General';

              // FETCH AVATAR FROM FIREBASE
              final String? avatarBase64 = userData['avatarBase64'];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('attendance')
                    .where('uid', isEqualTo: currentUser!.uid)
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, attendanceSnap) {
                  if (attendanceSnap.connectionState == ConnectionState.waiting && !attendanceSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
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
                    if (status == 'Paid') {
                      totalEarnedYTD += (lectures * hourlyRate);
                    } else if (status == 'Verified' || status == 'Pending') {
                      pendingPayment += (lectures * hourlyRate);
                    }
                  }

                  return Stack(
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              // PASS AVATAR TO HEADER
                              child: _buildHeader(name, dept, hourlyRate, docs, avatarBase64),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildMasterCard(totalEarnedYTD, pendingPayment),
                            ),
                          ],
                        ),
                      ),

                      // 3. THE DRAGGABLE BOTTOM SHEET (Monthly History)
                      DraggableScrollableSheet(
                        initialChildSize: 0.58,
                        minChildSize: 0.58,
                        maxChildSize: 0.88,
                        builder: (BuildContext context, ScrollController scrollController) {
                          return Container(
                            margin: const EdgeInsets.only(top: 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF242832),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -5))],
                            ),
                            child: ListView(
                              controller: scrollController, // This makes the ENTIRE sheet draggable
                              padding: const EdgeInsets.only(bottom: 120), // Padding for the floating nav bar
                              physics: const ClampingScrollPhysics(), // Keeps the drag smooth
                              children: [
                                // Drag Handle (Visual)
                                Center(
                                  child: Container(
                                    width: 40, height: 4,
                                    margin: const EdgeInsets.only(top: 16, bottom: 20),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                                  ),
                                ),

                                // Segmented Tabs
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: _buildSegmentedTabs(),
                                ),
                                const SizedBox(height: 24),

                                // History List
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Stack(
                                    children: [
                                      Positioned(left: 35, top: 30, bottom: 30, child: Container(width: 1.5, color: primaryRed.withValues(alpha: 0.4))),
                                      Column(
                                        children: _buildMonthlyList(groupedData, hourlyRate, name, dept),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
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

  // --- HEADER (WITH PRINT SERVICE) ---
  Widget _buildHeader(String name, String dept, double hourlyRate, List<QueryDocumentSnapshot> docs, String? avatarBase64) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text("FacultyPay", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5), overflow: TextOverflow.ellipsis)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                if (docs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No records to print")));
                  return;
                }
                double totalPaid = 0.0;
                for (var doc in docs) {
                  if (doc['status'] == 'Paid') totalPaid += (doc['lectures'] as int) * hourlyRate;
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
              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.print, color: Colors.white, size: 20)),
            ),
            const SizedBox(width: 12),
            // ---> CLICKABLE NOTIFICATION BUTTON <---
            const NotificationBadge(),
            const SizedBox(width: 12),

            // DECODED AVATAR WIDGET ADDED HERE
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
              child: (avatarBase64 == null || avatarBase64.isEmpty) ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
            ),
          ],
        )
      ],
    );
  }

  // --- MASTER CARD ---
  Widget _buildMasterCard(double totalEarned, double pendingPayment) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Payments", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text("Overview of recent faculty distributions.", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),

                    const SizedBox(height: 24),

                    Text("TOTAL EARNED (YTD)", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    FittedBox(fit: BoxFit.scaleDown, child: Text("₹${totalEarned.toStringAsFixed(2)}", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: successGreen))),

                    const SizedBox(height: 24),

                    Text("PENDING PAYMENT", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    FittedBox(fit: BoxFit.scaleDown, child: Text("₹${pendingPayment.toStringAsFixed(2)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Image.asset('assets/images/bank.png', width: 100, height: 100, fit: BoxFit.contain),
            ],
          ),
        ),
      ),
    );
  }

  // --- TABS ---
  Widget _buildSegmentedTabs() {
    return Container(
      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          _buildTab("All Payments", 0),
          const SizedBox(width: 8),
          _buildTab("Completed", 1),
          const SizedBox(width: 8),
          _buildTab("Pending", 2),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isActive = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primaryRed : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isActive ? primaryRed : Colors.white.withValues(alpha: 0.2)),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.8), fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, fontSize: 13),
          ),
        ),
      ),
    );
  }

  // --- MONTHLY LIST BUILDER ---
  List<Widget> _buildMonthlyList(Map<String, List<QueryDocumentSnapshot>> groupedData, double hourlyRate, String facultyName, String department) {
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

      String statusText = "Processing";
      Color statusColor = processingBlue;
      IconData icon = Icons.pending_actions;

      if (isAllPaid) {
        statusText = "COMPLETED";
        statusColor = successGreen;
        icon = Icons.check_circle;
      } else if (hasVerified) {
        statusText = "APPROVED";
        statusColor = processingBlue;
        icon = Icons.verified;
      } else if (hasPending) {
        statusText = "PENDING";
        statusColor = pendingOrange;
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
            statusColor: statusColor,
            isCompleted: isAllPaid,
            docs: docs,
            facultyName: facultyName,
            department: department,
            hourlyRate: hourlyRate,
            month: month,
            totalLectures: totalLectures,
            totalAmount: totalAmount,
          )
      );
    }

    if (items.isEmpty) {
      return [Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: Text("No records found for this filter.", style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))))];
    }

    return items;
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String amount,
    required String status,
    required Color statusColor,
    required bool isCompleted,
    required List<QueryDocumentSnapshot> docs,
    required String facultyName,
    required String department,
    required double hourlyRate,
    required String month,
    required int totalLectures,
    required double totalAmount,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF2A2E39), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
        child: Row(
          children: [
            Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: isCompleted ? successGreen : const Color(0xFF4A5060), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 20)
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(amount, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
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
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.download, color: Colors.white, size: 16),
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
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
              child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  // --- FLOATING NAV ---
  Widget _buildFloatingBottomNav() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7), // Reduced blur for clarity
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.03), // Almost completely transparent
                  Colors.transparent // 0.0 alpha
                ]
            ),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)), // Whisper thin border
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home, "HOME", 0),
              _buildNavItem(Icons.edit_document, "LOG", 1),
              _buildNavItem(Icons.account_balance_wallet, "PAY", 2),
              _buildNavItem(Icons.person, "MY PROFILE", 3), // Updated to match the wrapper
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _currentNavIndex == index;
    final color = isActive ? primaryRed : Colors.white.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: () {
        setState(() => _currentNavIndex = index);
      },
      child: Container(
        color: Colors.transparent,
        width: 60,
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
    );
  }
}