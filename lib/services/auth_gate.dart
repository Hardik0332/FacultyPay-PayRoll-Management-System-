import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/login_page.dart';
import '../pages/admin/admin_dashboard.dart';
import '../pages/faculty/faculty_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Loading State for Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. If NOT logged in, show Login Page
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // 3. If logged in, check role and redirect
        return const RoleRedirect();
      },
    );
  }
}

class RoleRedirect extends StatelessWidget {
  const RoleRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const LoginPage();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        // While fetching user role from Firestore
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle Errors (e.g., no internet or Firestore error)
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text("Error: ${snapshot.error}"),
                  TextButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text("Go Back to Login"),
                  ),
                ],
              ),
            ),
          );
        }

        // Handle case where user exists in Auth but not in Firestore
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("User account record not found."),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text("Logout"),
                  ),
                ],
              ),
            ),
          );
        }

        // Redirect based on role
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final String role = data?['role'] ?? 'faculty';

        if (role == 'admin') {
          return const AdminDashboard();
        } else {
          return const FacultyDashboard(initialIndex: 0);
        }
      },
    );
  }
}
