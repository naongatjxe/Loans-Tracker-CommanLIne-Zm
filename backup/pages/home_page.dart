import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../utils/loan_provider.dart';
import 'loan_details_page.dart';
import 'loan_edit_page_new.dart';
import 'settings_page.dart';
import '../theme/theme_controller.dart';
import '../widgets/loan_card_compact.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchCtrl;
  String _searchQuery = '';
  late final TabController _tabController;
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _tabController = TabController(length: 3, vsync: this);
    _lastTabIndex = _tabController.index;
    _tabController.animation?.addListener(_handleTabAnimation);
  }

  void _handleTabAnimation() {
    final animationValue = _tabController.animation?.value;
    if (animationValue != null) {
      final newIndex = animationValue.round();
      if (newIndex != _lastTabIndex) {
        _lastTabIndex = newIndex;
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.animation?.removeListener(_handleTabAnimation);
    _tabController.dispose();
    super.dispose();
  }

  int get _currentTabIndex => _lastTabIndex;

  Future<void> _addLoan() async {
    final Person? person = await Navigator.push<Person>(
      context,
      MaterialPageRoute(builder: (context) => const LoanEditPage()),
    );

    if (person != null && mounted) {
      final provider = Provider.of<LoanProvider>(context, listen: false);
      provider.addPerson(person);
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Added loan for "${person.name}"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(
      context,
      listen: false,
    );

    return Consumer<LoanProvider>(
      builder: (context, provider, child) {
        final people = provider.people;
        final filtered = people.where((p) {
          return _searchQuery.isEmpty ||
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.nrc.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.phone.contains(_searchQuery);
        }).toList();

        final now = DateTime.now();
        final active = filtered.where((p) => !p.isPaid && p.dueDate.difference(now).inDays >= 0).toList();
        final overdue = filtered.where((p) => !p.isPaid && p.dueDate.difference(now).inDays < 0).toList();
        final paid = filtered.where((p) => p.isPaid).toList();

        return Scaffold(
          appBar: AppBar(
            leading: Icon(
              Icons.account_balance_wallet_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            title: const Text(
              'Loans Tracker Pro',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                },
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Settings',
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === TOP SEGMENTED NAV (looks like bottom navbar) ===
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _segment(
                        selected: _currentTabIndex == 0,
                        icon: Icons.play_circle_rounded,
                        label: 'Active',
                        onTap: () => _tabController.index = 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _segment(
                        selected: _currentTabIndex == 1,
                        icon: Icons.warning_amber_rounded,
                        label: 'Overdue',
                        onTap: () => _tabController.index = 1,
                        isOverdueColor: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _segment(
                        selected: _currentTabIndex == 2,
                        icon: Icons.task_alt_rounded,
                        label: 'Paid',
                        onTap: () => _tabController.index = 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // === SEARCH + ADD ===
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search loans…',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: themeController.accent,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  icon: const Icon(Icons.clear_rounded),
                                )
                              : null,
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      onPressed: _addLoan,
                      backgroundColor: themeController.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      child: const Icon(Icons.add, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // === SWIPEABLE CONTENT ===
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    active.isEmpty
                        ? _buildEmptyState('No active loans')
                        : _buildLoansList(active),
                    overdue.isEmpty
                        ? _buildEmptyState('No overdue loans')
                        : _buildLoansList(overdue),
                    paid.isEmpty
                        ? _buildEmptyState('No paid loans yet')
                        : _buildLoansList(paid),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoansList(List<Person> people) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: people.length,
      itemBuilder: (context, i) {
        final p = people[i];

        return LoanCardCompact(
          loan: p,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoanDetailsPage(person: p),
              ),
            );
          },
          onEdit: () => _editLoan(p),
          onDelete: () => _confirmDelete(p),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 72, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }

  // === Reusable segment that mimics NavigationBar destination look ===
  Widget _segment({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isOverdueColor = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeController = Provider.of<ThemeController>(
      context,
      listen: false,
    );

    final Color accentColor = isOverdueColor ? Colors.red : themeController.accent;

    final bg = selected
        ? accentColor.withValues(alpha: 0.2)
        : cs.surfaceContainerHighest.withValues(alpha: 0.14);
    final fg = selected ? accentColor : cs.onSurfaceVariant;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editLoan(Person person) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoanEditPage(person: person)),
    );

    if (result != null && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Updated loan for "${result.name}"')),
      );
    }
  }

  void _confirmDelete(Person person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Loan'),
        content: Text(
          'Are you sure you want to delete the loan for "${person.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final provider = Provider.of<LoanProvider>(
                context,
                listen: false,
              );
              provider.deletePerson(person.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted loan for "${person.name}"')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

