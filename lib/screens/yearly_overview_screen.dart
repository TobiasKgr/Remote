import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/category_providers.dart';
import '../providers/transaction_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';
import '../widgets/budget_progress_section.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/person_filter_bar.dart';
import '../widgets/summary_card.dart';

class YearlyOverviewScreen extends ConsumerWidget {
  const YearlyOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearProvider);
    final transactions = ref.watch(transactionsForSelectedYearProvider).where((t) => !t.isTransfer);
    final categories = ref.watch(categoryNotifierProvider);
    final categoryById = {for (final c in categories) c.id: c};

    final incomeByMonth = List<double>.filled(12, 0);
    final expenseByMonth = List<double>.filled(12, 0);
    final expenseTotals = <String, double>{};

    for (final t in transactions) {
      final monthIndex = t.date.month - 1;
      if (t.isIncome) {
        incomeByMonth[monthIndex] += t.amount;
      } else {
        expenseByMonth[monthIndex] += t.amount.abs();
        expenseTotals[t.categoryId] = (expenseTotals[t.categoryId] ?? 0) + t.amount.abs();
      }
    }

    final totalIncome = incomeByMonth.fold<double>(0, (s, v) => s + v);
    final totalExpense = expenseByMonth.fold<double>(0, (s, v) => s + v);

    final breakdown = expenseTotals.entries
        .where((e) => categoryById[e.key] != null)
        .map((e) => CategoryTotal(categoryById[e.key]!, e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final maxY = [...incomeByMonth, ...expenseByMonth].fold<double>(0, (m, v) => v > m ? v : m);
    final colors = context.appleColors;

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.chevron_left),
            onPressed: () => ref.read(selectedYearProvider.notifier).state = year - 1,
          ),
          Center(child: Text('$year', style: Theme.of(context).textTheme.titleMedium)),
          IconButton(
            icon: const Icon(CupertinoIcons.chevron_right),
            onPressed: () => ref.read(selectedYearProvider.notifier).state = year + 1,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const AppleLargeTitle('Jahresübersicht'),
            const PersonFilterBar(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: SummaryCard(label: 'Einnahmen $year', amount: totalIncome, color: colors.success)),
                  const SizedBox(width: 12),
                  Expanded(child: SummaryCard(label: 'Ausgaben $year', amount: totalExpense, color: colors.danger)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppleHeroCard(
              label: 'Jahressaldo',
              value: currencyFormat.format(totalIncome - totalExpense),
              valueColor: (totalIncome - totalExpense) >= 0 ? colors.success : colors.danger,
            ),
            const AppleSectionHeader('Einnahmen vs. Ausgaben pro Monat'),
            AppleCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 240,
                  child: maxY == 0
                      ? const Center(child: Text('Keine Daten für dieses Jahr.'))
                      : BarChart(
                          BarChartData(
                            maxY: maxY * 1.2,
                            barGroups: [
                              for (var i = 0; i < 12; i++)
                                BarChartGroupData(x: i, barRods: [
                                  BarChartRodData(toY: incomeByMonth[i], color: colors.success, width: 6, borderRadius: BorderRadius.circular(2)),
                                  BarChartRodData(toY: expenseByMonth[i], color: colors.danger, width: 6, borderRadius: BorderRadius.circular(2)),
                                ]),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i > 11) return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(monthNamesDe[i].substring(0, 3), style: const TextStyle(fontSize: 10)),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                          ),
                        ),
                ),
              ),
            ),
            AppleSectionHeader('Ausgaben nach Kategorie ($year)'),
            AppleCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CategoryBreakdownChart(totals: breakdown),
              ),
            ),
            const YearlyBudgetProgressSection(),
          ],
        ),
      ),
    );
  }
}
