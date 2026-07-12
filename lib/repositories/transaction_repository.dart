import 'package:hive/hive.dart';

import '../models/transaction.dart';

class TransactionRepository {
  TransactionRepository(this._box);

  final Box<Transaction> _box;

  List<Transaction> getAll() => _box.values.toList(growable: false);

  Transaction? getById(String id) => _box.get(id);

  List<Transaction> getForMonth(int year, int month) {
    return _box.values
        .where((t) => t.date.year == year && t.date.month == month)
        .toList(growable: false)
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Transaction> getForYear(int year) {
    return _box.values.where((t) => t.date.year == year).toList(growable: false)
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> save(Transaction transaction) => _box.put(transaction.id, transaction);

  Future<void> saveAll(Iterable<Transaction> transactions) {
    return _box.putAll({for (final t in transactions) t.id: t});
  }

  Future<void> delete(String id) => _box.delete(id);
}
