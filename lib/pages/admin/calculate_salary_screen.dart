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

class AdminCalculateSalaryPage extends StatefulWidget {
  const AdminCalculateSalaryPage({super.key});

  @override
  State<AdminCalculateSalaryPage> createState() => _AdminCalculateSalaryPageState();
}

class _AdminCalculateSalaryPageState extends State<AdminCalculateSalaryPage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  final Color successGreen = const Color(0xFF4ADE80);
  final Color pendingOrange = const Color(0xFFFBBF24);
  final Color verifiedBlue = const Color(0xFF60A5FA);

  String? _searchUid; // ✅ Added state to track active search

  @override
  Widget build(BuildContext context) {
    return Stack( // ✅ Removed Scaffold, wrapped in Stack
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_searchUid == null ? "Process Payments" : "Filtered Payments", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Text("Calculate and clear verified logs for faculty.", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                          ],
                        ),
                      ),

                      Expanded(
                        child: _buildFacultyList(),
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
              const Text("Payouts", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ FIXED: Added GestureDetector and SearchDelegate
            GestureDetector(
              onTap: () async {
                final String? selectedUid = await showSearch<String>(
                    context: context,
                    delegate: SalarySearchDelegate()
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

            // ✅ CLEAR FILTER BUTTON
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
                    // ✅ FIXED: Corrected route from '/admin/my-profile' to '/admin/profile'
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

  Widget _buildFacultyList() {
    // ✅ Applied Search Filter
    Query query = FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'faculty');
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

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.account_balance_wallet_outlined, size: 60, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Center(child: Text("No faculty members found.", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.bold))),
                ]
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120), // ✅ Added padding to clear nav bar
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _AdminSalaryCard(facultyDoc: docs[index]);
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

  const _AdminSalaryCard({required this.facultyDoc});

  @override
  Widget build(BuildContext context) {
    final Color successGreen = const Color(0xFF4ADE80);
    final Color pendingOrange = const Color(0xFFFBBF24);
    final Color verifiedBlue = const Color(0xFF60A5FA);

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
              color: const Color(0xFF2A2E39),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                // Top Row: Avatar & Profile
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF4A5060),
                      backgroundImage: avatarBase64 != null &&
                          avatarBase64.isNotEmpty ? MemoryImage(
                          base64Decode(avatarBase64)) : null,
                      child: (avatarBase64 == null || avatarBase64.isEmpty)
                          ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'F',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text("Dept: ${dept.toUpperCase()}", style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOwed
                            ? pendingOrange.withValues(alpha: 0.1)
                            : successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isOwed ? pendingOrange
                            .withValues(alpha: 0.3) : successGreen.withValues(
                            alpha: 0.3)),
                      ),
                      child: Text(isOwed ? "PENDING" : "PAID UP",
                          style: TextStyle(
                              color: isOwed ? pendingOrange : successGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    )
                  ],
                ),

                const SizedBox(height: 16),
                Container(
                    height: 1, color: Colors.white.withValues(alpha: 0.05)),
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
                              style: TextStyle(color: Colors.white.withValues(
                                  alpha: 0.4), fontSize: 9, fontWeight: FontWeight
                                  .bold, letterSpacing: 1)),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text("₹${displayAmount.toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (isOwed)
                          GestureDetector(
                            onTap: () =>
                                _payFaculty(
                                    context,
                                    uid,
                                    docsToPay,
                                    name,
                                    displayAmount,
                                    upiId,
                                    successGreen),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: successGreen,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(color: successGreen.withValues(
                                      alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet,
                                      color: Colors.black, size: 14),
                                  const SizedBox(width: 6),
                                  const Text("Pay Now", style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
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
                                  DateTime dt = (d['date'] as Timestamp)
                                      .toDate();
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
                                  month: DateFormat('MMMM yyyy').format(
                                      DateTime.now()),
                                  totalLectures: displayLectures,
                                  ratePerLecture: rate,
                                  totalAmount: displayAmount,
                                  paymentDate: DateFormat('yyyy-MM-dd').format(
                                      DateTime.now()),
                                  receiptId: "REC-${DateTime
                                      .now()
                                      .millisecondsSinceEpoch}",
                                  lectureDetails: receiptDetails,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                    color: verifiedBlue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: verifiedBlue.withValues(
                                            alpha: 0.5))
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.print, color: verifiedBlue,
                                        size: 14),
                                    const SizedBox(width: 6),
                                    Text("Print Slip", style: TextStyle(
                                        color: verifiedBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            )
                          else
                            Text("No dues this month", style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 11,
                                fontStyle: FontStyle.italic)),
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

  Future<void> _payFaculty(BuildContext context, String uid,
      List<QueryDocumentSnapshot> docs, String facultyName, double amount,
      String upiId, Color successGreen) async {
    final String upiString = upiId.isNotEmpty
        ? "upi://pay?pa=$upiId&pn=${Uri.encodeComponent(
        facultyName)}&am=${amount.toStringAsFixed(2)}&cu=INR"
        : "";

    bool confirm = await showDialog(
        context: context,
        builder: (c) =>
            AlertDialog(
              backgroundColor: const Color(0xFF2A2E39),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.05))
              ),
              title: Text("Pay $facultyName", style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Amount Due: ₹${amount.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: successGreen)),
                    const SizedBox(height: 4),
                    Text("Total Verified Lectures: ${docs.length}",
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12)),

                    if (upiId.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text("Scan to Pay", style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                      const SizedBox(height: 8),
                      Text("Use GPay, PhonePe, or Paytm on your phone",
                          style: TextStyle(fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.5)),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),

                      Container(
                        width: 200,
                        height: 200,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: successGreen
                                .withValues(alpha: 0.2), blurRadius: 20)
                            ]
                        ),
                        child: QrImageView(
                          data: upiString,
                          version: QrVersions.auto,
                          size: 180.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ] else
                      ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE05B5C).withValues(
                                  alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Text(
                              "This faculty has not set up a UPI ID. Pay via cash or bank transfer.",
                              style: TextStyle(color: const Color(0xFFE05B5C),
                                  fontSize: 12,
                                  height: 1.4), textAlign: TextAlign.center),
                        )
                      ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text("Cancel", style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5)))
                ),

                if (upiId.isNotEmpty)
                  ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final Uri upiUrl = Uri.parse(upiString);
                          if (await canLaunchUrl(upiUrl)) {
                            await launchUrl(
                                upiUrl, mode: LaunchMode.externalApplication);
                            if (context.mounted) Navigator.pop(c, true);
                          } else {
                            if (context.mounted) ScaffoldMessenger
                                .of(context)
                                .showSnackBar(const SnackBar(content: Text(
                                "No UPI App found on this device.")));
                          }
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger
                              .of(context)
                              .showSnackBar(const SnackBar(
                              content: Text("Could not open UPI.")));
                        }
                      },
                      icon: const Icon(
                          Icons.touch_app, size: 16, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF60A5FA),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      label: const Text("Open UPI", style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))
                  ),

                ElevatedButton(
                    onPressed: () => Navigator.pop(c, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: successGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: const Text("Mark as Paid", style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold))
                ),
              ],
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text("Payment Processed Successfully"),
            backgroundColor: successGreen));
      }
    }
  }
}

// ✅ NEW: Search Delegate to filter Faculty for Payments
class SalarySearchDelegate extends SearchDelegate<String> {
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
          onPressed: () => query = '',
        )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(
        child: Text("Search a faculty name to pay...", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
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
          final q = query.toLowerCase();
          return name.contains(q);
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
            final avatarBase64 = data['avatarBase64'];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
                child: (avatarBase64 == null || avatarBase64.isEmpty) ? const Icon(Icons.person, color: Colors.white) : null,
              ),
              title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: () {
                close(context, data['uid'] ?? docs[index].id);
              },
            );
          },
        );
      },
    );
  }
}