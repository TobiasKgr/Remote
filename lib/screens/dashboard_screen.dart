import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/category_providers.dart';
import '../providers/transaction_providers.dart';
import '../models/category.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/month_selector.dart';
import '../widgets/person_filter_bar.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final transactions = ref.watch(transactionsForSelectedMonthProvider);
    final categories = ref.watch(categoryNotifierProvider);

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

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MonthSelector(month: month, onChanged: (m) => ref.read(selectedMonthProvider.notifier).state = m),
          const PersonFilterBar(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SummaryCard(label: 'Einnahmen', amount: income, color: Colors.green, icon: Icons.arrow_downward)),
              const SizedBox(width: 12),
              Expanded(child: SummaryCard(label: 'Ausgaben', amount: expenses, color: Colors.red, icon: Icons.arrow_upward)),
            ],
          ),
          const SizedBox(height: 12),
          SummaryCard(
            label: 'Saldo (Gehalt vs. Ausgaben)',
            amount: balance,
            color: balance >= 0 ? Colors.green : Colors.red,
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 24),
          Text('Ausgaben nach Kategorie', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CategoryBreakdownChart(totals: breakdown),
            ),
          ),
        ],
      ),
    );
  }

  Category _unknownCategory() => Category(id: 'unknown', name: 'Unbekannt', type: CategoryType.expense, colorValue: 0xFF9E9E9E);
}
