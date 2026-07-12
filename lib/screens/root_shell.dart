import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/budget_providers.dart';
import '../providers/insight_providers.dart';
import '../providers/settings_providers.dart';
import '../providers/transaction_providers.dart';
import '../services/notification_service.dart';
import '../services/optimization_service.dart';
import '../utils/formatters.dart';
import 'categories_screen.dart';
import 'dashboard_screen.dart';
import 'import_screen.dart';
import 'salary_screen.dart';
import 'transactions_screen.dart';
import 'yearly_overview_screen.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _index = 0;

  /// Keys of budget-overrun/insight notifications already shown this app
  /// session, so the same condition doesn't re-notify on every rebuild.
  final Set<String> _notifiedKeys = {};

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Übersicht'),
    NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Buchungen'),
    NavigationDestination(icon: Icon(Icons.upload_file_outlined), selectedIcon: Icon(Icons.upload_file), label: 'Import'),
    NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Gehalt'),
    NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Jahr'),
    NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: 'Kategorien'),
  ];

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    ImportScreen(),
    SalaryScreen(),
    YearlyOverviewScreen(),
    CategoriesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // listenManual (rather than listen) because this runs once outside
    // build, so fireImmediately can safely evaluate the current state too.
    ref.listenManual<List<BudgetProgress>>(
      budgetProgressForSelectedMonthProvider,
      (previous, next) => _handleBudgetProgress(next),
      fireImmediately: true,
    );
    ref.listenManual<List<Insight>>(
      insightsProvider,
      (previous, next) => _handleInsights(next),
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: _destinations
                  .map((d) => NavigationRailDestination(icon: d.icon, selectedIcon: d.selectedIcon, label: Text(d.label)))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _screens[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }

  void _handleBudgetProgress(List<BudgetProgress> progress) {
    if (!ref.read(notificationsEnabledProvider)) return;
    final month = ref.read(selectedMonthProvider);

    for (final p in progress) {
      if (p.ratio < 1) continue;
      final key = 'budget:${p.category.id}:${month.year}-${month.month}';
      if (_notifiedKeys.add(key)) {
        const NotificationService().show(
          key: key,
          title: 'Budget überschritten: ${p.category.name}',
          body: '${currencyFormat.format(p.spent)} von ${currencyFormat.format(p.limit)} ausgegeben.',
        );
      }
    }
  }

  void _handleInsights(List<Insight> insights) {
    if (!ref.read(notificationsEnabledProvider)) return;

    for (final insight in insights) {
      if (insight.severity != InsightSeverity.warning) continue;
      final key = 'insight:${insight.title}';
      if (_notifiedKeys.add(key)) {
        const NotificationService().show(key: key, title: insight.title, body: insight.description);
      }
    }
  }
}
