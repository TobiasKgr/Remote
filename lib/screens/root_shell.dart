import 'dart:ui';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/nav_tab.dart';
import '../providers/budget_providers.dart';
import '../providers/insight_providers.dart';
import '../providers/nav_settings_providers.dart';
import '../providers/settings_providers.dart';
import '../providers/transaction_providers.dart';
import '../services/notification_service.dart';
import '../services/optimization_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'more_screen.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  // "Übersicht" is always present (see kConfigurableNavTabs) and is the
  // default landing tab regardless of where the user has moved it to in
  // the (customizable) bar order.
  String _selectedKey = 'uebersicht';

  /// Keys of budget-overrun/insight notifications already shown this app
  /// session, so the same condition doesn't re-notify on every rebuild.
  final Set<String> _notifiedKeys = {};

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

    final order = ref.watch(navOrderProvider);
    final hidden = ref.watch(navHiddenProvider);
    final visibleTabs = [for (final key in order) if (!hidden.contains(key)) kNavTabRegistry[key]!];
    final keys = [for (final tab in visibleTabs) tab.key, 'mehr'];

    var index = keys.indexOf(_selectedKey);
    // The currently selected tab may have just been hidden (e.g. the user
    // navigated away to Einstellungen and hid it there) - fall back to the
    // first tab rather than crashing on an out-of-range index.
    if (index == -1) index = 0;

    final destinations = [
      for (final tab in visibleTabs) NavigationDestination(icon: Icon(tab.icon), selectedIcon: Icon(tab.selectedIcon), label: tab.label),
      const NavigationDestination(icon: Icon(CupertinoIcons.ellipsis_circle), selectedIcon: Icon(CupertinoIcons.ellipsis_circle_fill), label: 'Mehr'),
    ];
    final screens = [for (final tab in visibleTabs) tab.screenBuilder(), const MoreScreen()];

    void select(int i) => setState(() => _selectedKey = keys[i]);

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
                    selectedIndex: index,
                    onDestinationSelected: select,
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: context.appleColors.secondaryGroupedBackground.withValues(alpha: 0.75),
                    destinations: destinations
                        .map((d) => NavigationRailDestination(icon: d.icon, selectedIcon: d.selectedIcon, label: Text(d.label)))
                        .toList(),
                  ),
                ),
              ),
            ),
            Expanded(child: screens[index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: screens[index],
      // iOS tab bars are a translucent, blurred material sitting on top of
      // the content rather than an opaque bar - BackdropFilter + a
      // semi-transparent NavigationBar (see AppTheme) reproduces that.
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: separator, width: 0.5))),
            child: NavigationBar(selectedIndex: index, onDestinationSelected: select, destinations: destinations),
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
