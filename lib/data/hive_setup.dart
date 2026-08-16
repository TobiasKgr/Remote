import 'package:hive_flutter/hive_flutter.dart';

import '../models/account.dart';
import '../models/asset.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/company_car.dart';
import '../models/custom_import_profile.dart';
import '../models/import_batch.dart';
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
const importBatchBoxName = 'import_batches';
const customImportProfileBoxName = 'custom_import_profiles';

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
  Hive.registerAdapter(AccountTypeAdapter());
  Hive.registerAdapter(AssetAdapter());
  Hive.registerAdapter(AssetCategoryAdapter());
  Hive.registerAdapter(ImportBatchAdapter());
  Hive.registerAdapter(ImportSourceAdapter());
  Hive.registerAdapter(CustomImportProfileAdapter());

  final categoryBox = await Hive.openBox<Category>(categoryBoxName);
  await Hive.openBox<Transaction>(transactionBoxName);
  await Hive.openBox<SalarySlip>(salarySlipBoxName);
  await Hive.openBox<Person>(personBoxName);
  await Hive.openBox<CompanyCar>(companyCarBoxName);
  await Hive.openBox<Budget>(budgetBoxName);
  await Hive.openBox(settingsBoxName);
  await Hive.openBox<Account>(accountBoxName);
  await Hive.openBox<Asset>(assetBoxName);
  await Hive.openBox<ImportBatch>(importBatchBoxName);
  await Hive.openBox<CustomImportProfile>(customImportProfileBoxName);

  if (categoryBox.isEmpty) {
    for (final category in buildDefaultCategories()) {
      await categoryBox.put(category.id, category);
    }
  } else {
    // Back-fill default categories added after initial release (e.g. the
    // system "Umbuchung" category, or new expense categories like "Bank &
    // Gebühren") onto installs seeded before they existed. Categories the
    // user already has (even if renamed/edited) are left untouched - this
    // only adds entries that are completely missing by id, never overwrites
    // existing ones, respecting that categories are freely user-editable.
    for (final category in buildDefaultCategories()) {
      if (!categoryBox.containsKey(category.id)) {
        await categoryBox.put(category.id, category);
      }
    }
  }
}
