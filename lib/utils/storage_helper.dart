import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  /// Ensure we have sufficient permissions to write to external storage.
  /// Returns true if we can write to the chosen location.
  static Future<bool> ensureStoragePermission(BuildContext context) async {
    // Always return false on Android to bypass requesting raw storage permissions.
    // This forces the app to fall back to the native folder picker (Scoped Storage) or internal app storage.
    return false;
  }

  /// Show a system folder picker and return the chosen directory path or null.
  static Future<String?> promptForDirectory() async {
    final chosen = await FilePicker.platform.getDirectoryPath();
    return chosen;
  }

  /// Save a preferred export directory path for later use.
  static Future<void> setPreferredExportDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_export_dir', path);
  }

  /// Get saved preferred export directory path, or null if not set.
  static Future<String?> getPreferredExportDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('preferred_export_dir');
  }
}