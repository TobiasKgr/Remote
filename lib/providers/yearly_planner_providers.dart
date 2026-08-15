import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/description_normalizer.dart';
import 'category_providers.dart';
import 'transaction_providers.dart';

/// One row of the yearly planner: all bookings that share the same
/// normalized description (e.g. every "REWE SAGT DANKE ..." booking, or
/// every "Miete" booking), pivoted into one amount per calendar month.
class YearlyPlannerRow {
  const YearlyPlannerRow({
    required this.label,
    required this.dueDay,
    required this.monthlyAmounts,
    required this.yearTotal,
    required this.percentOfTotal,
  });

  final String label;

  /// Day-of-month of the most recent booking in this row - shown as a
  /// rough "Termin" (due date) hint, not a guaranteed recurrence day.
  final int dueDay;

  /// Index 0 = January ... index 11 = December. Always a positive
  /// magnitude, even for expense rows (matches how the rest of the app
  /// displays expense totals).
  final List<double> monthlyAmounts;

  final double yearTotal;

  /// Share of this row's [yearTotal] within its section's (income or
  /// expense) yearly total, 0..1.
  final double percentOfTotal;
}

/// A category with all of its [YearlyPlannerRow]s for the year, so the
/// planner can group/section rows the same way the rest of the app already
/// categorizes recurring payments.
class YearlyPlannerCategoryGroup {
  const YearlyPlannerCategoryGroup({required this.category, required this.rows, required this.yearTotal});

  final Category category;
  final List<YearlyPlannerRow> rows;
  final double yearTotal;
}

class YearlyPlannerData {
  const YearlyPlannerData({
    required this.incomeGroups,
    required this.expenseGroups,
    required this.monthlyIncomeTotals,
    required this.monthlyExpenseTotals,
    required this.yearIncomeTotal,
    required this.yearExpenseTotal,
  });

  final List<YearlyPlannerCategoryGroup> incomeGroups;
  final List<YearlyPlannerCategoryGroup> expenseGroups;

  /// Index 0 = January ... index 11 = December.
  final List<double> monthlyIncomeTotals;
  final List<double> monthlyExpenseTotals;
  final double yearIncomeTotal;
  final double yearExpenseTotal;
}

class _SeriesAggregate {
  _SeriesAggregate({required this.isIncome, required this.categoryId, required this.label, required this.dueDay});

  final bool isIncome;
  final String categoryId;
  final String label;
  final int dueDay;
  final List<double> monthly = List<double>.filled(12, 0);

  double get yearTotal => monthly.fold<double>(0, (s, v) => s + v);
}

/// Pure function (no Riverpod dependency): pivots a year's bookings into
/// the [YearlyPlannerData] grid - one row per recurring/unique payment
/// (grouped by [normalizeDescription], the same grouping used for learned
/// categorization and recurring-transaction detection), one column per
/// month, rows grouped by category. Internal transfers between own
/// accounts are excluded, same as everywhere else in the app.
YearlyPlannerData computeYearlyPlanner(List<Transaction> yearTransactions, List<Category> categories) {
  final categoryById = {for (final c in categories) c.id: c};

  final relevant = yearTransactions.where((t) => !t.isTransfer).toList()..sort((a, b) => a.date.compareTo(b.date));

  final seriesByKey = <String, List<Transaction>>{};
  for (final t in relevant) {
    final normalized = normalizeDescription(t.description);
    final key = normalized.isEmpty ? 'id:${t.id}' : normalized;
    seriesByKey.putIfAbsent(key, () => []).add(t);
  }

  final aggregates = <_SeriesAggregate>[];
  for (final entries in seriesByKey.values) {
    // entries were appended while iterating `relevant` in ascending date
    // order, so the last entry is chronologically the most recent one -
    // its category/description/isIncome decide the whole row, same
    // philosophy as RecurringTransactionService ("latest booking decides").
    final latest = entries.last;
    final aggregate = _SeriesAggregate(isIncome: latest.isIncome, categoryId: latest.categoryId, label: latest.description.trim(), dueDay: latest.date.day);
    for (final t in entries) {
      aggregate.monthly[t.date.month - 1] += latest.isIncome ? t.amount : t.amount.abs();
    }
    aggregates.add(aggregate);
  }

  final monthlyIncomeTotals = List<double>.filled(12, 0);
  final monthlyExpenseTotals = List<double>.filled(12, 0);
  for (final aggregate in aggregates) {
    final target = aggregate.isIncome ? monthlyIncomeTotals : monthlyExpenseTotals;
    for (var i = 0; i < 12; i++) {
      target[i] += aggregate.monthly[i];
    }
  }
  final yearIncomeTotal = monthlyIncomeTotals.fold<double>(0, (s, v) => s + v);
  final yearExpenseTotal = monthlyExpenseTotals.fold<double>(0, (s, v) => s + v);

  final incomeByCategory = <String, List<YearlyPlannerRow>>{};
  final expenseByCategory = <String, List<YearlyPlannerRow>>{};
  for (final aggregate in aggregates) {
    final sectionTotal = aggregate.isIncome ? yearIncomeTotal : yearExpenseTotal;
    final row = YearlyPlannerRow(
      label: aggregate.label,
      dueDay: aggregate.dueDay,
      monthlyAmounts: List.unmodifiable(aggregate.monthly),
      yearTotal: aggregate.yearTotal,
      percentOfTotal: sectionTotal == 0 ? 0 : aggregate.yearTotal / sectionTotal,
    );
    final bucket = aggregate.isIncome ? incomeByCategory : expenseByCategory;
    bucket.putIfAbsent(aggregate.categoryId, () => []).add(row);
  }

  List<YearlyPlannerCategoryGroup> buildGroups(Map<String, List<YearlyPlannerRow>> byCategory, CategoryType fallbackType) {
    final groups = <YearlyPlannerCategoryGroup>[];
    for (final entry in byCategory.entries) {
      final rows = entry.value..sort((a, b) => b.yearTotal.compareTo(a.yearTotal));
      final category = categoryById[entry.key] ?? Category(id: entry.key, name: 'Unbekannt', type: fallbackType, colorValue: 0xFF9E9E9E);
      final yearTotal = rows.fold<double>(0, (s, r) => s + r.yearTotal);
      groups.add(YearlyPlannerCategoryGroup(category: category, rows: rows, yearTotal: yearTotal));
    }
    groups.sort((a, b) => b.yearTotal.compareTo(a.yearTotal));
    return groups;
  }

  return YearlyPlannerData(
    incomeGroups: buildGroups(incomeByCategory, CategoryType.income),
    expenseGroups: buildGroups(expenseByCategory, CategoryType.expense),
    monthlyIncomeTotals: monthlyIncomeTotals,
    monthlyExpenseTotals: monthlyExpenseTotals,
    yearIncomeTotal: yearIncomeTotal,
    yearExpenseTotal: yearExpenseTotal,
  );
}

final yearlyPlannerProvider = Provider<YearlyPlannerData>((ref) {
  final transactions = ref.watch(transactionsForSelectedYearProvider);
  final categories = ref.watch(categoryNotifierProvider);
  return computeYearlyPlanner(transactions, categories);
});
