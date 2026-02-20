import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_sidebars.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
        title: const Text("Admin Panel"),
        elevation: 0,
      ),
      drawer: isDesktop
          ? null
          : const Drawer(
        child: AdminSidebar(activeRoute: '/admin/dashboard'),
      ),
      body: Row(
        children: [
          if (isDesktop) const AdminSidebar(activeRoute: '/admin/dashboard'),

          // MAIN CONTENT
          Expanded(
            // ✅ 1. Wrap the content in a RefreshIndicator
            child: RefreshIndicator(
              color: theme.primaryColor,
              backgroundColor: theme.cardColor,
              onRefresh: () async {
                // Firebase StreamBuilders are already live!
                // This delay just provides a satisfying UX pull-to-refresh animation.
                await Future.delayed(const Duration(milliseconds: 1200));
              },
              child: SingleChildScrollView(
                // ✅ 2. Required so the user can drag down even if the page isn't full
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Admin Dashboard", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),

                    // REAL-TIME STATS RESPONSIVE
                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(
                              child: _StatCard(
                                  title: "Faculty Members",
                                  queryStream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'faculty').snapshots(),
                                  color: const Color(0xff45a182),
                                  icon: Icons.group
                              )
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _StatCard(
                                  title: "Attendance Records",
                                  queryStream: FirebaseFirestore.instance.collection('attendance').snapshots(),
                                  color: Colors.purple,
                                  icon: Icons.library_books
                              )
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                              child: _PendingSalaryCard()
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _StatCard(
                              title: "Faculty Members",
                              queryStream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'faculty').snapshots(),
                              color: const Color(0xff45a182),
                              icon: Icons.group
                          ),
                          const SizedBox(height: 16),
                          _StatCard(
                              title: "Attendance Records",
                              queryStream: FirebaseFirestore.instance.collection('attendance').snapshots(),
                              color: Colors.purple,
                              icon: Icons.library_books
                          ),
                          const SizedBox(height: 16),
                          const _PendingSalaryCard(),
                        ],
                      ),

                    const SizedBox(height: 32),
                    const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),

                    // QUICK ACTIONS RESPONSIVE
                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(child: _QuickAction(icon: Icons.person_add, title: "Add New Faculty", onTap: () => Navigator.pushReplacementNamed(context, '/admin/add-faculty'))),
                          const SizedBox(width: 16),
                          Expanded(child: _QuickAction(icon: Icons.check_circle, title: "Verify Attendance", onTap: () => Navigator.pushReplacementNamed(context, '/admin/view-attendance'))),
                          const SizedBox(width: 16),
                          Expanded(child: _QuickAction(icon: Icons.payments, title: "Process Payments", onTap: () => Navigator.pushReplacementNamed(context, '/admin/calculate-salary'))),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _QuickAction(icon: Icons.person_add, title: "Add New Faculty", onTap: () => Navigator.pushReplacementNamed(context, '/admin/add-faculty')),
                          const SizedBox(height: 16),
                          _QuickAction(icon: Icons.check_circle, title: "Verify Attendance", onTap: () => Navigator.pushReplacementNamed(context, '/admin/view-attendance')),
                          const SizedBox(height: 16),
                          _QuickAction(icon: Icons.payments, title: "Process Payments", onTap: () => Navigator.pushReplacementNamed(context, '/admin/calculate-salary')),
                        ],
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
}

// ================= CUSTOM WIDGET FOR CALCULATING PENDING SALARY =================
class _PendingSalaryCard extends StatelessWidget {
  const _PendingSalaryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Colors.orange;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('attendance').where('status', isEqualTo: 'Verified').snapshots(),
      builder: (context, attendanceSnap) {
        if (!attendanceSnap.hasData) return _buildUI(theme, "...", color);

        Map<String, int> pendingLecturesPerUser = {};
        for (var doc in attendanceSnap.data!.docs) {
          String uid = doc['uid'];
          int lectures = doc['lectures'];
          pendingLecturesPerUser[uid] = (pendingLecturesPerUser[uid] ?? 0) + lectures;
        }

        if (pendingLecturesPerUser.isEmpty) return _buildUI(theme, "₹0.00", color);

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'faculty').get(),
          builder: (context, usersSnap) {
            if (!usersSnap.hasData) return _buildUI(theme, "...", color);

            double totalPendingAmount = 0.0;
            for (var userDoc in usersSnap.data!.docs) {
              String uid = userDoc.id;
              if (pendingLecturesPerUser.containsKey(uid)) {
                var rawRate = userDoc['hourlyRate'];
                double rate = (rawRate is int) ? rawRate.toDouble() : (rawRate as double? ?? 0.0);
                totalPendingAmount += pendingLecturesPerUser[uid]! * rate;
              }
            }

            return _buildUI(theme, "₹${totalPendingAmount.toStringAsFixed(2)}", color);
          },
        );
      },
    );
  }

  Widget _buildUI(ThemeData theme, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Pending Payments", style: TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(Icons.account_balance_wallet, color: color)),
        ],
      ),
    );
  }
}

// ================= STANDARD STAT CARD =================
class _StatCard extends StatelessWidget {
  final String title;
  final Stream<QuerySnapshot> queryStream;
  final Color color;
  final IconData icon;

  const _StatCard({required this.title, required this.queryStream, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: queryStream,
      builder: (context, snapshot) {
        String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text(count, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
            ],
          ),
        );
      },
    );
  }
}

// ================= QUICK ACTION BUTTON =================
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xff45a182)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}