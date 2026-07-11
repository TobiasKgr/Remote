import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/category_providers.dart';
import '../providers/transaction_providers.dart';
import '../utils/formatters.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/person_filter_bar.dart';
import '../widgets/summary_card.dart';

class YearlyOverviewScreen extends ConsumerWidget {
  const YearlyOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearProvider);
    final transactions = ref.watch(transactionsForSelectedYearProvider);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jahresübersicht'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(selectedYearProvider.notifier).state = year - 1,
          ),
          Center(child: Text('$year', style: Theme.of(context).textTheme.titleMedium)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(selectedYearProvider.notifier).state = year + 1,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const PersonFilterBar(),
            Row(
              children: [
                Expanded(child: SummaryCard(label: 'Einnahmen $year', amount: totalIncome, color: Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: SummaryCard(label: 'Ausgaben $year', amount: totalExpense, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 12),
            SummaryCard(
              label: 'Jahressaldo',
              amount: totalIncome - totalExpense,
              color: (totalIncome - totalExpense) >= 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 24),
            Text('Einnahmen vs. Ausgaben pro Monat', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: maxY == 0
                  ? const Center(child: Text('Keine Daten für dieses Jahr.'))
                  : BarChart(
                      BarChartData(
                        maxY: maxY * 1.2,
                        barGroups: [
                          for (var i = 0; i < 12; i++)
                            BarChartGroupData(x: i, barRods: [
                              BarChartRodData(toY: incomeByMonth[i], color: Colors.green, width: 6),
                              BarChartRodData(toY: expenseByMonth[i], color: Colors.red, width: 6),
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
            const SizedBox(height: 24),
            Text('Ausgaben nach Kategorie ($year)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CategoryBreakdownChart(totals: breakdown),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
