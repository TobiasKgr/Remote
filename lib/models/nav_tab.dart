import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../screens/assets_screen.dart';
import '../screens/budgets_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/import_screen.dart';
import '../screens/salary_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/yearly_overview_screen.dart';
import '../screens/yearly_planner_screen.dart';

/// One entry in the main tab bar/navigation rail, outside the fixed
/// "Übersicht" home tab and "Mehr" overflow tab - both order and whether it
/// shows directly in the bar (vs. tucked under "Mehr") are user-configurable,
/// see [NavOrderNotifier]/[NavHiddenNotifier].
class NavTabDefinition {
  const NavTabDefinition({
    required this.key,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screenBuilder,
    this.canHide = true,
  });

  /// Stable identifier persisted to disk - never change an existing key,
  /// only add new ones, or a user's saved order/visibility silently drops it.
  final String key;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() screenBuilder;

  /// False for the one tab ("Übersicht") that must always stay directly
  /// reachable - its position can still be moved.
  final bool canHide;
}

/// Every configurable tab, in the app's default order - this is exactly the
/// order/set that shipped before the tab bar became customizable, so
/// installs that never touch the new setting see no change in behavior.
const List<NavTabDefinition> kConfigurableNavTabs = [
  NavTabDefinition(key: 'vermoegen', label: 'Vermögen', icon: CupertinoIcons.chart_pie, selectedIcon: CupertinoIcons.chart_pie_fill, screenBuilder: AssetsScreen.new),
  NavTabDefinition(key: 'budgets', label: 'Budgets', icon: CupertinoIcons.graph_circle, selectedIcon: CupertinoIcons.graph_circle_fill, screenBuilder: BudgetsScreen.new),
  NavTabDefinition(
    key: 'jahresplaner',
    label: 'Jahresplaner',
    icon: CupertinoIcons.square_grid_3x2,
    selectedIcon: CupertinoIcons.square_grid_3x2_fill,
    screenBuilder: YearlyPlannerScreen.new,
  ),
  NavTabDefinition(
    key: 'uebersicht',
    label: 'Übersicht',
    icon: CupertinoIcons.house,
    selectedIcon: CupertinoIcons.house_fill,
    screenBuilder: DashboardScreen.new,
    canHide: false,
  ),
  NavTabDefinition(key: 'buchungen', label: 'Buchungen', icon: CupertinoIcons.list_bullet, selectedIcon: CupertinoIcons.list_bullet, screenBuilder: TransactionsScreen.new),
  NavTabDefinition(
    key: 'kontoauszug_import',
    label: 'Kontoauszug-Import',
    icon: CupertinoIcons.arrow_up_doc,
    selectedIcon: CupertinoIcons.arrow_up_doc_fill,
    screenBuilder: ImportScreen.new,
  ),
  NavTabDefinition(
    key: 'gehalt_import',
    label: 'Gehalt-Import',
    icon: CupertinoIcons.money_euro_circle,
    selectedIcon: CupertinoIcons.money_euro_circle_fill,
    screenBuilder: SalaryScreen.new,
  ),
  NavTabDefinition(key: 'jahr', label: 'Jahr', icon: CupertinoIcons.calendar, selectedIcon: CupertinoIcons.calendar, screenBuilder: YearlyOverviewScreen.new),
  NavTabDefinition(
    key: 'kategorien',
    label: 'Kategorien',
    icon: CupertinoIcons.square_grid_2x2,
    selectedIcon: CupertinoIcons.square_grid_2x2_fill,
    screenBuilder: CategoriesScreen.new,
  ),
];

final Map<String, NavTabDefinition> kNavTabRegistry = {for (final t in kConfigurableNavTabs) t.key: t};

/// Derived (not hand-duplicated) from [kConfigurableNavTabs] so the default
/// order can never drift out of sync with the registry itself.
List<String> get kDefaultNavOrder => [for (final t in kConfigurableNavTabs) t.key];
