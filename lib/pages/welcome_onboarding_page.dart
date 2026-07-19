import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../theme/theme_controller.dart';
import '../main_tabs.dart';

class WelcomeOnboardingPage extends StatefulWidget {
  const WelcomeOnboardingPage({super.key});

  @override
  State<WelcomeOnboardingPage> createState() => _WelcomeOnboardingPageState();
}

class _WelcomeOnboardingPageState extends State<WelcomeOnboardingPage> {
  bool _notificationGranted = false;
  bool _exactAlarmGranted = false;
  bool _storageGranted = false;
  String _saveFolderPath = 'Downloads/Loans Tracker';
  String? _rawCustomPath;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatuses();
  }

  int _getAndroidSdkVersion() {
    if (!Platform.isAndroid) return 0;
    try {
      final sdkMatch = RegExp(r'SDK\s+(\d+)').firstMatch(Platform.operatingSystemVersion) ??
                       RegExp(r'API\s+(\d+)').firstMatch(Platform.operatingSystemVersion);
      if (sdkMatch != null) {
        return int.parse(sdkMatch.group(1)!);
      }
      final androidMatch = RegExp(r'Android\s+(\d+)').firstMatch(Platform.operatingSystemVersion);
      if (androidMatch != null) {
        final version = int.parse(androidMatch.group(1)!);
        if (version >= 13) return 33;
        if (version == 12) return 31;
        if (version == 11) return 30;
        if (version == 10) return 29;
        if (version == 9) return 28;
      }
    } catch (_) {}
    return 0;
  }

  Future<void> _checkPermissionStatuses() async {
    final notificationStatus = await Permission.notification.status;
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    
    bool storageGranted = false;
    if (Platform.isAndroid) {
      final sdk = _getAndroidSdkVersion();
      if (sdk >= 30) {
        final manageStatus = await Permission.manageExternalStorage.status;
        storageGranted = manageStatus.isGranted;
      } else {
        final storageStatus = await Permission.storage.status;
        storageGranted = storageStatus.isGranted;
      }
    } else {
      storageGranted = true;
    }

    setState(() {
      _notificationGranted = notificationStatus.isGranted;
      _exactAlarmGranted = exactAlarmStatus.isGranted;
      _storageGranted = storageGranted;
    });
  }

  Future<void> _requestNotification() async {
    final status = await Permission.notification.request();
    setState(() {
      _notificationGranted = status.isGranted;
    });
  }

  Future<void> _requestExactAlarm() async {
    final status = await Permission.scheduleExactAlarm.request();
    setState(() {
      _exactAlarmGranted = status.isGranted;
    });
  }

  Future<void> _requestStorage() async {
    PermissionStatus status;
    if (Platform.isAndroid && _getAndroidSdkVersion() >= 30) {
      status = await Permission.manageExternalStorage.request();
    } else {
      status = await Permission.storage.request();
    }
    setState(() {
      _storageGranted = status.isGranted;
    });
  }

  Future<void> _chooseFolder() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath();
      if (path != null) {
        setState(() {
          _rawCustomPath = path;
          // Clean presentation for user
          if (path.length > 35) {
            _saveFolderPath = '...${path.substring(path.length - 32)}';
          } else {
            _saveFolderPath = path;
          }
        });
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    if (_rawCustomPath != null) {
      await prefs.setString('custom_export_path', _rawCustomPath!);
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainTabs()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeCtrl = Provider.of<ThemeController>(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    const Spacer(),

                    // App Logo / Icon Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: themeCtrl.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 64,
                        color: themeCtrl.accent,
                      ),
                    ),
                      const SizedBox(height: 24),

                    // Welcome Texts
                    Text(
                      'Loans Tracker Pro',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: cs.onSurface,
                      ),
                    ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your loans, track interest rates, and export summaries cleanly.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 16),

                      // Permissions Header
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'REQUIRED PERMISSIONS',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: themeCtrl.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Permission 1: Notifications
                      _buildPermissionCard(
                        icon: Icons.notifications_active_rounded,
                        title: 'Daily Reminders',
                        description: 'Receive alerts for upcoming or overdue loan payments.',
                        granted: _notificationGranted,
                        onTap: _requestNotification,
                        accentColor: themeCtrl.accent,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),

                      // Permission 2: Exact Alarms
                      _buildPermissionCard(
                        icon: Icons.alarm_rounded,
                        title: 'Exact Alarm Scheduling',
                        description: 'Ensures payment reminders trigger precisely at the scheduled hour.',
                        granted: _exactAlarmGranted,
                        onTap: _requestExactAlarm,
                        accentColor: themeCtrl.accent,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),

                      // Permission 3: Storage
                      _buildPermissionCard(
                        icon: Icons.folder_shared_rounded,
                        title: 'Storage Write Permission',
                        description: 'Required to create folders and save CSV exports and backup files.',
                        granted: _storageGranted,
                        onTap: _requestStorage,
                        accentColor: themeCtrl.accent,
                        theme: theme,
                      ),

                      const SizedBox(height: 24),

                      // Folder Selection Header
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'EXPORT DIRECTORY',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: themeCtrl.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Directory Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.folder_copy_rounded,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Save Location',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _saveFolderPath,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: cs.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: themeCtrl.accent,
                                  backgroundColor: themeCtrl.accent.withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: _chooseFolder,
                                icon: const Icon(Icons.drive_file_move_rounded, size: 18),
                                label: const Text(
                                  'Choose Custom Directory',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 32),

                      // Continue Button
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(27),
                          gradient: LinearGradient(
                            colors: [
                              themeCtrl.accent,
                              themeCtrl.accent.withBlue(240).withGreen(100),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: themeCtrl.accent.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                          onPressed: _completeOnboarding,
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool granted,
    required VoidCallback onTap,
    required Color accentColor,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          granted
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                )
              : SizedBox(
                  height: 32,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onTap,
                    child: const Text(
                      'Allow',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
