import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_sidebars.dart';

class AdminViewAttendancePage extends StatelessWidget {
  const AdminViewAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context); // Get theme for refresh spinner

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
        title: const Text("Verify Attendance"),
        elevation: 0,
      ),
      drawer: isDesktop
          ? null
          : const Drawer(
        child: AdminSidebar(activeRoute: '/admin/view-attendance'),
      ),
      body: Row(
        children: [
          if (isDesktop) const AdminSidebar(activeRoute: '/admin/view-attendance'),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop) _TopHeader(),
                Expanded(
                  // ✅ REFRESH WRAPPER APPLIED HERE
                  child: RefreshIndicator(
                    color: theme.primaryColor,
                    backgroundColor: theme.cardColor,
                    onRefresh: () async {
                      await Future.delayed(const Duration(milliseconds: 1200));
                    },
                    child: SingleChildScrollView(
                      // ✅ ALWAYS SCROLLABLE
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(isDesktop ? 32 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Attendance Verification", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          SizedBox(height: 24),

                          // FULL SCREEN TABLE
                          ExpandedAttendanceTable(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExpandedAttendanceTable extends StatelessWidget {
  const ExpandedAttendanceTable({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Error loading data");
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12)
            ),
            child: const Center(child: Text("No attendance records found")),
          );
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: 24,
                      horizontalMargin: 24,
                      headingRowColor: MaterialStateProperty.all(
                          theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade50
                      ),
                      columns: const [
                        DataColumn(label: Text("Faculty Name", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Subject", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Lectures", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final uid = data['uid'] ?? '';
                        final dateVal = data['date'];
                        DateTime date = (dateVal is Timestamp) ? dateVal.toDate() : DateTime.now();
                        final status = data['status'] ?? 'Pending';

                        return DataRow(cells: [
                          DataCell(
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                              builder: (context, userSnap) {
                                if (userSnap.connectionState == ConnectionState.waiting) {
                                  return const Text("Loading...", style: TextStyle(color: Colors.grey));
                                }

                                if (!userSnap.hasData || !userSnap.data!.exists) {
                                  return const Text("Deleted Faculty", style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic));
                                }

                                final userData = userSnap.data!.data() as Map<String, dynamic>?;
                                return Text(userData?['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold));
                              },
                            ),
                          ),
                          DataCell(Text(DateFormat('MMM dd, yyyy').format(date))),
                          DataCell(Text(data['subject'] ?? '-')),
                          DataCell(Text(data['lectures'].toString())),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: status == 'Verified' ? Colors.green.withOpacity(0.1) : (status == 'Paid' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                    color: status == 'Verified' ? Colors.green : (status == 'Paid' ? Colors.blue : Colors.orange),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            status == 'Pending'
                                ? ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                              ),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text("Verify"),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('attendance').doc(doc.id).update({
                                  'status': 'Verified'
                                });
                              },
                            )
                                : const Icon(Icons.check_circle, color: Colors.grey, size: 24),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              }
          ),
        );
      },
    );
  }
}

class _TopHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Faculty Attendance Log", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          CircleAvatar(
              radius: 18,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Text("A", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}