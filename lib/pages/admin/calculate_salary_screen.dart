import 'package:animations/animations.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/notification_service.dart';
import '../../services/receipt_service.dart';
import '../../theme/theme_manager.dart'; // ✅ Added ThemeManager

class AdminCalculateSalaryPage extends StatefulWidget {
  const AdminCalculateSalaryPage({super.key});

  @override
  State<AdminCalculateSalaryPage> createState() => _AdminCalculateSalaryPageState();
}

class _AdminCalculateSalaryPageState extends State<AdminCalculateSalaryPage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  String? _searchUid;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: ThemeManager.instance,
        builder: (context, child) {
          final colors = ThemeManager.instance.colors;
          final isDark = ThemeManager.instance.isDarkMode;

          return Stack(
            children: [
              // 1. Background Gradient
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
              SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: _buildHeader(colors, isDark),
                        ),

                        // Main List Container
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_searchUid == null ? "Process Payments" : "Filtered Payments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textMain, letterSpacing: 0.5)),
                                      const SizedBox(height: 4),
                                      Text("Calculate and clear verified logs for faculty.", style: TextStyle(color: colors.textMuted, fontSize: 13)),
                                    ],
                                  ),
                                ),

                                Expanded(
                                  child: _buildFacultyList(colors, isDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader(AppColors colors, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Admin Action", style: TextStyle(color: primaryRed, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text("Payouts", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colors.textMain, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
            ],
          ),
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

            // Search Action
            GestureDetector(
              onTap: () async {
                final String? selectedUid = await showDialog<String>(
                  context: context,
                  builder: (context) => const FacultySearchDialog(),
                );
                if (selectedUid != null && selectedUid.isNotEmpty) {
                  setState(() {
                    _searchUid = selectedUid;
                  });
                }
              },
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isDark ? colors.textMain.withValues(alpha: 0.15) : colors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.search, color: isDark ? Colors.white : colors.primary, size: 20)
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
                    decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Icon(Icons.close, color: colors.error, size: 20)
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

  Widget _buildFacultyList(AppColors colors, bool isDark) {
    Query query = FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'faculty');
    if (_searchUid != null) {
      query = query.where('uid', isEqualTo: _searchUid);
    }

    return RefreshIndicator(
      color: colors.primary,
      backgroundColor: colors.cardHighlight,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 1200));
        setState(() {});
      },
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading data", style: TextStyle(color: colors.error)));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.account_balance_wallet_outlined, size: 60, color: colors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Center(child: Text("No faculty members found.", style: TextStyle(color: colors.textMuted, fontSize: 16, fontWeight: FontWeight.bold))),
                ]
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _AdminSalaryCard(
                  facultyDoc: docs[index],
                  colors: colors,
                  isDark: isDark
              );
            },
          );
        },
      ),
    );
  }
}

// ================= INDIVIDUAL SALARY CARD COMPONENT =================
class _AdminSalaryCard extends StatelessWidget {
  final QueryDocumentSnapshot facultyDoc;
  final AppColors colors;
  final bool isDark;

  const _AdminSalaryCard({required this.facultyDoc, required this.colors, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final data = facultyDoc.data() as Map<String, dynamic>;
    final String uid = facultyDoc.id;
    final String name = data['name'] ?? 'Unknown';
    final String dept = data['department'] ?? '-';
    final String upiId = data['upiId'] ?? '';
    final String? avatarBase64 = data['avatarBase64'];
    final double rate = (data['hourlyRate'] is int)
        ? (data['hourlyRate'] as int).toDouble()
        : (data['hourlyRate'] as double? ?? 0.0);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: uid)
          .where('status', whereIn: ['Verified', 'Paid'])
          .snapshots(),
      builder: (context, attSnapshot) {
        if (attSnapshot.connectionState == ConnectionState.waiting &&
            !attSnapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = attSnapshot.data?.docs ?? [];
        final now = DateTime.now();

        int owedLectures = 0;
        int paidLecturesThisMonth = 0;
        List<QueryDocumentSnapshot> docsToPay = [];
        List<QueryDocumentSnapshot> paidDocsThisMonth = [];

        for (var doc in docs) {
          String status = doc['status'];
          DateTime docDate = (doc['date'] as Timestamp).toDate();

          if (status == 'Verified') {
            owedLectures += (doc['lectures'] as int);
            docsToPay.add(doc);
          } else if (status == 'Paid' && docDate.month == now.month &&
              docDate.year == now.year) {
            paidLecturesThisMonth += (doc['lectures'] as int);
            paidDocsThisMonth.add(doc);
          }
        }

        double owedAmount = owedLectures * rate;
        double paidAmountThisMonth = paidLecturesThisMonth * rate;
        bool isOwed = owedAmount > 0;

        int displayLectures = isOwed ? owedLectures : paidLecturesThisMonth;
        double displayAmount = isOwed ? owedAmount : paidAmountThisMonth;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? colors.cardHighlight : colors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? colors.textMain.withValues(alpha: 0.05) : Colors.transparent),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                // Top Row: Avatar & Profile
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isDark ? const Color(0xFF4A5060) : colors.bgTop,
                      backgroundImage: avatarBase64 != null && avatarBase64!.isNotEmpty ? MemoryImage(base64Decode(avatarBase64!)) : null,
                      child: (avatarBase64 == null || avatarBase64!.isEmpty)
                          ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'F',
                          style: TextStyle(color: colors.textMuted, fontWeight: FontWeight.bold, fontSize: 16))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(color: colors.textMain, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text("Dept: ${dept.toUpperCase()}", style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOwed ? colors.warningBg : colors.successBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isOwed ? colors.warning.withValues(alpha: 0.3) : colors.success.withValues(alpha: 0.3)),
                      ),
                      child: Text(isOwed ? "PENDING" : "PAID UP",
                          style: TextStyle(color: isOwed ? colors.warning : colors.success, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    )
                  ],
                ),

                const SizedBox(height: 16),
                Container(height: 1, color: colors.textMain.withValues(alpha: 0.05)),
                const SizedBox(height: 16),

                // Bottom Row: Amount & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$displayLectures VERIFIED LOG(S)",
                              style: TextStyle(color: colors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text("₹${displayAmount.toStringAsFixed(2)}",
                                style: TextStyle(color: colors.textMain, fontSize: 18, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (isOwed)
                          GestureDetector(
                            onTap: () => _payFaculty(context, uid, docsToPay, name, dept, displayAmount, upiId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: colors.success,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: colors.success.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.account_balance_wallet, color: isDark ? Colors.black : Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text("Pay Now", style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          )
                        else
                          if (paidLecturesThisMonth > 0)
                            GestureDetector(
                              onTap: () {
                                List<List<String>> receiptDetails = [];
                                for (var doc in paidDocsThisMonth) {
                                  final d = doc.data() as Map<String, dynamic>;
                                  DateTime dt = (d['date'] as Timestamp).toDate();
                                  int lecs = d['lectures'] as int;
                                  double rowTotal = lecs * rate;
                                  receiptDetails.add([
                                    DateFormat('dd MMM yyyy').format(dt),
                                    d['subject'] ?? '-',
                                    lecs.toString(),
                                    "₹ ${rate.toStringAsFixed(2)}",
                                    "₹ ${rowTotal.toStringAsFixed(2)}"
                                  ]);
                                }

                                ReceiptService.printReceipt(
                                  facultyName: name,
                                  department: dept,
                                  month: DateFormat('MMMM yyyy').format(DateTime.now()),
                                  totalLectures: displayLectures,
                                  ratePerLecture: rate,
                                  totalAmount: displayAmount,
                                  paymentDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                                  receiptId: "REC-${DateTime.now().millisecondsSinceEpoch}",
                                  lectureDetails: receiptDetails,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                    color: colors.processingBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: colors.processing.withValues(alpha: 0.3))
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.print, color: colors.processing, size: 14),
                                    const SizedBox(width: 6),
                                    Text("Print Slip", style: TextStyle(color: colors.processing, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            )
                          else
                            Text("No dues this month", style: TextStyle(color: colors.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _payFaculty(BuildContext context, String uid, List<QueryDocumentSnapshot> docs, String facultyName, String dept, double amount, String upiId) async {
    final String upiString = upiId.isNotEmpty
        ? "upi://pay?pa=$upiId&pn=${Uri.encodeComponent(facultyName)}&am=${amount.toStringAsFixed(2)}&cu=INR"
        : "";

    bool confirm = await showDialog(
        context: context,
        builder: (c) => AnimatedBuilder( // Wrap Dialog in AnimatedBuilder to catch theme changes
            animation: ThemeManager.instance,
            builder: (context, child) {
              final dialogColors = ThemeManager.instance.colors;
              final dialogIsDark = ThemeManager.instance.isDarkMode;

              return Dialog(
                backgroundColor: dialogColors.card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top Icon
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: dialogColors.successBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.qr_code_scanner, color: dialogColors.success, size: 32),
                            ),
                            const SizedBox(height: 16),

                            // Title & Subtitle
                            Text("Scan to Pay", style: TextStyle(color: dialogColors.textMain, fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text("$facultyName • ${dept.toUpperCase()}", style: TextStyle(color: dialogColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 24),

                            // QR Code Area
                            if (upiId.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: Colors.white, // QR Background MUST ALWAYS BE WHITE for scanning
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 5))
                                    ]
                                ),
                                child: QrImageView(
                                  data: upiString,
                                  version: QrVersions.auto,
                                  size: 160.0,
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black, // QR Modules MUST ALWAYS BE BLACK
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Amount Label & Value
                              Text("AMOUNT TO TRANSFER", style: TextStyle(color: dialogColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              const SizedBox(height: 4),
                              Text("₹${amount.toStringAsFixed(2)}", style: TextStyle(color: dialogColors.success, fontSize: 32, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 16),

                              // UPI ID Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: dialogIsDark ? dialogColors.textMain.withValues(alpha: 0.05) : dialogColors.bgTop,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: dialogIsDark ? dialogColors.textMain.withValues(alpha: 0.1) : Colors.transparent),
                                ),
                                child: Text("UPI ID: $upiId", style: TextStyle(color: dialogColors.textMuted, fontSize: 12)),
                              ),
                            ] else ...[
                              // Missing UPI Warning
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: dialogColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16)),
                                child: Text(
                                    "This faculty has not set up a UPI ID. Pay via cash or bank transfer.",
                                    style: TextStyle(color: dialogColors.error, fontSize: 13, height: 1.4), textAlign: TextAlign.center),
                              )
                            ],

                            const SizedBox(height: 32),

                            // Action Buttons Stacked
                            if (upiId.isNotEmpty) ...[
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final Uri upiUrl = Uri.parse(upiString);
                                        bool launched = await launchUrl(upiUrl, mode: LaunchMode.externalApplication);
                                        if (launched) {
                                          if (context.mounted) Navigator.pop(c, true);
                                        } else {
                                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Could not launch UPI."), backgroundColor: dialogColors.error));
                                        }
                                      } catch (e) {
                                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("No UPI App found."), backgroundColor: dialogColors.error));
                                      }
                                    },
                                    icon: const Icon(Icons.touch_app, size: 18, color: Colors.white),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: dialogColors.processing,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                    label: const Text("Open UPI App", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                  onPressed: () => Navigator.pop(c, true),
                                  icon: Icon(Icons.check_circle, size: 18, color: dialogIsDark ? Colors.black : Colors.white),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: dialogColors.success,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  label: Text("Mark as Paid", style: TextStyle(color: dialogIsDark ? Colors.black : Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Top Right Close "X" Button
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                          icon: Icon(Icons.close, color: dialogColors.textMuted),
                          onPressed: () => Navigator.pop(c, false),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
        )
    ) ?? false;

    if (confirm) {
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in docs) {
        batch.update(doc.reference, {'status': 'Paid'});
      }

      await batch.commit();
      await NotificationService().sendPaymentProcessedNotification(uid: uid, amount: amount);

      if (context.mounted) {
        final currentColors = ThemeManager.instance.colors;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text("Payment Processed Successfully"),
            backgroundColor: currentColors.success));
      }
    }
  }
}

// ============================================================================
// THE BEAUTIFUL FLOATING SEARCH DIALOG (Matches the Dashboard!)
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
                          hintText: "Search a faculty name to pay...",
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
                            final q = query.toLowerCase();
                            return name.contains(q);
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
                              final avatarBase64 = data['avatarBase64'];

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDark ? colors.textMain.withValues(alpha: 0.15) : colors.primary.withValues(alpha: 0.1),
                                  backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
                                  child: (avatarBase64 == null || avatarBase64.isEmpty) ? Icon(Icons.person, color: isDark ? colors.textMain : colors.primary) : null,
                                ),
                                title: Text(name, style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold)),
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