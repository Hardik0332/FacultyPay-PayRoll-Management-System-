import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_faculty_page.dart'; // Ensure this matches your file structure

class AdminViewFacultyPage extends StatefulWidget {
  const AdminViewFacultyPage({super.key});

  @override
  State<AdminViewFacultyPage> createState() => _AdminViewFacultyPageState();
}

class _AdminViewFacultyPageState extends State<AdminViewFacultyPage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  final Color successGreen = const Color(0xFF4ADE80);
  final Color pendingOrange = const Color(0xFFFBBF24);
  final Color verifiedBlue = const Color(0xFF60A5FA);

  String _sortOrder = 'default';
  String? _searchUid; // ✅ Added state to track active search

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                        child: _buildListToolbar(),
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
              // ✅ Dynamic Title
              Text(_searchUid == null ? "Manage Faculty" : "Filtered Faculty", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ FIXED SEARCH BUTTON
            GestureDetector(
              onTap: () async {
                final String? selectedUid = await showSearch<String>(
                    context: context,
                    delegate: FacultyRosterSearchDelegate()
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

            // ✅ CLEAR SEARCH BUTTON
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

  Widget _buildListToolbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            "Faculty Roster",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
                color: const Color(0xFF2A2E39),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05))
            ),
            child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                    value: _sortOrder,
                    dropdownColor: const Color(0xFF2A2E39),
                    icon: Icon(Icons.sort, size: 16, color: primaryRed),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: 'default', child: Text("Default")),
                      DropdownMenuItem(value: 'alphabetical', child: Text("A-Z")),
                      DropdownMenuItem(value: 'highest', child: Text("Highest Rate")),
                      DropdownMenuItem(value: 'lowest', child: Text("Lowest Rate")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sortOrder = val);
                    }
                )
            )
        )
      ],
    );
  }

  Widget _buildFacultyList() {
    // ✅ APPLIED SEARCH FILTER
    Query query = FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'faculty');
    if (_searchUid != null) {
      query = query.where('uid', isEqualTo: _searchUid);
    }

    return RefreshIndicator(
      color: primaryRed,
      backgroundColor: const Color(0xFF2A2E39),
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 1200));
        setState(() {}); // Ensure UI updates
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

          List<QueryDocumentSnapshot> docs = snapshot.data!.docs.toList();

          if (docs.isEmpty) {
            return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.group_off_outlined, size: 60, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Center(child: Text("No faculty members found.", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.bold))),
                ]
            );
          }

          if (_sortOrder != 'default') {
            docs.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;

              if (_sortOrder == 'alphabetical') {
                String nameA = (dataA['name'] ?? '').toString().toLowerCase();
                String nameB = (dataB['name'] ?? '').toString().toLowerCase();
                return nameA.compareTo(nameB);
              } else {
                double rateA = (dataA['hourlyRate'] is int) ? (dataA['hourlyRate'] as int).toDouble() : (dataA['hourlyRate'] as double? ?? 0.0);
                double rateB = (dataB['hourlyRate'] is int) ? (dataB['hourlyRate'] as int).toDouble() : (dataB['hourlyRate'] as double? ?? 0.0);

                if (_sortOrder == 'highest') {
                  return rateB.compareTo(rateA);
                } else {
                  return rateA.compareTo(rateB);
                }
              }
            });
          }

          return ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String name = data['name'] ?? 'Unknown';
              final String email = data['email'] ?? 'No Email';
              final String dept = data['department'] ?? 'General';
              final double rate = (data['hourlyRate'] is int) ? (data['hourlyRate'] as int).toDouble() : (data['hourlyRate'] as double? ?? 0.0);
              final String? avatarBase64 = data['avatarBase64'];

              return _buildFacultyCard(doc.id, data, name, email, dept, rate, avatarBase64);
            },
          );
        },
      ),
    );
  }

  Widget _buildFacultyCard(String docId, Map<String, dynamic> data, String name, String email, String dept, double rate, String? avatarBase64) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2E39),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // Top Row: Avatar & Info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF4A5060),
                  backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
                  child: (avatarBase64 == null || avatarBase64.isEmpty)
                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'F', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                  child: Text(dept.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                )
              ],
            ),

            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 16),

            // Bottom Row: Rate & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("HOURLY RATE", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text("₹${rate.toStringAsFixed(2)}", style: TextStyle(color: successGreen, fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Edit Button
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditFacultyPage(facultyId: docId, facultyData: data))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: verifiedBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, color: verifiedBlue, size: 14),
                            const SizedBox(width: 6),
                            Text("Edit", style: TextStyle(color: verifiedBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete Button
                    GestureDetector(
                      onTap: () => _confirmDelete(docId, name),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: primaryRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.delete_outline, color: primaryRed, size: 16),
                      ),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2E39),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Faculty", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to completely remove $name from the system?", style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text("Cancel", style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text("Delete", style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name removed."), backgroundColor: successGreen));
      }
    }
  }
}

// ✅ NEW: Search Delegate specifically for filtering the Roster
class FacultyRosterSearchDelegate extends SearchDelegate<String> {
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
        child: Text("Search faculty by name...", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
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