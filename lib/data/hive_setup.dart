import 'package:hive_flutter/hive_flutter.dart';

import '../models/account.dart';
import '../models/asset.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/company_car.dart';
import '../models/person.dart';
import '../models/salary_slip.dart';
import '../models/transaction.dart';
import 'default_categories.dart';

const categoryBoxName = 'categories';
const transactionBoxName = 'transactions';
const salarySlipBoxName = 'salary_slips';
const personBoxName = 'persons';
const companyCarBoxName = 'company_cars';
const budgetBoxName = 'budgets';
const settingsBoxName = 'settings';
const accountBoxName = 'accounts';
const assetBoxName = 'assets';

/// Initializes Hive, registers all [TypeAdapter]s, opens the boxes used by
/// the app and seeds default categories on first launch.
Future<void> initHive() async {
  await Hive.initFlutter();

  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(SubcategoryAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(CategoryTypeAdapter());
  Hive.registerAdapter(TransactionSourceAdapter());
  Hive.registerAdapter(SalarySlipAdapter());
  Hive.registerAdapter(PersonAdapter());
  Hive.registerAdapter(CompanyCarAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(AccountAdapter());
  Hive.registerAdapter(AssetAdapter());
  Hive.registerAdapter(AssetCategoryAdapter());

  final categoryBox = await Hive.openBox<Category>(categoryBoxName);
  await Hive.openBox<Transaction>(transactionBoxName);
  await Hive.openBox<SalarySlip>(salarySlipBoxName);
  await Hive.openBox<Person>(personBoxName);
  await Hive.openBox<CompanyCar>(companyCarBoxName);
  await Hive.openBox<Budget>(budgetBoxName);
  await Hive.openBox(settingsBoxName);
  await Hive.openBox<Account>(accountBoxName);
  await Hive.openBox<Asset>(assetBoxName);

  if (categoryBox.isEmpty) {
    for (final category in buildDefaultCategories()) {
      await categoryBox.put(category.id, category);
    }
  } else if (!categoryBox.containsKey('umbuchung')) {
    // Added after initial release: back-fill the system category used by
    // the account transfer flow onto installs seeded before it existed.
    await categoryBox.put('umbuchung', buildDefaultCategories().firstWhere((c) => c.id == 'umbuchung'));
  }
}
