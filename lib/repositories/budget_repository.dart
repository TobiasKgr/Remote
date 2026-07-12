import 'package:hive/hive.dart';

import '../models/budget.dart';

class BudgetRepository {
  BudgetRepository(this._box);

  final Box<Budget> _box;

  List<Budget> getAll() => _box.values.toList(growable: false);

  Budget? getById(String id) => _box.get(id);

  Future<void> save(Budget budget) => _box.put(budget.id, budget);

  Future<void> delete(String id) => _box.delete(id);
}
