import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_sidebars.dart';
import '../../services/report_service.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
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

    setState(() {
      facultyNames = tempNames;
      facultyRates = tempRates;
    });
  }

  Future<void> _pickMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      helpText: "Select any day in the desired month",
    );
    if (picked != null) {
      setState(() => _selectedMonth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
        title: const Text("Reports"),
        elevation: 0,
      ),
      drawer: isDesktop
          ? null
          : const Drawer(
        child: AdminSidebar(activeRoute: '/admin/reports'),
      ),
      body: Row(
        children: [
          if (isDesktop) const AdminSidebar(activeRoute: '/admin/reports'),
          Expanded(
            // ✅ ONLY ADDED REFRESH INDICATOR HERE
            child: RefreshIndicator(
              color: theme.primaryColor,
              backgroundColor: theme.cardColor,
              onRefresh: () async {
                await _fetchFacultyData();
                setState(() {});
              },
              child: SingleChildScrollView(
                // ✅ ADDED PHYSICS FOR SCROLLING
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Attendance Reports", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),

                    // FILTER CARD
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Generate PDF Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),

                          // ROW 1: FACULTY & PERIOD SELECTION
                          if (isDesktop)
                            Row(
                              children: [
                                Expanded(child: _buildFacultyDropdown(theme)),
                                const SizedBox(width: 24),
                                Expanded(child: _buildPeriodDropdown(theme)),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildFacultyDropdown(theme),
                                const SizedBox(height: 16),
                                _buildPeriodDropdown(theme),
                              ],
                            ),

                          const SizedBox(height: 16),

                          // ROW 2: DYNAMIC FILTERS & PRINT BUTTON
                          if (isDesktop)
                            Row(
                              children: [
                                Expanded(child: _buildDynamicDateFilter(theme)),
                                const SizedBox(width: 24),
                                _buildPrintButton(),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildDynamicDateFilter(theme),
                                const SizedBox(height: 24),
                                _buildPrintButton(),
                              ],
                            ),
                        ],
                      ),
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

  // --- UI HELPERS ---

  Widget _buildFacultyDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      dropdownColor: theme.cardColor,
      decoration: const InputDecoration(labelText: "Select Faculty", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      value: selectedFacultyId,
      items: [
        const DropdownMenuItem(value: null, child: Text("All Faculty (Master Report)", overflow: TextOverflow.ellipsis)),
        ...facultyNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (val) => setState(() => selectedFacultyId = val),
    );
  }

  Widget _buildPeriodDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      dropdownColor: theme.cardColor,
      decoration: const InputDecoration(labelText: "Report Period", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      value: _reportPeriod,
      items: const [
        DropdownMenuItem(value: 'All Time', child: Text("All Time")),
        DropdownMenuItem(value: 'Monthly', child: Text("Monthly")),
        DropdownMenuItem(value: 'Financial Year', child: Text("Financial Year")),
      ],
      onChanged: (val) => setState(() => _reportPeriod = val ?? 'All Time'),
    );
  }

  Widget _buildDynamicDateFilter(ThemeData theme) {
    if (_reportPeriod == 'Monthly') {
      return InkWell(
        onTap: _pickMonth,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(4)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Month: ${DateFormat('MMMM yyyy').format(_selectedMonth)}", style: const TextStyle(fontSize: 16)),
              const Icon(Icons.calendar_month, color: Colors.grey),
            ],
          ),
        ),
      );
    } else if (_reportPeriod == 'Financial Year') {
      return DropdownButtonFormField<String>(
        dropdownColor: theme.cardColor,
        decoration: const InputDecoration(labelText: "Select Financial Year", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        value: _selectedFY,
        items: _getFinancialYearOptions().map((fy) => DropdownMenuItem(value: fy, child: Text("FY $fy"))).toList(),
        onChanged: (val) => setState(() => _selectedFY = val!),
      );
    }
    return const SizedBox();
  }

  Widget _buildPrintButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff45a182),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      ),
      icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.print),
      label: const Text("Generate PDF"),
      onPressed: isLoading ? null : _generateReport,
    );
  }

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