import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode;
  Color _accent;

  // App Lock State
  bool _pinLockEnabled;
  String _pinCode;
  bool _biometricsEnabled;

  ThemeController({
    ThemeMode initialMode = ThemeMode.system,
    Color initialAccent = const Color(0xFF64B5F6),
    bool initialPinLockEnabled = false,
    String initialPinCode = '',
    bool initialBiometricsEnabled = false,
  })  : _mode = initialMode,
        _accent = initialAccent,
        _pinLockEnabled = initialPinLockEnabled,
        _pinCode = initialPinCode,
        _biometricsEnabled = initialBiometricsEnabled;

  ThemeMode get mode {
    final _ = _mode;
    return ThemeMode.dark;
  }
  Color get accent => _accent;
  bool get pinLockEnabled => _pinLockEnabled;
  String get pinCode => _pinCode;
  bool get biometricsEnabled => _biometricsEnabled;

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', m.index);
    } catch (_) {}
  }

  Future<void> setAccent(Color c) async {
    _accent = c;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_accent', c.toARGB32());
    } catch (_) {}
  }

  Future<void> setPinLockEnabled(bool value) async {
    _pinLockEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pin_lock_enabled', value);
    } catch (_) {}
  }

  Future<void> setPinCode(String value) async {
    _pinCode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pin_code', value);
    } catch (_) {}
  }

  Future<void> setBiometricsEnabled(bool value) async {
    _biometricsEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometrics_enabled', value);
    } catch (_) {}
  }
}
