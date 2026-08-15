import 'dart:ui';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/budget_providers.dart';
import '../providers/insight_providers.dart';
import '../providers/settings_providers.dart';
import '../providers/transaction_providers.dart';
import '../services/notification_service.dart';
import '../services/optimization_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'categories_screen.dart';
import 'dashboard_screen.dart';
import 'import_screen.dart';
import 'more_screen.dart';
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
    NavigationDestination(icon: Icon(CupertinoIcons.house), selectedIcon: Icon(CupertinoIcons.house_fill), label: 'Übersicht'),
    NavigationDestination(icon: Icon(CupertinoIcons.list_bullet), selectedIcon: Icon(CupertinoIcons.list_bullet), label: 'Buchungen'),
    NavigationDestination(icon: Icon(CupertinoIcons.arrow_up_doc), selectedIcon: Icon(CupertinoIcons.arrow_up_doc_fill), label: 'Kontoauszug-Import'),
    NavigationDestination(icon: Icon(CupertinoIcons.money_euro_circle), selectedIcon: Icon(CupertinoIcons.money_euro_circle_fill), label: 'Gehalt-Import'),
    NavigationDestination(icon: Icon(CupertinoIcons.calendar), selectedIcon: Icon(CupertinoIcons.calendar), label: 'Jahr'),
    NavigationDestination(icon: Icon(CupertinoIcons.square_grid_2x2), selectedIcon: Icon(CupertinoIcons.square_grid_2x2_fill), label: 'Kategorien'),
    NavigationDestination(icon: Icon(CupertinoIcons.ellipsis_circle), selectedIcon: Icon(CupertinoIcons.ellipsis_circle_fill), label: 'Mehr'),
  ];

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    ImportScreen(),
    SalaryScreen(),
    YearlyOverviewScreen(),
    CategoriesScreen(),
    MoreScreen(),
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
    final separator = context.appleColors.separator;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border(right: BorderSide(color: separator, width: 0.5))),
                  child: NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: context.appleColors.secondaryGroupedBackground.withValues(alpha: 0.75),
                    destinations: _destinations
                        .map((d) => NavigationRailDestination(icon: d.icon, selectedIcon: d.selectedIcon, label: Text(d.label)))
                        .toList(),
                  ),
                ),
              ),
            ),
            Expanded(child: _screens[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _screens[_index],
      // iOS tab bars are a translucent, blurred material sitting on top of
      // the content rather than an opaque bar - BackdropFilter + a
      // semi-transparent NavigationBar (see AppTheme) reproduces that.
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: separator, width: 0.5))),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: _destinations,
            ),
          ),
        ),
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
