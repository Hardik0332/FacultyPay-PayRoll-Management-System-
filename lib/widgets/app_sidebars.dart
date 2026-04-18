import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ✅ IMPORT MAIN TO ACCESS THE THEME NOTIFIER
import '../../main.dart';

// ==========================================
// ADMIN SIDEBAR
// ==========================================
class AdminSidebar extends StatelessWidget {
  final String activeRoute;

  const AdminSidebar({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 250,
      color: theme.cardColor,
      child: Column(
        children: [
          // Logo Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 28, color: theme.primaryColor),
                const SizedBox(width: 12),
                const Text(
                  "FacultyPay",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const Divider(),
          const SizedBox(height: 16),

          // Menu Items
          _buildNavItem(context, Icons.dashboard, "Dashboard", '/admin/dashboard'),
          _buildNavItem(context, Icons.person_add, "Add Faculty", '/admin/add-faculty'),
          _buildNavItem(context, Icons.people, "View Faculty", '/admin/view-faculty'),
          _buildNavItem(context, Icons.list_alt, "View Attendance", '/admin/view-attendance'),
          _buildNavItem(context, Icons.calculate, "Calculate Salary", '/admin/calculate-salary'),
          _buildNavItem(context, Icons.analytics, "Reports", '/admin/reports'),

          const Spacer(),
          const Divider(),

          // ✅ DARK MODE TOGGLE
          ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, child) {
                final isCurrentlyDark = currentMode == ThemeMode.dark ||
                    (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

                return ListTile(
                  leading: Icon(
                    isCurrentlyDark ? Icons.light_mode : Icons.dark_mode_outlined,
                    color: isCurrentlyDark ? Colors.amber : Colors.grey.shade700,
                  ),
                  title: Text(
                    isCurrentlyDark ? "Light Mode" : "Dark Mode",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    themeNotifier.value = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
                  },
                  hoverColor: theme.primaryColor.withValues(alpha: 0.1),
                );
              }
          ),

          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            hoverColor: Colors.redAccent.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String route) {
    final isActive = activeRoute == route;
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: isActive ? theme.primaryColor : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? theme.primaryColor : (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: theme.primaryColor.withValues(alpha: 0.1),
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
    final theme = Theme.of(context);

    return Container(
      width: 250,
      color: theme.cardColor,
      child: Column(
        children: [
          // Logo Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 28, color: theme.primaryColor),
                const SizedBox(width: 12),
                const Text(
                  "FacultyPay",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const Divider(),
          const SizedBox(height: 16),

          // Menu Items
          _buildNavItem(context, Icons.dashboard, "Dashboard", '/faculty/dashboard'),
          _buildNavItem(context, Icons.calendar_today, "Add Attendance", '/faculty/add-attendance'),
          _buildNavItem(context, Icons.account_balance_wallet, "Salary History", '/faculty/salary-history'),
          _buildNavItem(context, Icons.person, "My Profile", '/faculty/profile'),

          const Spacer(),
          const Divider(),

          // ✅ DARK MODE TOGGLE
          ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, child) {
                final isCurrentlyDark = currentMode == ThemeMode.dark ||
                    (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

                return ListTile(
                  leading: Icon(
                    isCurrentlyDark ? Icons.light_mode : Icons.dark_mode_outlined,
                    color: isCurrentlyDark ? Colors.amber : Colors.grey.shade700,
                  ),
                  title: Text(
                    isCurrentlyDark ? "Light Mode" : "Dark Mode",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    themeNotifier.value = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
                  },
                  hoverColor: theme.primaryColor.withValues(alpha: 0.1),
                );
              }
          ),

          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            hoverColor: Colors.redAccent.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String route) {
    final isActive = activeRoute == route;
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: isActive ? theme.primaryColor : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? theme.primaryColor : (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: theme.primaryColor.withValues(alpha: 0.1),
      onTap: () {
        if (!isActive) Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}