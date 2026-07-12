import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import 'category_providers.dart';
import 'repository_providers.dart';
import 'transaction_providers.dart';

class BudgetNotifier extends Notifier<List<Budget>> {
  @override
  List<Budget> build() {
    return ref.watch(budgetRepositoryProvider).getAll();
  }

  Future<void> upsert(Budget budget) async {
    await ref.read(budgetRepositoryProvider).save(budget);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(budgetRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final budgetNotifierProvider = NotifierProvider<BudgetNotifier, List<Budget>>(BudgetNotifier.new);

class BudgetProgress {
  const BudgetProgress({required this.category, required this.limit, required this.spent});

  final Category category;
  final double limit;
  final double spent;

  /// 0.0..1.0+ (can exceed 1 when over budget).
  double get ratio => limit <= 0 ? 0 : spent / limit;
}

/// Resolves which budget applies to [categoryId] in a given [year]/[month]:
/// a month-specific override always wins over the recurring default.
Budget? resolveEffectiveBudget(List<Budget> budgets, String categoryId, int year, int month) {
  Budget? fallback;
  for (final budget in budgets) {
    if (budget.categoryId != categoryId) continue;
    if (budget.year == year && budget.month == month) return budget;
    if (budget.year == null && budget.month == null) fallback = budget;
  }
  return fallback;
}

/// Pure function (no Riverpod dependency) so it can be unit-tested directly:
/// combines the effective budget of each category (for [year]/[month]) with
/// the actual spend within [transactions] (already filtered to that month
/// and to the relevant person).
List<BudgetProgress> computeBudgetProgress(
  List<Budget> budgets,
  List<Category> categories,
  List<Transaction> transactions,
  int year,
  int month,
) {
  final categoryById = {for (final c in categories) c.id: c};
  final spendByCategory = <String, double>{};
  for (final t in transactions.where((t) => !t.isIncome)) {
    spendByCategory[t.categoryId] = (spendByCategory[t.categoryId] ?? 0) + t.amount.abs();
  }

  final progress = <BudgetProgress>[];
  for (final categoryId in budgets.map((b) => b.categoryId).toSet()) {
    final category = categoryById[categoryId];
    if (category == null) continue; // category was deleted
    final effective = resolveEffectiveBudget(budgets, categoryId, year, month);
    if (effective == null || effective.monthlyLimit <= 0) continue;
    progress.add(BudgetProgress(
      category: category,
      limit: effective.monthlyLimit,
      spent: spendByCategory[categoryId] ?? 0,
    ));
  }
  progress.sort((a, b) => b.ratio.compareTo(a.ratio));
  return progress;
}

/// Same idea as [computeBudgetProgress] but aggregated over a whole [year]:
/// the planned limit is the sum of the effective (override-or-default)
/// monthly limit across all 12 months, compared against the year's actual
/// spend per category.
List<BudgetProgress> computeYearlyBudgetProgress(
  List<Budget> budgets,
  List<Category> categories,
  List<Transaction> transactionsForYear,
  int year,
) {
  final categoryById = {for (final c in categories) c.id: c};
  final spendByCategory = <String, double>{};
  for (final t in transactionsForYear.where((t) => !t.isIncome)) {
    spendByCategory[t.categoryId] = (spendByCategory[t.categoryId] ?? 0) + t.amount.abs();
  }

  final progress = <BudgetProgress>[];
  for (final categoryId in budgets.map((b) => b.categoryId).toSet()) {
    final category = categoryById[categoryId];
    if (category == null) continue;

    var totalPlanned = 0.0;
    for (var month = 1; month <= 12; month++) {
      totalPlanned += resolveEffectiveBudget(budgets, categoryId, year, month)?.monthlyLimit ?? 0;
    }
    if (totalPlanned <= 0) continue;

    progress.add(BudgetProgress(
      category: category,
      limit: totalPlanned,
      spent: spendByCategory[categoryId] ?? 0,
    ));
  }
  progress.sort((a, b) => b.ratio.compareTo(a.ratio));
  return progress;
}

final budgetProgressForSelectedMonthProvider = Provider<List<BudgetProgress>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final budgets = ref.watch(budgetNotifierProvider);
  final categories = ref.watch(categoryNotifierProvider);
  final transactions = ref.watch(transactionsForSelectedMonthProvider);
  return computeBudgetProgress(budgets, categories, transactions, month.year, month.month);
});

final budgetProgressForSelectedYearProvider = Provider<List<BudgetProgress>>((ref) {
  final year = ref.watch(selectedYearProvider);
  final budgets = ref.watch(budgetNotifierProvider);
  final categories = ref.watch(categoryNotifierProvider);
  final transactions = ref.watch(transactionsForSelectedYearProvider);
  return computeYearlyBudgetProgress(budgets, categories, transactions, year);
});
