import 'dart:ui';
import 'package:flutter/material.dart';

import 'admin_dashboard.dart';
import 'admin_view_attendance_page.dart';
import 'calculate_salary_screen.dart';
import 'view_faculty_page.dart';
import 'add_faculty.dart';
import 'admin_reports_page.dart';
import 'admin_profile_page.dart';

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward();
    super.initState();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}

class AdminBaseWrapper extends StatefulWidget {
  final int initialIndex;
  const AdminBaseWrapper({super.key, required this.initialIndex});

  @override
  State<AdminBaseWrapper> createState() => _AdminBaseWrapperState();
}

class _AdminBaseWrapperState extends State<AdminBaseWrapper> {
  late int _currentNavIndex;
  final Color primaryRed = const Color(0xFFE05B5C);

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialIndex;
  }

  late final List<Widget> _pages = [
    const AdminDashboard(),
    const AdminVerifyAttendancePage(),
    const AdminCalculateSalaryPage(),
    const AdminViewFacultyPage(),
    const AdminAddFacultyPage(),
    const AdminReportsPage(),
    const AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentNavIndex == 0,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (!didPop) {
          setState(() {
            _currentNavIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF282C37),
        body: Stack(
          children: [
            // Shared Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3B4154), Color(0xFF1E212A)],
                ),
              ),
            ),

            // Pages
            FadeIndexedStack(
              index: _currentNavIndex,
              children: _pages,
            ),

            // Floating Bottom Navigation (Crystal Clear Glass)
            Positioned(
              bottom: 30, left: 20, right: 20,
              child: _buildFloatingBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBottomNav() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.03),
                  Colors.transparent,
                ]),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _buildNavItem(Icons.dashboard, "DASH", 0),
                _buildNavItem(Icons.checklist, "APPROVE", 1),
                _buildNavItem(Icons.account_balance, "PAY", 2),
                _buildNavItem(Icons.people, "VIEW FAC", 3),
                _buildNavItem(Icons.person_add, "ADD FAC", 4),
                _buildNavItem(Icons.receipt_long, "REPORTS", 5),
                _buildNavItem(Icons.person, "PROFILE", 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _currentNavIndex == index;
    final color = isActive ? primaryRed : Colors.white.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: () {
        setState(() => _currentNavIndex = index);
      },
      child: Container(
        color: Colors.transparent,
        width: 75,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (isActive)
              Container(margin: const EdgeInsets.only(top: 4), height: 3, width: 20, decoration: BoxDecoration(color: primaryRed, borderRadius: BorderRadius.circular(2)))
          ],
        ),
      ),
    );
  }
}
