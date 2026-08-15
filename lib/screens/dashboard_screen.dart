import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/category_providers.dart';
import '../providers/transaction_providers.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';
import '../widgets/budget_progress_section.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/insights_section.dart';
import '../widgets/month_selector.dart';
import '../widgets/person_filter_bar.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final transactions = ref.watch(transactionsForSelectedMonthProvider).where((t) => !t.isTransfer);
    final categories = ref.watch(categoryNotifierProvider);
    final colors = context.appleColors;

    final income = transactions.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final expenses = transactions.where((t) => !t.isIncome).fold<double>(0, (s, t) => s + t.amount.abs());
    final balance = income - expenses;

    final categoryById = {for (final c in categories) c.id: c};
    final expenseTotals = <String, double>{};
    for (final t in transactions.where((t) => !t.isIncome)) {
      expenseTotals[t.categoryId] = (expenseTotals[t.categoryId] ?? 0) + t.amount.abs();
    }
    final breakdown = expenseTotals.entries
        .map((e) => CategoryTotal(categoryById[e.key] ?? _unknownCategory(), e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const AppleLargeTitle('Übersicht'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  MonthSelector(month: month, onChanged: (m) => ref.read(selectedMonthProvider.notifier).state = m),
                  const PersonFilterBar(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: SummaryCard(label: 'Einnahmen', amount: income, color: colors.success, icon: CupertinoIcons.arrow_down)),
                  const SizedBox(width: 12),
                  Expanded(child: SummaryCard(label: 'Ausgaben', amount: expenses, color: colors.danger, icon: CupertinoIcons.arrow_up)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppleHeroCard(
              label: 'Saldo',
              value: currencyFormat.format(balance),
              valueColor: balance >= 0 ? colors.success : colors.danger,
            ),
            AppleSectionHeader('Ausgaben nach Kategorie'),
            AppleCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CategoryBreakdownChart(totals: breakdown),
              ),
            ),
            const BudgetProgressSection(),
            const InsightsSection(),
          ],
        ),
      ),
    );
  }

  Category _unknownCategory() => Category(id: 'unknown', name: 'Unbekannt', type: CategoryType.expense, colorValue: 0xFF9E9E9E);
}
