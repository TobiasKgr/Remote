import 'package:flutter/material.dart';

import 'categories_screen.dart';
import 'dashboard_screen.dart';
import 'import_screen.dart';
import 'transactions_screen.dart';
import 'yearly_overview_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Übersicht'),
    NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Buchungen'),
    NavigationDestination(icon: Icon(Icons.upload_file_outlined), selectedIcon: Icon(Icons.upload_file), label: 'Import'),
    NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Jahr'),
    NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: 'Kategorien'),
  ];

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    ImportScreen(),
    YearlyOverviewScreen(),
    CategoriesScreen(),
  ];

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
}
