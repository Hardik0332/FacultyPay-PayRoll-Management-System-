import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ IMPORT THE NEW THEME MANAGER
import 'package:fixed_project/theme/theme_manager.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:animations/animations.dart';

// ==========================================
// ADMIN SIDEBAR
// ==========================================
class AdminSidebar extends StatelessWidget {
  final String activeRoute;

  const AdminSidebar({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    // Grab our custom colors so the sidebar matches the rest of the app!
    final colors = ThemeManager.instance.colors;

    return Container(
      width: 250,
      color: colors.card, // ✅ DYNAMIC BACKGROUND
      child: Column(
        children: [
          // Logo Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 28, color: colors.primary), // ✅ DYNAMIC ICON
                const SizedBox(width: 12),
                Text(
                  "FacultyPay",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textMain), // ✅ DYNAMIC TEXT
                ),
              ],
            ),
          ),

          Divider(color: colors.textMain.withValues(alpha: 0.1)),
          const SizedBox(height: 16),

          // Menu Items
          _buildNavItem(context, Icons.dashboard, "Dashboard", '/admin/dashboard', colors),
          _buildNavItem(context, Icons.person_add, "Add Faculty", '/admin/add-faculty', colors),
          _buildNavItem(context, Icons.people, "View Faculty", '/admin/view-faculty', colors),
          _buildNavItem(context, Icons.list_alt, "View Attendance", '/admin/view-attendance', colors),
          _buildNavItem(context, Icons.calculate, "Calculate Salary", '/admin/calculate-salary', colors),
          _buildNavItem(context, Icons.analytics, "Reports", '/admin/reports', colors),
          _buildNavItem(context, Icons.person, "My Profile", '/admin/profile', colors),

          const Spacer(),
          Divider(color: colors.textMain.withValues(alpha: 0.1)),

          // ✅ UPDATED THEME TOGGLE USING 3-STATE ThemeManager
          ThemeSwitcher(
            clipper: const ThemeSwitcherCircleClipper(),
            builder: (context) {
              return ListTile(
                leading: Icon(
                  ThemeManager.instance.currentMode == AppThemeMode.system
                      ? Icons.brightness_auto
                      : (ThemeManager.instance.currentMode == AppThemeMode.light ? Icons.light_mode : Icons.dark_mode_outlined),
                  color: ThemeManager.instance.currentMode == AppThemeMode.system
                      ? colors.processing
                      : (ThemeManager.instance.currentMode == AppThemeMode.light ? Colors.amber : colors.primary),
                ),
                title: Text(
                  ThemeManager.instance.currentMode == AppThemeMode.system
                      ? "System Theme"
                      : (ThemeManager.instance.currentMode == AppThemeMode.light ? "Light Mode" : "Dark Mode"),
                  style: TextStyle(fontWeight: FontWeight.w500, color: colors.textMain),
                ),
                onTap: () {
                  ThemeManager.instance.toggleTheme(); // Cycles through System -> Light -> Dark
                  final newColors = ThemeManager.instance.colors;
                  final newIsDark = ThemeManager.instance.isDarkMode;
                  ThemeSwitcher.of(context).changeTheme(
                    theme: ThemeData(
                      brightness: newIsDark ? Brightness.dark : Brightness.light,
                      primaryColor: newColors.primary,
                      scaffoldBackgroundColor: newIsDark ? Colors.black : newColors.bgBottom,
                      cardColor: newColors.card,
                      appBarTheme: AppBarTheme(backgroundColor: newColors.card, foregroundColor: newColors.textMain),
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
                hoverColor: colors.primary.withValues(alpha: 0.1),
              );
            }
          ),

          // Logout Button
          ListTile(
            leading: Icon(Icons.logout, color: colors.error),
            title: Text("Logout", style: TextStyle(color: colors.error, fontWeight: FontWeight.bold)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            hoverColor: colors.error.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String route, AppColors colors) {
    final isActive = activeRoute == route;

    return ListTile(
      leading: Icon(icon, color: isActive ? colors.primary : colors.textMuted),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? colors.primary : colors.textMain,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: colors.primary.withValues(alpha: 0.1),
      onTap: () {
        if (!isActive) Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}


// ==========================================
// FACULTY SIDEBAR
// ==========================================
class FacultySidebar extends StatelessWidget {
  final String activeRoute;

  const FacultySidebar({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    // Grab our custom colors!
    final colors = ThemeManager.instance.colors;

    return Container(
      width: 250,
      color: colors.card,
      child: Column(
        children: [
          // Logo Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 28, color: colors.primary),
                const SizedBox(width: 12),
                Text(
                  "FacultyPay",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textMain),
                ),
              ],
            ),
          ),

          Divider(color: colors.textMain.withValues(alpha: 0.1)),
          const SizedBox(height: 16),

          // Menu Items
          _buildNavItem(context, Icons.dashboard, "Dashboard", '/faculty/dashboard', colors),
          _buildNavItem(context, Icons.calendar_today, "Add Attendance", '/faculty/add-attendance', colors),
          _buildNavItem(context, Icons.account_balance_wallet, "Salary History", '/faculty/salary-history', colors),
          _buildNavItem(context, Icons.person, "My Profile", '/faculty/profile', colors),

          const Spacer(),
          Divider(color: colors.textMain.withValues(alpha: 0.1)),

          // ✅ UPDATED THEME TOGGLE USING 3-STATE ThemeManager
          ThemeSwitcher(
            clipper: const ThemeSwitcherCircleClipper(),
            builder: (context) {
              return ListTile(
                leading: Icon(
                  ThemeManager.instance.currentMode == AppThemeMode.system
                      ? Icons.brightness_auto
                      : (ThemeManager.instance.currentMode == AppThemeMode.light ? Icons.light_mode : Icons.dark_mode_outlined),
                  color: ThemeManager.instance.currentMode == AppThemeMode.system
                      ? colors.processing
                      : (ThemeManager.instance.currentMode == AppThemeMode.light ? Colors.amber : colors.primary),
                ),
                title: Text(
                  ThemeManager.instance.currentMode == AppThemeMode.system
                      ? "System Theme"
                      : (ThemeManager.instance.currentMode == AppThemeMode.light ? "Light Mode" : "Dark Mode"),
                  style: TextStyle(fontWeight: FontWeight.w500, color: colors.textMain),
                ),
                onTap: () {
                  ThemeManager.instance.toggleTheme(); // Cycles through System -> Light -> Dark
                  final newColors = ThemeManager.instance.colors;
                  final newIsDark = ThemeManager.instance.isDarkMode;
                  ThemeSwitcher.of(context).changeTheme(
                    theme: ThemeData(
                      brightness: newIsDark ? Brightness.dark : Brightness.light,
                      primaryColor: newColors.primary,
                      scaffoldBackgroundColor: newIsDark ? Colors.black : newColors.bgBottom,
                      cardColor: newColors.card,
                      appBarTheme: AppBarTheme(backgroundColor: newColors.card, foregroundColor: newColors.textMain),
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
                hoverColor: colors.primary.withValues(alpha: 0.1),
              );
            }
          ),

          // Logout Button
          ListTile(
            leading: Icon(Icons.logout, color: colors.error),
            title: Text("Logout", style: TextStyle(color: colors.error, fontWeight: FontWeight.bold)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            hoverColor: colors.error.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String route, AppColors colors) {
    final isActive = activeRoute == route;

    return ListTile(
      leading: Icon(icon, color: isActive ? colors.primary : colors.textMuted),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? colors.primary : colors.textMain,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: colors.primary.withValues(alpha: 0.1),
      onTap: () {
        if (!isActive) Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}