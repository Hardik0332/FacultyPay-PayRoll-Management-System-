import 'package:animations/animations.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/theme_manager.dart'; // ✅ Added ThemeManager
import 'edit_faculty_page.dart'; // Ensure this matches your file structure

class AdminViewFacultyPage extends StatefulWidget {
  const AdminViewFacultyPage({super.key});

  @override
  State<AdminViewFacultyPage> createState() => _AdminViewFacultyPageState();
}

class _AdminViewFacultyPageState extends State<AdminViewFacultyPage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  String _sortOrder = 'default';
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

              // 2. Main Content
              SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: _buildHeader(colors, isDark),
                        ),

                        // Main List Container
                        Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colors.card, // ✅ DYNAMIC
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 16),
                                  child: _buildListToolbar(colors, isDark),
                                ),

                                _buildFacultyList(colors, isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
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
              Text(_searchUid == null ? "Manage Faculty" : "Filtered Faculty", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colors.textMain, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
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

            // Search Dialog Trigger
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

            // Clear Search Button
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

  Widget _buildListToolbar(AppColors colors, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            "Faculty Roster",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textMain, letterSpacing: 0.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2E39) : colors.bgTop,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? colors.textMain.withValues(alpha: 0.05) : Colors.transparent)
            ),
            child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                    value: _sortOrder,
                    dropdownColor: colors.card,
                    icon: Icon(Icons.sort, size: 16, color: colors.primary),
                    style: TextStyle(color: colors.textMain, fontSize: 12, fontWeight: FontWeight.bold),
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

          List<QueryDocumentSnapshot> docs = snapshot.data!.docs.toList();

          if (docs.isEmpty) {
            return ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.group_off_outlined, size: 60, color: colors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Center(child: Text("No faculty members found.", style: TextStyle(color: colors.textMuted, fontSize: 16, fontWeight: FontWeight.bold))),
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
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String name = data['name'] ?? 'Unknown';
              final String email = data['email'] ?? 'No Email';
              final String dept = data['department'] ?? 'General';
              final double rate = (data['hourlyRate'] is int) ? (data['hourlyRate'] as int).toDouble() : (data['hourlyRate'] as double? ?? 0.0);
              final String? avatarBase64 = data['avatarBase64'];

              return _buildFacultyCard(doc.id, data, name, email, dept, rate, avatarBase64, colors, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildFacultyCard(String docId, Map<String, dynamic> data, String name, String email, String dept, double rate, String? avatarBase64, AppColors colors, bool isDark) {
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
            // Top Row: Avatar & Info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isDark ? const Color(0xFF4A5060) : colors.bgTop,
                  backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
                  child: (avatarBase64 == null || avatarBase64.isEmpty)
                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'F', style: TextStyle(color: colors.textMuted, fontWeight: FontWeight.bold, fontSize: 20))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(color: colors.textMain, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(email, style: TextStyle(color: colors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: isDark ? colors.textMain.withValues(alpha: 0.05) : colors.bgTop, borderRadius: BorderRadius.circular(8)),
                  child: Text(dept.toUpperCase(), style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                )
              ],
            ),

            const SizedBox(height: 16),
            Container(height: 1, color: colors.textMain.withValues(alpha: 0.05)),
            const SizedBox(height: 16),

            // Bottom Row: Rate & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("HOURLY RATE", style: TextStyle(color: colors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text("₹${rate.toStringAsFixed(2)}", style: TextStyle(color: colors.primary, fontSize: 16, fontWeight: FontWeight.w900)),
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
                        decoration: BoxDecoration(color: colors.processing.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, color: colors.processing, size: 14),
                            const SizedBox(width: 6),
                            Text("Edit", style: TextStyle(color: colors.processing, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete Button
                    GestureDetector(
                      onTap: () => _confirmDelete(docId, name, colors, isDark),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.delete_outline, color: colors.error, size: 16),
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

  Future<void> _confirmDelete(String docId, String name, AppColors colors, bool isDark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Faculty", style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to completely remove $name from the system?", style: TextStyle(color: colors.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text("Cancel", style: TextStyle(color: colors.textMuted))
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text("Delete", style: TextStyle(color: colors.error, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name removed."), backgroundColor: colors.success));
      }
    }
  }
}

// ============================================================================
// THE BEAUTIFUL FLOATING SEARCH DIALOG
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
                          hintText: "Search faculty by name...",
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



