import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Added for SystemChrome (Orientation Lock)
import 'package:flutter/foundation.dart'; // ✅ Added for kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:animations/animations.dart';
import 'firebase_options.dart';

import 'pages/admin/admin_base_wrapper.dart';
import 'pages/faculty/faculty_base_wrapper.dart';

import 'theme/theme_manager.dart';
import 'services/auth_gate.dart';

// ✅ 1. Define the High Importance Channel
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.', // description
  importance: Importance.max, // This ensures the "Heads-up" popup
  playSound: true,
);

// ✅ 2. Initialize local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Lock orientation to Portrait for Mobile App ONLY
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("DotEnv Init Error: $e");
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ✅ 3. Create the notification channel on the device
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // ✅ 4. Update foreground presentation options for the popup effect
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Grab initial colors
    final colors = ThemeManager.instance.colors;
    final isDark = ThemeManager.instance.isDarkMode;

    final initialTheme = ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: isDark ? Colors.black : colors.bgBottom,
      cardColor: colors.card,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.card,
        foregroundColor: colors.textMain,
      ),
      useMaterial3: false,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.scaled,
          ),
          TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.scaled,
          ),
          TargetPlatform.windows: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.scaled,
          ),
          TargetPlatform.macOS: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.scaled,
          ),
          TargetPlatform.linux: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.scaled,
          ),
        },
      ),
    );

    // 2. ThemeProvider handles ALL the rebuilding now!
    return ThemeProvider(
      initTheme: initialTheme,
      builder: (context, myTheme) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FacultyPay',
          theme: myTheme,
          home: const AuthGate(),
          builder: (context, child) {
            return ThemeSwitchingArea(
              child: child!,
            );
          },
          routes: {
            '/admin/dashboard': (context) => const AdminBaseWrapper(initialIndex: 0),
            '/admin/view-attendance': (context) => const AdminBaseWrapper(initialIndex: 1),
            '/admin/calculate-salary': (context) => const AdminBaseWrapper(initialIndex: 2),
            '/admin/view-faculty': (context) => const AdminBaseWrapper(initialIndex: 3),
            '/admin/add-faculty': (context) => const AdminBaseWrapper(initialIndex: 4),
            '/admin/reports': (context) => const AdminBaseWrapper(initialIndex: 5),
            '/admin/profile': (context) => const AdminBaseWrapper(initialIndex: 6),
            '/faculty/dashboard': (context) => const FacultyBaseWrapper(initialIndex: 0),
            '/faculty/add-attendance': (context) => const FacultyBaseWrapper(initialIndex: 1),
            '/faculty/salary-history': (context) => const FacultyBaseWrapper(initialIndex: 2),
            '/faculty/profile': (context) => const FacultyBaseWrapper(initialIndex: 3),
          },
        );
      },
    );
  }
}