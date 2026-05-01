import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/theme_manager.dart'; // ✅ IMPORT THE THEME MANAGER
import 'package:animations/animations.dart'; // ✅ Added morph animations
import 'faculty_dashboard.dart';
import 'add_attendance_page.dart';
import 'faculty_salary_summary_page.dart';
import 'faculty_profile_page.dart';

class FadeIndexedStack extends StatelessWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: duration,
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          fillColor: Colors.transparent,
          child: child,
        );
      },
      // Using a UniqueKey derived from index ensures PageTransitionSwitcher knows the child changed
      child: KeyedSubtree(
        key: ValueKey<int>(index),
        child: children[index],
      ),
    );
  }
}

class FacultyBaseWrapper extends StatefulWidget {
  final int initialIndex;
  const FacultyBaseWrapper({super.key, required this.initialIndex});

  @override
  State<FacultyBaseWrapper> createState() => _FacultyBaseWrapperState();
}

class _FacultyBaseWrapperState extends State<FacultyBaseWrapper> {
  late int _currentNavIndex;

  // ✅ 1. Add the Tab History Stack
  final List<int> _tabHistory = [];

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialIndex;
    // ✅ Add the initial screen to history
    _tabHistory.add(_currentNavIndex);
  }

  late final List<Widget> _pages = [
    const FacultyDashboard(),
    const AddAttendancePage(),
    const FacultySalaryHistoryPage(),
    const FacultyProfilePage(),
  ];

  // ✅ 2. Create a central method to handle all tab routing
  void _onTabTapped(int index) {
    if (_currentNavIndex == index) return;

    setState(() {
      _currentNavIndex = index;
      // Remove the index if it exists, then add it to the top of the stack
      _tabHistory.remove(index);
      _tabHistory.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    // ✅ REMOVED AnimatedBuilder here!
    // Just grab the colors normally. The ThemeSwitcher in main.dart handles the rebuild now.
    final colors = ThemeManager.instance.colors;
    final isDark = ThemeManager.instance.isDarkMode;

    // ✅ 3. Update the PopScope to read from our History Stack
    return PopScope(
      canPop: _tabHistory.length <= 1, // Let Android exit app if only 1 page left
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (didPop) return; // App is exiting

        if (_tabHistory.length > 1) {
          setState(() {
            _tabHistory.removeLast(); // Pop current view
            _currentNavIndex = _tabHistory.last; // Navigate to previous view
          });
        }
      },
      child: Scaffold(
        backgroundColor: colors.bgBottom, // ✅ DYNAMIC
        body: isDesktop ? _buildDesktopLayout(colors) : _buildMobileLayout(colors, isDark),
      ),
    );
  }

  Widget _buildDesktopLayout(AppColors colors) {
    return Row(
      children: [
        Container(
          width: 250,
          color: colors.card, // ✅ DYNAMIC
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40, left: 24, bottom: 40),
                child: Row(
                  children: [
                    Icon(Icons.school, color: colors.primary, size: 28),
                    const SizedBox(width: 12),
                    Text("Faculty Portal", style: TextStyle(color: colors.textMain, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildSidebarItem(Icons.home, "Home", 0, colors),
                      _buildSidebarItem(Icons.edit_document, "Log Hours", 1, colors),
                      _buildSidebarItem(Icons.account_balance_wallet, "Payments", 2, colors),
                      _buildSidebarItem(Icons.person, "My Profile", 3, colors),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: GestureDetector(
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: colors.error, size: 20),
                      const SizedBox(width: 12),
                      Text("Logout", style: TextStyle(color: colors.error, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.bgTop, colors.bgBottom],
                  ),
                ),
              ),
              FadeIndexedStack(
                index: _currentNavIndex,
                children: _pages,
                duration: const Duration(milliseconds: 400), // ✅ Make it slower for a more dramatic effect
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index, AppColors colors) {
    bool isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index), // ✅ 4. Use the new tap function
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: colors.primary.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? colors.primary : colors.textMuted, size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isActive ? colors.primary : colors.textMain,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AppColors colors, bool isDark) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.bgTop, colors.bgBottom],
            ),
          ),
        ),
        FadeIndexedStack(
          index: _currentNavIndex,
          children: _pages,
          duration: const Duration(milliseconds: 400), // ✅ Make it slower for a more dramatic effect
        ),
        Positioned(
          bottom: 30, left: 0, right: 0,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildFloatingBottomNav(colors, isDark),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingBottomNav(AppColors colors, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7), // Smoother blur for light mode
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7), // ✅ White translucent bar in light mode
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home, "HOME", 0, colors, isDark),
              _buildNavItem(Icons.edit_document, "LOG", 1, colors, isDark),
              _buildNavItem(Icons.account_balance_wallet, "PAY", 2, colors, isDark),
              _buildNavItem(Icons.person, "PROFILE", 3, colors, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, AppColors colors, bool isDark) {
    bool isActive = _currentNavIndex == index;
    final color = isActive ? colors.primary : (isDark ? Colors.white.withValues(alpha: 0.4) : colors.textMuted); // ✅ DYNAMIC
    return GestureDetector(
      onTap: () => _onTabTapped(index), // ✅ 4. Use the new tap function
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
              Container(margin: const EdgeInsets.only(top: 4), height: 3, width: 20, decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(2)))
          ],
        ),
      ),
    );
  }
}