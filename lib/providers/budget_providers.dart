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

  Future<void> remove(String categoryId) async {
    await ref.read(budgetRepositoryProvider).delete(categoryId);
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

/// Pure function (no Riverpod dependency) so it can be unit-tested directly:
/// combines each [Budget] with the actual spend of its category within
/// [transactions] (already filtered to the relevant month/person).
List<BudgetProgress> computeBudgetProgress(
  List<Budget> budgets,
  List<Category> categories,
  List<Transaction> transactions,
) {
  final categoryById = {for (final c in categories) c.id: c};
  final spendByCategory = <String, double>{};
  for (final t in transactions.where((t) => !t.isIncome)) {
    spendByCategory[t.categoryId] = (spendByCategory[t.categoryId] ?? 0) + t.amount.abs();
  }

  final progress = <BudgetProgress>[];
  for (final budget in budgets) {
    final category = categoryById[budget.categoryId];
    if (category == null) continue; // category was deleted
    progress.add(BudgetProgress(
      category: category,
      limit: budget.monthlyLimit,
      spent: spendByCategory[budget.categoryId] ?? 0,
    ));
  }
  progress.sort((a, b) => b.ratio.compareTo(a.ratio));
  return progress;
}

final budgetProgressForSelectedMonthProvider = Provider<List<BudgetProgress>>((ref) {
  final budgets = ref.watch(budgetNotifierProvider);
  final categories = ref.watch(categoryNotifierProvider);
  final transactions = ref.watch(transactionsForSelectedMonthProvider);
  return computeBudgetProgress(budgets, categories, transactions);
});
