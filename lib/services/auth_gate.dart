import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/theme_manager.dart';
import '../pages/login_page.dart';
import '../pages/admin/admin_base_wrapper.dart';
import '../pages/faculty/faculty_base_wrapper.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final colors = ThemeManager.instance.colors;
          return Scaffold(
            backgroundColor: colors.bgBottom,
            body: Center(child: CircularProgressIndicator(color: colors.primary)),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        return RoleRedirect(user: snapshot.data!);
      },
    );
  }
}

class RoleRedirect extends StatefulWidget {
  final User user;
  const RoleRedirect({super.key, required this.user});

  @override
  State<RoleRedirect> createState() => _RoleRedirectState();
}

class _RoleRedirectState extends State<RoleRedirect> {
  late final Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();
    // ✅ FIXED: Wait until the screen actually finishes drawing before asking for permissions!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupPushNotifications(widget.user.uid);
    });
  }

  // ✅ Wrapped in try-catch so Emulators don't crash looking for a battery
  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        PermissionStatus status = await Permission.ignoreBatteryOptimizations.status;
        if (!status.isGranted) {
          await Permission.ignoreBatteryOptimizations.request();
        }
      }
    } catch (e) {
      debugPrint("Battery Optimization skip (Safe to ignore on emulators): $e");
    }
  }

  Future<void> _setupPushNotifications(String uid) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Grab token (wrapped in try-catch for buggy emulators)
        String? token;
        try {
          token = await messaging.getToken();
        } catch (e) {
          debugPrint("Emulator FCM Token skip: $e");
        }

        if (token != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'fcmToken': token,
          });
        }

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (message.notification != null && mounted) {
            final colors = ThemeManager.instance.colors;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message.notification!.title ?? 'New Alert', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(message.notification!.body ?? '', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                backgroundColor: colors.primary,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
                dismissDirection: DismissDirection.up,
              ),
            );
          }
        });

        await _requestBatteryOptimizationExemption();
      }
    } catch (e) {
      debugPrint("Push Notification Setup Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder: (context, snapshot) {
        final colors = ThemeManager.instance.colors;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: colors.bgBottom,
            body: Center(child: CircularProgressIndicator(color: colors.primary)),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: colors.bgBottom,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: colors.error, size: 60),
                  const SizedBox(height: 16),
                  Text("Error: ${snapshot.error}", style: TextStyle(color: colors.textMain)),
                  TextButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: Text("Go Back to Login", style: TextStyle(color: colors.primary)),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: colors.bgBottom,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, color: colors.warning, size: 60),
                  const SizedBox(height: 16),
                  Text("User account record not found.", style: TextStyle(color: colors.textMain)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text("Logout", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final String role = data?['role'] ?? 'faculty';

        if (role == 'admin') {
          return const AdminBaseWrapper(initialIndex: 0);
        } else {
          return const FacultyBaseWrapper(initialIndex: 0);
        }
      },
    );
  }
}