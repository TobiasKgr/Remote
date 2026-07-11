import 'package:hive_flutter/hive_flutter.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import 'default_categories.dart';

const categoryBoxName = 'categories';
const transactionBoxName = 'transactions';

/// Initializes Hive, registers all [TypeAdapter]s, opens the boxes used by
/// the app and seeds default categories on first launch.
Future<void> initHive() async {
  await Hive.initFlutter();

  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(SubcategoryAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(CategoryTypeAdapter());
  Hive.registerAdapter(TransactionSourceAdapter());

  final categoryBox = await Hive.openBox<Category>(categoryBoxName);
  await Hive.openBox<Transaction>(transactionBoxName);

  if (categoryBox.isEmpty) {
    for (final category in buildDefaultCategories()) {
      await categoryBox.put(category.id, category);
    }
  }
}
