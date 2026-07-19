import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_controller.dart';
import '../utils/loan_provider.dart';
import '../utils/csv_exporter.dart';
import '../utils/backup_service.dart';
import '../utils/notification_service.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _activeExportPath = 'Downloads/Loans Tracker';
  bool _notificationsEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  bool _notifyOneDayBefore = true;

  @override
  void initState() {
    super.initState();
    _loadActiveExportPath();
    _loadNotificationSettings();
  }

  void _loadNotificationSettings() {
    final notifService = NotificationService();
    setState(() {
      _notificationsEnabled = notifService.enabled;
      _notificationTime = TimeOfDay(hour: notifService.hour, minute: notifService.minute);
      _notifyOneDayBefore = notifService.oneDayBefore;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    await NotificationService().setEnabled(value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _selectNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked != null) {
      await NotificationService().setNotificationTime(picked.hour, picked.minute);
      setState(() {
        _notificationTime = picked;
      });
      // Reschedule all active contracts
      if (mounted) {
        final provider = Provider.of<LoanProvider>(context, listen: false);
        for (final loan in provider.people) {
          if (!loan.isPaid) {
            await NotificationService().scheduleLoanNotifications(loan);
          }
        }
      }
    }
  }

  Future<void> _toggleOneDayBefore(bool value) async {
    await NotificationService().setOneDayBefore(value);
    setState(() {
      _notifyOneDayBefore = value;
    });
    // Reschedule all active contracts
    if (mounted) {
      final provider = Provider.of<LoanProvider>(context, listen: false);
      for (final loan in provider.people) {
        if (!loan.isPaid) {
          await NotificationService().scheduleLoanNotifications(loan);
        }
      }
    }
  }

  Future<void> _loadActiveExportPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('custom_export_path');
      if (customPath != null && customPath.isNotEmpty) {
        setState(() {
          if (customPath.length > 35) {
            _activeExportPath = '...${customPath.substring(customPath.length - 32)}';
          } else {
            _activeExportPath = customPath;
          }
        });
      } else {
        setState(() {
          _activeExportPath = 'Downloads/Loans Tracker';
        });
      }
    } catch (_) {}
  }

  Future<void> _changeSaveDirectory() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath();
      if (path != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_export_path', path);
        _loadActiveExportPath();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Save directory updated to: $path')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update directory: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Provider.of<ThemeController>(context);
    final isSystemDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = themeCtrl.mode == ThemeMode.dark ||
        (themeCtrl.mode == ThemeMode.system && isSystemDark);
    final accent = themeCtrl.accent;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.3,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        toolbarHeight: 48,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [


          // Theme Settings Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Theme Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    activeThumbColor: accent,
                    activeTrackColor: accent.withValues(alpha: 0.5),
                    title: const Text('Always Dark Mode'),
                    subtitle: const Text('Force dark theme, otherwise follow system settings'),
                    value: themeCtrl.mode == ThemeMode.dark,
                    onChanged: (bool value) {
                      themeCtrl.setMode(value ? ThemeMode.dark : ThemeMode.system);
                    },
                    secondary: Icon(
                      Icons.dark_mode_rounded,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accent Color',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Accent Colors
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:
                        [
                              Colors.blue,
                              Colors.green,
                              Colors.purple,
                              Colors.orange,
                              Colors.red,
                            ]
                            .map(
                              (color) =>
                                  _buildColorOption(color, accent, themeCtrl),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    activeThumbColor: accent,
                    activeTrackColor: accent.withValues(alpha: 0.5),
                    title: const Text('Enable Reminders'),
                    subtitle: const Text('Send notifications for upcoming and overdue payments'),
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    secondary: Icon(
                      Icons.notifications_active_rounded,
                      color: accent,
                    ),
                  ),
                  if (_notificationsEnabled) ...[
                    ListTile(
                      leading: Icon(
                        Icons.access_time_filled_rounded,
                        color: accent,
                      ),
                      title: const Text('Reminder Time'),
                      subtitle: Text(
                        'Scheduled for: ${_notificationTime.format(context)}',
                      ),
                      onTap: _selectNotificationTime,
                    ),
                    SwitchListTile(
                      activeThumbColor: accent,
                      activeTrackColor: accent.withValues(alpha: 0.5),
                      title: const Text('1 Day Before Due'),
                      subtitle: const Text('Notify one day prior to payment deadlines'),
                      value: _notifyOneDayBefore,
                      onChanged: _toggleOneDayBefore,
                      secondary: Icon(
                        Icons.today_rounded,
                        color: accent,
                      ),
                    ),
                  ],
                  ListTile(
                    leading: Icon(
                      Icons.notification_important_rounded,
                      color: accent,
                    ),
                    title: const Text('Send Test Notification'),
                    subtitle: const Text('Triggers an immediate test reminder to verify notifications work'),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await NotificationService().showTestNotification(
                          title: 'Test Notification',
                          body: 'This is a test notification from Loans Tracker Pro!',
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Failed to trigger notification: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(
                      Icons.file_download,
                      color: Color(0xFF64B5F6),
                    ),
                    title: const Text('Export CSV'),
                    subtitle: const Text('Export all loan data to CSV file'),
                    onTap: () => _exportCsv(context),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF64B5F6),
                    ),
                    title: const Text('Export Monthly CSV'),
                    subtitle: const Text('Export monthly report summaries to CSV'),
                    onTap: () => _exportMonthlyCsv(context),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.backup_rounded,
                      color: Color(0xFF64B5F6),
                    ),
                    title: const Text('Backup Data'),
                    subtitle: const Text('Backup settings and loans to a JSON file'),
                    onTap: () => BackupService.backupData(context),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.restore_rounded,
                      color: Color(0xFF64B5F6),
                    ),
                    title: const Text('Restore Data'),
                    subtitle: const Text('Restore settings and loans from a JSON file'),
                    onTap: () => BackupService.restoreData(context),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.folder_open_rounded,
                      color: Color(0xFF64B5F6),
                    ),
                    title: const Text('Change Save Directory'),
                    subtitle: Text('Current: $_activeExportPath'),
                    onTap: () => _changeSaveDirectory(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'About',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: Color(0xFF64B5F6)),
                    title: Text('Loans Tracker'),
                    subtitle: Text('Version: 1.2.0'),
                  ),
                  ListTile(
                    leading: Icon(Icons.person, color: Color(0xFF64B5F6)),
                    title: Text('Developer'),
                    subtitle: Text('Naonga Gondwe'),
                  ),
                  ListTile(
                    leading: Icon(Icons.business, color: Color(0xFF64B5F6)),
                    title: Text('Developer Company'),
                    subtitle: Text('CommandLine'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildColorOption(
    Color color,
    Color currentAccent,
    ThemeController themeCtrl,
  ) {
    final isSelected = color == currentAccent;

    return GestureDetector(
      onTap: () {
        themeCtrl.setAccent(color);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
            : null,
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final provider = Provider.of<LoanProvider>(context, listen: false);
    final people = provider.people;
    if (people.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No loans to export')));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      // 1. Generate the CSV using our robust package-backed exporter
      final filePath = await CsvExporter.exportLoansToCsv(people);
      final fileName = filePath.split('/').last;

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
        SnackBar(content: Text('CSV saved to: $displayPath/$fileName')),
      );

      // 2. Share the file immediately using the cross-platform share_plus sheet
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Loans Export',
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _exportMonthlyCsv(BuildContext context) async {
    final provider = Provider.of<LoanProvider>(context, listen: false);
    final people = provider.people;
    if (people.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No reports to export')));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      // 1. Generate the CSV using our robust package-backed exporter
      final filePath = await CsvExporter.exportMonthlyReportsToCsv(people);
      final fileName = filePath.split('/').last;

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
        SnackBar(content: Text('Monthly CSV saved to: $displayPath/$fileName')),
      );

      // 2. Share the file immediately using the cross-platform share_plus sheet
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Monthly Reports Export',
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}
