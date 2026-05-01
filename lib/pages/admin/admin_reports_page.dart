import 'package:animations/animations.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../theme/theme_manager.dart'; // ✅ Added ThemeManager
import '../../services/report_service.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  String? selectedFacultyId; // Null means "All Faculty"
  Map<String, String> facultyNames = {};
  Map<String, double> facultyRates = {};
  bool isLoading = false;

  // Time Period Filtering State
  String _reportPeriod = 'All Time';
  DateTime _selectedMonth = DateTime.now();
  String _selectedFY = '';

  @override
  void initState() {
    super.initState();
    _fetchFacultyData();
    _initializeFinancialYears();
  }

  void _initializeFinancialYears() {
    int currentYear = DateTime.now().year;
    int currentMonth = DateTime.now().month;
    int startYear = currentMonth < 4 ? currentYear - 1 : currentYear;
    _selectedFY = "$startYear-${startYear + 1}";
  }

  List<String> _getFinancialYearOptions() {
    int currentYear = DateTime.now().year;
    return [
      "${currentYear - 2}-${currentYear - 1}",
      "${currentYear - 1}-$currentYear",
      "$currentYear-${currentYear + 1}",
    ];
  }

  Future<void> _fetchFacultyData() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'faculty').get();
    final Map<String, String> tempNames = {};
    final Map<String, double> tempRates = {};

    for (var doc in snapshot.docs) {
      tempNames[doc.id] = doc['name'] ?? 'Unknown';
      tempRates[doc.id] = (doc['hourlyRate'] is int)
          ? (doc['hourlyRate'] as int).toDouble()
          : (doc['hourlyRate'] as double? ?? 0.0);
    }

    if (mounted) {
      setState(() {
        facultyNames = tempNames;
        facultyRates = tempRates;
      });
    }
  }

  Future<void> _pickMonth(AppColors colors, bool isDark) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      helpText: "Select any day in the desired month",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(primary: colors.primary, onPrimary: Colors.white, surface: colors.card, onSurface: colors.textMain)
                : ColorScheme.light(primary: colors.primary, onPrimary: Colors.white, surface: colors.card, onSurface: colors.textMain),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedMonth = picked);
    }
  }

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

                        // Main Form Container
                        Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colors.card, // ✅ DYNAMIC
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
                            ),
                            child: RefreshIndicator(
                              color: colors.primary,
                              backgroundColor: colors.cardHighlight,
                              onRefresh: _fetchFacultyData,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 120),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Generate Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textMain)),
                                    const SizedBox(height: 4),
                                    Text("Export attendance and payment liability as PDF.", style: TextStyle(color: colors.textMuted, fontSize: 13)),
                                    const SizedBox(height: 24),

                                    _buildFilterCard(colors, isDark),
                                  ],
                                ),
                              ),
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
              Text("Reports", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colors.textMain, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
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

            // Search Dialog Button
            GestureDetector(
              onTap: () async {
                final String? selectedUid = await showDialog<String>(
                  context: context,
                  builder: (context) => const FacultySearchDialog(),
                );
                if (selectedUid != null && selectedUid.isNotEmpty) {
                  setState(() {
                    selectedFacultyId = selectedUid; // Updates the dropdown!
                  });
                }
              },
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isDark ? colors.textMain.withValues(alpha: 0.15) : colors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.search, color: isDark ? Colors.white : colors.primary, size: 20)
              ),
            ),
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

  Widget _buildFilterCard(AppColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colors.cardHighlight : colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? colors.textMain.withValues(alpha: 0.05) : Colors.transparent),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFacultyDropdown(colors, isDark),
          const SizedBox(height: 20),
          _buildPeriodDropdown(colors, isDark),
          const SizedBox(height: 20),
          _buildDynamicDateFilter(colors, isDark),
          const SizedBox(height: 32),
          _buildPrintButton(colors),
        ],
      ),
    );
  }

  Widget _buildFacultyDropdown(AppColors colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Target Faculty", style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedFacultyId,
          isExpanded: true,
          dropdownColor: colors.card,
          style: TextStyle(color: colors.textMain, fontSize: 15),
          icon: Icon(Icons.arrow_drop_down, color: colors.textMuted),
          decoration: InputDecoration(
            hintText: "Select Faculty",
            hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.5)),
            prefixIcon: Icon(Icons.people_outline, color: colors.textMuted, size: 20),
            filled: true,
            fillColor: isDark ? colors.textMain.withValues(alpha: 0.03) : colors.bgTop,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? colors.textMain.withValues(alpha: 0.1) : Colors.transparent)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary, width: 1.5)),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text("All Faculty (Master Report)", overflow: TextOverflow.ellipsis)),
            ...facultyNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (val) => setState(() => selectedFacultyId = val),
        ),
      ],
    );
  }

  Widget _buildPeriodDropdown(AppColors colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Time Period", style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _reportPeriod,
          isExpanded: true,
          dropdownColor: colors.card,
          style: TextStyle(color: colors.textMain, fontSize: 15),
          icon: Icon(Icons.arrow_drop_down, color: colors.textMuted),
          decoration: InputDecoration(
            hintText: "Select Period",
            hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.5)),
            prefixIcon: Icon(Icons.date_range, color: colors.textMuted, size: 20),
            filled: true,
            fillColor: isDark ? colors.textMain.withValues(alpha: 0.03) : colors.bgTop,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? colors.textMain.withValues(alpha: 0.1) : Colors.transparent)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary, width: 1.5)),
          ),
          items: const [
            DropdownMenuItem(value: 'All Time', child: Text("All Time")),
            DropdownMenuItem(value: 'Monthly', child: Text("Monthly")),
            DropdownMenuItem(value: 'Financial Year', child: Text("Financial Year")),
          ],
          onChanged: (val) => setState(() => _reportPeriod = val ?? 'All Time'),
        ),
      ],
    );
  }

  Widget _buildDynamicDateFilter(AppColors colors, bool isDark) {
    if (_reportPeriod == 'Monthly') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Select Month", style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickMonth(colors, isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? colors.textMain.withValues(alpha: 0.03) : colors.bgTop,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? colors.textMain.withValues(alpha: 0.05) : Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, color: colors.textMuted, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(DateFormat('MMMM yyyy').format(_selectedMonth), style: TextStyle(color: colors.textMain, fontSize: 15), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Icon(Icons.edit, color: colors.textMuted, size: 18),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (_reportPeriod == 'Financial Year') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Select Financial Year", style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedFY,
            dropdownColor: colors.card,
            style: TextStyle(color: colors.textMain, fontSize: 15),
            icon: Icon(Icons.arrow_drop_down, color: colors.textMuted),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.account_balance, color: colors.textMuted, size: 20),
              filled: true,
              fillColor: isDark ? colors.textMain.withValues(alpha: 0.03) : colors.bgTop,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? colors.textMain.withValues(alpha: 0.05) : Colors.transparent)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary, width: 1.5)),
            ),
            items: _getFinancialYearOptions().map((fy) => DropdownMenuItem(value: fy, child: Text("FY $fy"))).toList(),
            onChanged: (val) => setState(() => _selectedFY = val!),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPrintButton(AppColors colors) {
    return GestureDetector(
      onTap: isLoading ? null : () => _generateReport(colors),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isLoading ? colors.primary.withValues(alpha: 0.5) : colors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.print, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("Generate PDF Report", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  // --- REPORT GENERATION LOGIC ---
  Future<void> _generateReport(AppColors colors) async {
    setState(() => isLoading = true);

    try {
      Query query = FirebaseFirestore.instance.collection('attendance');

      String reportTitle = "Master Attendance Report";
      String subTitle = "All Faculty Records";

      if (selectedFacultyId != null) {
        query = query.where('uid', isEqualTo: selectedFacultyId);
        reportTitle = "Individual Attendance Report";
        subTitle = "Faculty: ${facultyNames[selectedFacultyId] ?? 'Unknown'}";
      }

      DateTime? startDate;
      DateTime? endDate;

      if (_reportPeriod == 'Monthly') {
        startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
        subTitle += "  |  Period: ${DateFormat('MMMM yyyy').format(_selectedMonth)}";
      }
      else if (_reportPeriod == 'Financial Year') {
        int startYr = int.parse(_selectedFY.split('-')[0]);
        int endYr = int.parse(_selectedFY.split('-')[1]);
        startDate = DateTime(startYr, 4, 1);
        endDate = DateTime(endYr, 3, 31, 23, 59, 59);
        subTitle += "  |  Period: FY $_selectedFY";
      }

      if (startDate != null && endDate != null) {
        query = query
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('date', descending: true);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("No records found for this selection."), backgroundColor: colors.warning));
      } else {

        double totalPaidAmount = 0.0;
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'Paid' || data['status'] == 'Completed') {
            final uid = data['uid'] ?? '';
            final rate = facultyRates[uid] ?? 0.0;
            final lectures = data['lectures'] as int;
            totalPaidAmount += (lectures * rate);
          }
        }

        await ReportService.printHistoryReport(
          title: reportTitle,
          subtitle: subTitle,
          docs: snapshot.docs,
          isAdminReport: true,
          facultyNames: facultyNames,
          totalAmountPaid: totalPaidAmount,
        );
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: colors.error));
    } finally {
      if(mounted) setState(() => isLoading = false);
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
                          hintText: "Search faculty by name or email...",
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
                            final email = (data['email'] ?? '').toString().toLowerCase();
                            final q = query.toLowerCase();
                            return name.contains(q) || email.contains(q);
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
                              final email = data['email'] ?? 'No email';
                              final avatarBase64 = data['avatarBase64'];

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDark ? colors.textMain.withValues(alpha: 0.15) : colors.primary.withValues(alpha: 0.1),
                                  backgroundImage: avatarBase64 != null && avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
                                  child: (avatarBase64 == null || avatarBase64.isEmpty) ? Icon(Icons.person, color: isDark ? colors.textMain : colors.primary) : null,
                                ),
                                title: Text(name, style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold)),
                                subtitle: Text(email, style: TextStyle(color: colors.textMuted)),
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
