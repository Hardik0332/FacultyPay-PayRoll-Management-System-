import 'dart:ui';
import 'package:flutter/material.dart';

enum AppThemeMode { system, light, dark }

class AppColors {
  final Color bgTop;
  final Color bgBottom;
  final Color card;
  final Color cardHighlight;
  final Color primary;
  final Color textMain;
  final Color textMuted;

  final Color success;
  final Color warning;
  final Color error;
  final Color processing;

  final Color successBg;
  final Color warningBg;
  final Color processingBg;

  AppColors({
    required this.bgTop,
    required this.bgBottom,
    required this.card,
    required this.cardHighlight,
    required this.primary,
    required this.textMain,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.error,
    required this.processing,
    required this.successBg,
    required this.warningBg,
    required this.processingBg,
  });
}

// ✅ ADDED WidgetsBindingObserver to safely listen to the OS
class ThemeManager extends ChangeNotifier with WidgetsBindingObserver {
  static final ThemeManager instance = ThemeManager._internal();

  AppThemeMode _currentMode = AppThemeMode.system;

  ThemeManager._internal() {
    // ✅ Safely hook into Flutter's lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  // ✅ Triggered automatically when Android/iOS changes Dark Mode
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (_currentMode == AppThemeMode.system) {
      notifyListeners();
    }
  }

  AppThemeMode get currentMode => _currentMode;

  bool get isDarkMode {
    if (_currentMode == AppThemeMode.light) return false;
    if (_currentMode == AppThemeMode.dark) return true;

    try {
      return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    } catch (e) {
      return true;
    }
  }

  AppColors get colors => isDarkMode ? darkColors : lightColors;

  void toggleTheme() {
    if (_currentMode == AppThemeMode.system) {
      _currentMode = AppThemeMode.light;
    } else if (_currentMode == AppThemeMode.light) {
      _currentMode = AppThemeMode.dark;
    } else {
      _currentMode = AppThemeMode.system;
    }
    notifyListeners();
  }

  // ==========================================
  // 🌙 DARK MODE PALETTE
  // ==========================================
  static final AppColors darkColors = AppColors(
    bgTop: const Color(0xFF3B4154),
    bgBottom: const Color(0xFF1E212A),
    card: const Color(0xFF242832),
    cardHighlight: const Color(0xFF2A2E39),
    primary: const Color(0xFF4ADE80),
    textMain: Colors.white,
    textMuted: Colors.white.withValues(alpha: 0.5),
    success: const Color(0xFF4ADE80),
    warning: const Color(0xFFFBBF24),
    error: const Color(0xFFE05B5C),
    processing: const Color(0xFF60A5FA),
    successBg: const Color(0xFF4ADE80).withValues(alpha: 0.1),
    warningBg: const Color(0xFFFBBF24).withValues(alpha: 0.1),
    processingBg: const Color(0xFF60A5FA).withValues(alpha: 0.1),
  );

  // ==========================================
  // ☀️ LIGHT MODE PALETTE
  // ==========================================
  static final AppColors lightColors = AppColors(
    bgTop: const Color(0xFFF4EFE6),
    bgBottom: const Color(0xFFF8F5EE),
    card: const Color(0xFFFFFFFF),
    cardHighlight: const Color(0xFFFFFFFF),
    primary: const Color(0xFF2F6B4F),
    textMain: const Color(0xFF1A1A1A),
    textMuted: const Color(0xFF7A7A7A),
    success: const Color(0xFF2F6B4F),
    processing: const Color(0xFF6B6B6B),
    warning: const Color(0xFFB8860B),
    error: const Color(0xFFD32F2F),
    successBg: const Color(0xFFE3F2EA),
    processingBg: const Color(0xFFEAEAEA),
    warningBg: const Color(0xFFFDF5E6),
  );
}