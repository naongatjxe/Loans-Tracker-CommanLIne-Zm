import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/person.dart';
import '../models/contract.dart';
import 'loan_provider.dart';
import 'notification_service.dart';
import '../theme/theme_controller.dart';

class BackupService {
  static Future<Directory> _getPublicLoansTrackerDir() async {
    Directory? baseDir;

    // Check SharedPreferences for custom path
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('custom_export_path');
      if (customPath != null && customPath.isNotEmpty) {
        final d = Directory(customPath);
        if (await d.parent.exists() || await d.exists()) {
          baseDir = d;
        }
      }
    } catch (_) {}

    // Fallback if no custom path is configured or valid
    if (baseDir == null) {
      // Try common Android Downloads paths first, appending "/Loans Tracker"
      final androidPaths = [
        '/storage/emulated/0/Download/Loans Tracker',
        '/storage/emulated/0/Downloads/Loans Tracker',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads'
      ];

      for (final p in androidPaths) {
        try {
          if (p == '/storage/emulated/0/Download' || p == '/storage/emulated/0/Downloads') {
            if (await Directory(p).exists()) {
              baseDir = Directory('$p/Loans Tracker');
              break;
            }
          } else {
            final parent = Directory(p).parent;
            if (await parent.exists()) {
              baseDir = Directory(p);
              break;
            }
          }
        } catch (_) {}
      }
    }

    // Next fallback: path_provider's getDownloadsDirectory
    if (baseDir == null) {
      try {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) {
          baseDir = Directory('${downloads.path}/Loans Tracker');
        }
      } catch (_) {}
    }

    // Final fallback: temporary directory
    if (baseDir == null) {
      final temp = await getTemporaryDirectory();
      baseDir = Directory('${temp.path}/Loans Tracker');
    }

    // Ensure directory exists
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    return baseDir;
  }

  static Future<void> backupData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      final themeController = Provider.of<ThemeController>(context, listen: false);
      final notifService = NotificationService();

      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      // Check context mount status before using context after async gaps
      if (!context.mounted) return;

      final backupMap = {
        'version': 1,
        'exportDate': DateTime.now().toIso8601String(),
        'people': loanProvider.people.map((p) => p.toMap()).toList(),
        'contracts': loanProvider.contracts.map((c) => c.toMap()).toList(),
        'settings': {
          'notifications_enabled': notifService.enabled,
          'notification_hour': notifService.hour,
          'notification_minute': notifService.minute,
          'notification_one_day_before': notifService.oneDayBefore,
          'theme_mode': themeController.mode.index,
          'theme_accent': themeController.accent.toARGB32(),
        }
      };

      final jsonString = jsonEncode(backupMap);
      final destDir = await _getPublicLoansTrackerDir();
      final fileName = 'loans_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final backupFile = File('${destDir.path}/$fileName');
      await backupFile.writeAsString(jsonString);

      // Shorten the output path display for SnackBar
      String displayPath = 'Downloads/Loans Tracker';
      try {
        final prefs = await SharedPreferences.getInstance();
        final customPath = prefs.getString('custom_export_path');
        if (customPath != null && customPath.isNotEmpty) {
          final parts = customPath.split('/');
          if (parts.length >= 2) {
            displayPath = '${parts[parts.length - 2]}/${parts.last}';
          } else {
            displayPath = customPath;
          }
        }
      } catch (_) {}

      messenger.showSnackBar(
        SnackBar(content: Text('Backup saved to: $displayPath/$fileName')),
      );

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'Loans Tracker Backup',
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  static Future<void> restoreData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        messenger.showSnackBar(const SnackBar(content: Text('No backup file selected')));
        return;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic> ||
          decoded['version'] == null ||
          decoded['people'] == null ||
          decoded['contracts'] == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Invalid backup file format')));
        return;
      }

      // Check context mount status before using context after async gaps
      if (!context.mounted) return;

      // Parse people
      final List<dynamic> rawPeople = decoded['people'];
      final List<Person> importedPeople = rawPeople.map((p) => Person.fromMap(p)).toList();

      // Parse contracts
      final List<dynamic> rawContracts = decoded['contracts'];
      final List<Contract> importedContracts = rawContracts.map((c) => Contract.fromMap(c)).toList();

      // Import database data
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      await loanProvider.importData(importedPeople, importedContracts);

      // Check context mount status before restoring settings
      if (!context.mounted) return;

      // Restore settings if present
      final dynamic rawSettings = decoded['settings'];
      if (rawSettings is Map<String, dynamic>) {
        final themeController = Provider.of<ThemeController>(context, listen: false);
        final notifService = NotificationService();

        // Restore notifications settings
        if (rawSettings['notifications_enabled'] is bool) {
          await notifService.setEnabled(rawSettings['notifications_enabled']);
        }
        if (rawSettings['notification_hour'] is int && rawSettings['notification_minute'] is int) {
          await notifService.setNotificationTime(
            rawSettings['notification_hour'],
            rawSettings['notification_minute'],
          );
        }
        if (rawSettings['notification_one_day_before'] is bool) {
          await notifService.setOneDayBefore(rawSettings['notification_one_day_before']);
        }

        // Restore theme settings
        if (rawSettings['theme_mode'] is int) {
          final modeIndex = rawSettings['theme_mode'] as int;
          if (modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
            themeController.setMode(ThemeMode.values[modeIndex]);
          }
        }
        if (rawSettings['theme_accent'] is int) {
          themeController.setAccent(Color(rawSettings['theme_accent']));
        }
      }

      messenger.showSnackBar(const SnackBar(content: Text('Backup restored successfully')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }
}
