import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_sidebars.dart';
import '../../services/report_service.dart';
import '../../services/receipt_service.dart';

class FacultySalaryHistoryPage extends StatelessWidget {
  const FacultySalaryHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(title: const Text("Salary History"), elevation: 0),
      drawer: isDesktop
          ? null
          : const Drawer(child: FacultySidebar(activeRoute: '/faculty/salary-history')),

      body: Row(
        children: [
          if (isDesktop)
            const FacultySidebar(activeRoute: '/faculty/salary-history'),

          Expanded(
            // ✅ 1. ADDED PULL-TO-REFRESH
            child: RefreshIndicator(
              color: theme.primaryColor,
              backgroundColor: theme.cardColor,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 1200));
              },
              child: SingleChildScrollView(
                // ✅ 2. ALWAYS SCROLLABLE SO YOU CAN DRAG EVEN IF NOT FULL
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Salary History", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text("View monthly earnings and payment status.", style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.print, color: Color(0xff45a182), size: 28),
                          tooltip: "Print Full Statement",
                          onPressed: () async {
                            if (user == null) return;

                            final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                            double hourlyRate = 0.0;
                            String name = 'Faculty Member';
                            String dept = 'General';

                            if (userDoc.exists) {
                              var data = userDoc.data()!;
                              hourlyRate = (data['hourlyRate'] is int)
                                  ? (data['hourlyRate'] as int).toDouble()
                                  : (data['hourlyRate'] as double? ?? 0.0);

                              name = data['name'] ?? 'Faculty Member';
                              dept = data['department'] ?? 'General';
                            }

                            final snapshot = await FirebaseFirestore.instance
                                .collection('attendance')
                                .where('uid', isEqualTo: user.uid)
                                .orderBy('date', descending: true)
                                .get();

                            if (snapshot.docs.isNotEmpty) {
                              double totalPaid = 0.0;
                              for (var doc in snapshot.docs) {
                                if (doc['status'] == 'Paid') {
                                  totalPaid += (doc['lectures'] as int) * hourlyRate;
                                }
                              }

                              ReportService.printHistoryReport(
                                title: "Faculty Statement",
                                subtitle: "Full History of Lectures and Payment Status",
                                docs: snapshot.docs,
                                isAdminReport: false,
                                singleFacultyName: name,
                                singleFacultyDept: dept,
                                singleFacultyRate: hourlyRate,
                                totalAmountPaid: totalPaid,
                              );
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No records to print")));
                              }
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) return const LinearProgressIndicator();

                        final userData = userSnap.data!.data() as Map<String, dynamic>;

                        final double hourlyRate = (userData['hourlyRate'] is int)
                            ? (userData['hourlyRate'] as int).toDouble()
                            : (userData['hourlyRate'] as double? ?? 0.0);

                        final String name = userData['name'] ?? 'Faculty Member';
                        final String dept = userData['department'] ?? 'General';

                        return _buildSalaryContent(context, user.uid, hourlyRate, name, dept);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryContent(BuildContext context, String uid, double hourlyRate, String name, String dept) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: uid)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(context);
        }

        Map<String, List<QueryDocumentSnapshot>> groupedData = {};

        for (var doc in snapshot.data!.docs) {
          Timestamp ts = doc['date'];
          String monthKey = DateFormat('MMMM yyyy').format(ts.toDate());

          if (!groupedData.containsKey(monthKey)) {
            groupedData[monthKey] = [];
          }
          groupedData[monthKey]!.add(doc);
        }

        double totalEarnedYTD = 0;
        double pendingPayment = 0;

        for (var doc in snapshot.data!.docs) {
          int lectures = doc['lectures'];
          String status = doc['status'];
          if (status == 'Paid') {
            totalEarnedYTD += (lectures * hourlyRate);
          } else if (status == 'Verified') {
            pendingPayment += (lectures * hourlyRate);
          }
        }

        return Column(
          children: [
            if (isDesktop)
              Row(
                children: [
                  Expanded(child: _SummaryCard(title: "TOTAL EARNED", value: "\₹${totalEarnedYTD.toStringAsFixed(2)}", icon: Icons.account_balance_wallet, color: Colors.green)),
                  const SizedBox(width: 20),
                  Expanded(child: _SummaryCard(title: "PENDING PAYMENT", value: "\₹${pendingPayment.toStringAsFixed(2)}", icon: Icons.hourglass_empty, color: Colors.orange)),
                ],
              )
            else
              Column(
                children: [
                  _SummaryCard(title: "TOTAL EARNED", value: "\₹${totalEarnedYTD.toStringAsFixed(2)}", icon: Icons.account_balance_wallet, color: Colors.green),
                  const SizedBox(height: 16),
                  _SummaryCard(title: "PENDING PAYMENT", value: "\₹${pendingPayment.toStringAsFixed(2)}", icon: Icons.hourglass_empty, color: Colors.orange),
                ],
              ),

            const SizedBox(height: 32),

            const Align(
                alignment: Alignment.centerLeft,
                child: Text("Monthly Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            ),
            const SizedBox(height: 16),

            ...groupedData.entries.map((entry) {
              return _MonthlyRow(
                month: entry.key,
                docs: entry.value,
                hourlyRate: hourlyRate,
                facultyName: name,
                department: dept,
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
      child: const Center(child: Text("No attendance records found yet.")),
    );
  }
}

class _MonthlyRow extends StatelessWidget {
  final String month;
  final List<QueryDocumentSnapshot> docs;
  final double hourlyRate;
  final String facultyName;
  final String department;

  const _MonthlyRow({
    required this.month,
    required this.docs,
    required this.hourlyRate,
    required this.facultyName,
    required this.department,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    int totalLectures = 0;
    double totalAmount = 0;
    bool hasPending = false;
    bool hasVerified = false;
    bool isAllPaid = true;

    for (var doc in docs) {
      int l = doc['lectures'] as int;
      totalLectures += l;
      totalAmount += (l * hourlyRate);

      String status = doc['status'];
      if (status == 'Pending') { hasPending = true; isAllPaid = false; }
      if (status == 'Verified') { hasVerified = true; isAllPaid = false; }
    }

    String statusText = "Processing";
    Color statusColor = Colors.blue;

    if (isAllPaid) {
      statusText = "Paid";
      statusColor = Colors.green;
    } else if (hasPending) {
      statusText = "Pending Review";
      statusColor = Colors.orange;
    } else if (hasVerified) {
      statusText = "Approved";
      statusColor = Colors.purple;
    }

    Widget leftSide = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8)
          ),
          child: const Icon(Icons.calendar_month, color: Colors.grey),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(month, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
              Text("$totalLectures Lectures Recorded", style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );

    Widget statusPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: isDesktop
          ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: leftSide),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("\₹${totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 24),
              statusPill,
              if (isAllPaid) ...[
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.grey),
                  tooltip: "Download Receipt",
                  onPressed: () => _downloadReceipt(totalLectures, totalAmount),
                )
              ]
            ],
          )
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: leftSide),
              statusPill,
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Earnings:", style: TextStyle(color: Colors.grey)),
              Row(
                children: [
                  Text("\₹${totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (isAllPaid) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.download, color: Colors.grey),
                      tooltip: "Download Receipt",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _downloadReceipt(totalLectures, totalAmount),
                    )
                  ]
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  void _downloadReceipt(int totalLectures, double totalAmount) {
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
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}