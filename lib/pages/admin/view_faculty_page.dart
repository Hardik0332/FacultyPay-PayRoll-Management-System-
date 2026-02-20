import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/app_sidebars.dart';
import 'edit_faculty_page.dart';

class ViewFacultyPage extends StatefulWidget {
  const ViewFacultyPage({super.key});

  @override
  State<ViewFacultyPage> createState() => _ViewFacultyPageState();
}

class _ViewFacultyPageState extends State<ViewFacultyPage> {
  String _sortOrder = 'default';

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
        title: const Text("View Faculty"),
        elevation: 0,
      ),
      drawer: isDesktop
          ? null
          : const Drawer(
        child: AdminSidebar(activeRoute: '/admin/view-faculty'),
      ),
      body: Row(
        children: [
          if (isDesktop) const AdminSidebar(activeRoute: '/admin/view-faculty'),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 32 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Faculty Members",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.withOpacity(0.3))
                          ),
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                  value: _sortOrder,
                                  dropdownColor: theme.cardColor,
                                  icon: Icon(Icons.sort, size: 18, color: theme.primaryColor),
                                  items: const [
                                    DropdownMenuItem(value: 'default', child: Text("Sort: Default")),
                                    DropdownMenuItem(value: 'highest', child: Text("Highest Salary")),
                                    DropdownMenuItem(value: 'lowest', child: Text("Lowest Salary")),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _sortOrder = val);
                                    }
                                  }
                              )
                          )
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  Expanded(
                    // ✅ WRAPPED LIST IN REFRESH INDICATOR
                    child: RefreshIndicator(
                      color: theme.primaryColor,
                      backgroundColor: theme.cardColor,
                      onRefresh: () async {
                        await Future.delayed(const Duration(milliseconds: 1200));
                      },
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'faculty')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) return const Center(child: Text("Error loading data"));
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                          List<QueryDocumentSnapshot> docs = snapshot.data!.docs.toList();

                          if (docs.isEmpty) {
                            return ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(12)
                                    ),
                                    child: const Center(
                                      child: Text("No faculty members found.\nGo to 'Add Faculty' to create one.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                    ),
                                  )
                                ]
                            );
                          }

                          if (_sortOrder != 'default') {
                            docs.sort((a, b) {
                              final dataA = a.data() as Map<String, dynamic>;
                              final dataB = b.data() as Map<String, dynamic>;
                              double rateA = (dataA['hourlyRate'] is int) ? (dataA['hourlyRate'] as int).toDouble() : (dataA['hourlyRate'] as double? ?? 0.0);
                              double rateB = (dataB['hourlyRate'] is int) ? (dataB['hourlyRate'] as int).toDouble() : (dataB['hourlyRate'] as double? ?? 0.0);

                              if (_sortOrder == 'highest') {
                                return rateB.compareTo(rateA);
                              } else {
                                return rateA.compareTo(rateB);
                              }
                            });
                          }

                          return ListView.separated(
                            // ✅ ENABLES DRAG DOWN GESTURE
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final String name = data['name'] ?? 'Unknown';
                              final String email = data['email'] ?? 'No Email';
                              final String dept = data['department'] ?? 'General';
                              final double rate = (data['hourlyRate'] is int) ? (data['hourlyRate'] as int).toDouble() : (data['hourlyRate'] as double? ?? 0.0);

                              Widget profileInfo = Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'F', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4)
                                          ),
                                          child: Text("Dept: ${dept.toUpperCase()}", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );

                              Widget actionInfo = Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("₹ ${rate.toStringAsFixed(2)} / hr", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.primaryColor)),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    tooltip: "Edit Faculty",
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditFacultyPage(facultyId: doc.id, facultyData: data))),
                                  ),
                                  IconButton(
                                    tooltip: "Delete Faculty",
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: theme.cardColor,
                                          title: const Text("Delete Faculty?"),
                                          content: Text("Are you sure you want to remove $name?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) await FirebaseFirestore.instance.collection('users').doc(doc.id).delete();
                                    },
                                  ),
                                ],
                              );

                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                                ),
                                child: isDesktop
                                    ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: profileInfo), actionInfo])
                                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [profileInfo, const SizedBox(height: 16), Align(alignment: Alignment.centerRight, child: actionInfo)]),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}