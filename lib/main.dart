import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/admin/admin_dashboard.dart';
import 'pages/admin/add_faculty.dart';
import 'pages/faculty/faculty_dashboard.dart';
import 'pages/admin/admin_view_attendance_page.dart';
import 'pages/admin/calculate_salary_screen.dart';
import 'pages/faculty/add_attendance_page.dart';
import 'pages/faculty/faculty_salary_summary_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/admin/dashboard': (context) => AdminDashboard(),
        '/admin/add-faculty': (context) => AddFacultyPage(),
        '/admin/view-attendance': (context) => AdminViewAttendancePage(),
        '/admin/calculate-salary': (context) => CalculateSalaryScreen(),
        '/faculty/dashboard': (context) => FacultyDashboard(),
        '/faculty/add-attendance': (context) => FacultyAddAttendancePage(),
        '/faculty/salary-summary': (context) => FacultySalarySummaryPage(),
      },
    );
  }
}
