import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'pages/login_page.dart';
import 'pages/admin/admin_dashboard.dart';
import 'pages/admin/add_faculty.dart';
import 'pages/admin/view_faculty_page.dart';
import 'pages/admin/admin_view_attendance_page.dart';
import 'pages/admin/calculate_salary_screen.dart';
import 'pages/faculty/faculty_dashboard.dart';
import 'pages/faculty/add_attendance_page.dart';
import 'services/auth_gate.dart';
import 'pages/faculty/faculty_salary_summary_page.dart';
import 'pages/admin/admin_reports_page.dart';
import 'pages/faculty/faculty_profile_page.dart';

// ✅ Global Variable for Dark Mode (The Sidebar talks to this!)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

// Removes the "Flashing/Loading" animation between pages
class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Wraps the app to listen for Dark Mode changes from the Sidebar
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FacultyPay',
          themeMode: currentMode,

          // ☀️ LIGHT THEME
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xff45a182),
            scaffoldBackgroundColor: const Color(0xfff6f7f7),
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xff45a182), foregroundColor: Colors.white),
            useMaterial3: false,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
                TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
                TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
                TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
                TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
              },
            ),
          ),

          // 🌙 DARK THEME
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xff45a182),
            scaffoldBackgroundColor: Colors.black,
            cardColor: const Color(0xff121212),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xff121212), foregroundColor: Colors.white),
            useMaterial3: false,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
                TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
                TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
                TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
                TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
              },
            ),
          ),

          home: const AuthGate(),
          routes: {
            '/admin/dashboard': (context) => const AdminDashboard(),
            '/admin/add-faculty': (context) => const AddFacultyPage(),
            '/admin/view-faculty': (context) => const ViewFacultyPage(),
            '/admin/view-attendance': (context) => const AdminViewAttendancePage(),
            '/admin/calculate-salary': (context) => const CalculateSalaryScreen(),
            '/faculty/salary-history': (context) => const FacultySalaryHistoryPage(),
            '/faculty/dashboard': (context) => const FacultyDashboard(),
            '/faculty/add-attendance': (context) => const FacultyAddAttendancePage(),
            '/admin/reports': (context) => const AdminReportsPage(),
            '/faculty/profile': (context) => const FacultyProfilePage(),
          },
        );
      },
    );
  }
}