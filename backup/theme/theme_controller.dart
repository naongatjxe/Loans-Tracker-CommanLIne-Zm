import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  Color _accent = const Color(0xFF64B5F6);

  ThemeMode get mode => _mode;
  Color get accent => _accent;

  void setMode(ThemeMode m) {
    _mode = m;
    notifyListeners();
  }

  void setAccent(Color c) {
    _accent = c;
    notifyListeners();
  }
}
