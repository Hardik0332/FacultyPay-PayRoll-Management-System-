import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Make sure you have this import pointing to your actual service file!
import '../../services/report_service.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  final Color successGreen = const Color(0xFF4ADE80);
  final Color pendingOrange = const Color(0xFFFBBF24);
  final Color verifiedBlue = const Color(0xFF60A5FA);

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

  Future<void> _pickMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      helpText: "Select any day in the desired month",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryRed,
              onPrimary: Colors.white,
              surface: const Color(0xFF282C37),
              onSurface: Colors.white,
            ),
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

              // Main Form Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF242832),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: RefreshIndicator(
                    color: primaryRed,
                    backgroundColor: const Color(0xFF2A2E39),
                    onRefresh: _fetchFacultyData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Generate Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text("Export attendance and payment liability as PDF.", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                          const SizedBox(height: 24),

                          _buildFilterCard(),
                        ],
                      ),
                    ),
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
              const Text("Reports", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ FIXED: Added SearchDelegate to instantly pick a faculty for the dropdown
            GestureDetector(
              onTap: () async {
                final String? selectedUid = await showSearch<String>(
                  context: context,
                  delegate: ReportsSearchDelegate(),
                );
                if (selectedUid != null && selectedUid.isNotEmpty) {
                  setState(() {
                    selectedFacultyId = selectedUid; // Updates the dropdown!
                  });
                }
              },
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.search, color: Colors.white, size: 20)
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

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2E39),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFacultyDropdown(),
          const SizedBox(height: 20),
          _buildPeriodDropdown(),
          const SizedBox(height: 20),
          _buildDynamicDateFilter(),
          const SizedBox(height: 32),
          _buildPrintButton(),
        ],
      ),
    );
  }

  Widget _buildFacultyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Target Faculty", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedFacultyId,
          isExpanded: true,
          dropdownColor: const Color(0xFF2A2E39),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.5)),
          decoration: InputDecoration(
            hintText: "Select Faculty",
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            prefixIcon: Icon(Icons.people_outline, color: Colors.white.withValues(alpha: 0.5), size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryRed, width: 1.5)),
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

  Widget _buildPeriodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Time Period", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _reportPeriod,
          isExpanded: true,
          dropdownColor: const Color(0xFF2A2E39),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.5)),
          decoration: InputDecoration(
            hintText: "Select Period",
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            prefixIcon: Icon(Icons.date_range, color: Colors.white.withValues(alpha: 0.5), size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryRed, width: 1.5)),
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

  Widget _buildDynamicDateFilter() {
    if (_reportPeriod == 'Monthly') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Select Month", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, color: Colors.white.withValues(alpha: 0.5), size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(DateFormat('MMMM yyyy').format(_selectedMonth), style: const TextStyle(color: Colors.white, fontSize: 15), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Icon(Icons.edit, color: Colors.white.withValues(alpha: 0.3), size: 18),
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
          Text("Select Financial Year", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedFY,
            dropdownColor: const Color(0xFF2A2E39),
            style: const TextStyle(color: Colors.white, fontSize: 15),
            icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.5)),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.account_balance, color: Colors.white.withValues(alpha: 0.5), size: 20),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.03),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryRed, width: 1.5)),
            ),
            items: _getFinancialYearOptions().map((fy) => DropdownMenuItem(value: fy, child: Text("FY $fy"))).toList(),
            onChanged: (val) => setState(() => _selectedFY = val!),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPrintButton() {
    return GestureDetector(
      onTap: isLoading ? null : _generateReport,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isLoading ? successGreen.withValues(alpha: 0.5) : successGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: successGreen.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.print, color: Colors.black, size: 20),
              SizedBox(width: 8),
              Text("Generate PDF Report", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  // --- REPORT GENERATION LOGIC ---
  Future<void> _generateReport() async {
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
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No records found for this selection.")));
      } else {

        double totalPaidAmount = 0.0;
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'Paid') {
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
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }
}

// ✅ NEW: Custom Search Delegate to find Faculty and select them in the Dropdown
class ReportsSearchDelegate extends SearchDelegate<String> {
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
        child: Text("Search faculty by name for report...", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
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