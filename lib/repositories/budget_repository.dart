import 'package:hive/hive.dart';

import '../models/budget.dart';

class BudgetRepository {
  BudgetRepository(this._box);

  final Box<Budget> _box;

  List<Budget> getAll() => _box.values.toList(growable: false);

  Budget? getForCategory(String categoryId) => _box.get(categoryId);

  Future<void> save(Budget budget) => _box.put(budget.categoryId, budget);

  Future<void> delete(String categoryId) => _box.delete(categoryId);
}
