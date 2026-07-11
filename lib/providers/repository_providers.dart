import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../data/hive_setup.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../repositories/category_repository.dart';
import '../repositories/transaction_repository.dart';

/// Boxes are opened once in `main()` before `runApp`, so accessing them here
/// via `Hive.box` (sync) is safe.
final categoryBoxProvider = Provider<Box<Category>>((ref) => Hive.box<Category>(categoryBoxName));

final transactionBoxProvider = Provider<Box<Transaction>>((ref) => Hive.box<Transaction>(transactionBoxName));

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(categoryBoxProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(transactionBoxProvider));
});
