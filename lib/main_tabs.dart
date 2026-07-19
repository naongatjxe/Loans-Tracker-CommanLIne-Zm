import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/monthly_report_page.dart';
import 'pages/contract_page.dart';

import 'theme/theme_controller.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _currentIndex = 0;

  final GlobalKey<HomePageState> homeKey = GlobalKey<HomePageState>();

  late final List<Widget> _pages = [
    HomePage(key: homeKey),
    const DashboardPage(),
    const MonthlyReportPage(),
    const ContractPage(),
  ];

  final List<String> _titles = ['Loans', 'Dashboard', 'Monthly', 'Contract'];

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_currentIndex == 0) {
      // Home page with swipeable TabBar - no AppBar
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          body: HomePage(key: homeKey),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            indicatorColor: themeController.accent.withValues(alpha: 0.15),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.list_alt_rounded),
                label: 'Loans',
              ),
              NavigationDestination(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_rounded),
                label: 'Monthly',
              ),
              NavigationDestination(
                icon: Icon(Icons.description_rounded),
                label: 'Contract',
              ),
            ],
          ),
        ),
      );
    } else {
      // Other pages without tabs
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _titles[_currentIndex],
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
                    Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        body: _pages[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          indicatorColor: themeController.accent.withValues(alpha: 0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.list_alt_rounded),
              label: 'Loans',
            ),
            NavigationDestination(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'Monthly',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_rounded),
              label: 'Contract',
            ),
          ],
        ),
      );
    }
  }
}
