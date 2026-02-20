import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_sidebars.dart';

class FacultyDashboard extends StatelessWidget {
  const FacultyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
        title: const Text("Faculty Portal"),
        elevation: 0,
      ),
      drawer: isDesktop
          ? null
          : const Drawer(
        child: FacultySidebar(activeRoute: '/faculty/dashboard'),
      ),
      body: Row(
        children: [
          if (isDesktop) const FacultySidebar(activeRoute: '/faculty/dashboard'),

          // MAIN CONTENT
          Expanded(
            // ✅ 1. Wrap the content in a RefreshIndicator
            child: RefreshIndicator(
              color: theme.primaryColor,
              backgroundColor: theme.cardColor,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 1200));
              },
              child: SingleChildScrollView(
                // ✅ 2. Always scrollable physics
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, user),
                    const SizedBox(height: 32),
                    _buildStatsRow(user, isDesktop),
                    const SizedBox(height: 32),
                    const Text("Recent Attendance History",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildRecentActivityTable(context, user),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String name = "Faculty Member";
        if (snapshot.hasData && snapshot.data!.exists) {
          name = snapshot.data!['name'] ?? "Faculty Member";
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome back, $name",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Here is your performance summary for this month.",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, color: theme.primaryColor),
            )
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(User? user, bool isDesktop) {
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        int totalLectures = 0;
        int verifiedLectures = 0;

        for (var doc in snapshot.data!.docs) {
          totalLectures += (doc['lectures'] as int);
          if (doc['status'] == 'Verified' || doc['status'] == 'Paid') {
            verifiedLectures += (doc['lectures'] as int);
          }
        }

        return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnap) {
              double rate = 0;
              if (userSnap.hasData && userSnap.data!.exists) {
                rate = (userSnap.data!['hourlyRate'] ?? 0).toDouble();
              }
              double earnings = verifiedLectures * rate;

              if (!isDesktop) {
                return Column(
                  children: [
                    _StatCard(title: "Total Earnings", value: "\₹${earnings.toStringAsFixed(2)}", icon: Icons.currency_rupee, color: const Color(0xff45a182)),
                    const SizedBox(height: 16),
                    _StatCard(title: "Total Lectures", value: "$totalLectures", icon: Icons.class_outlined, color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    _StatCard(title: "Hourly Rate", value: "\₹${rate.toStringAsFixed(0)}", icon: Icons.access_time, color: Colors.orangeAccent),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: _StatCard(title: "Total Earnings", value: "\₹${earnings.toStringAsFixed(2)}", icon: Icons.currency_rupee, color: const Color(0xff45a182))),
                  const SizedBox(width: 20),
                  Expanded(child: _StatCard(title: "Total Lectures", value: "$totalLectures", icon: Icons.class_outlined, color: Colors.blueAccent)),
                  const SizedBox(width: 20),
                  Expanded(child: _StatCard(title: "Hourly Rate", value: "\₹${rate.toStringAsFixed(0)}", icon: Icons.access_time, color: Colors.orangeAccent)),
                ],
              );
            });
      },
    );
  }

  Widget _buildRecentActivityTable(BuildContext context, User? user) {
    final theme = Theme.of(context);

    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
            child: const Text("No attendance records found. Start by adding one!", style: TextStyle(color: Colors.grey)),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              DateTime date = (data['date'] as Timestamp).toDate();
              String status = data['status'] ?? 'Pending';
              Color statusColor = status == 'Verified' || status == 'Paid' ? Colors.green : Colors.orange;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                title: Text(DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text("${data['lectures']} Lecture(s) • ${data['subject'] ?? '-'}"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}