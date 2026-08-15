import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../data/hive_setup.dart';
import '../models/account.dart';
import '../models/asset.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/company_car.dart';
import '../models/import_batch.dart';
import '../models/person.dart';
import '../models/salary_slip.dart';
import '../models/transaction.dart';
import '../repositories/account_repository.dart';
import '../repositories/asset_repository.dart';
import '../repositories/budget_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/company_car_repository.dart';
import '../repositories/import_batch_repository.dart';
import '../repositories/person_repository.dart';
import '../repositories/salary_slip_repository.dart';
import '../repositories/transaction_repository.dart';

/// Boxes are opened once in `main()` before `runApp`, so accessing them here
/// via `Hive.box` (sync) is safe.
final categoryBoxProvider = Provider<Box<Category>>((ref) => Hive.box<Category>(categoryBoxName));

final transactionBoxProvider = Provider<Box<Transaction>>((ref) => Hive.box<Transaction>(transactionBoxName));

final salarySlipBoxProvider = Provider<Box<SalarySlip>>((ref) => Hive.box<SalarySlip>(salarySlipBoxName));

final personBoxProvider = Provider<Box<Person>>((ref) => Hive.box<Person>(personBoxName));

final companyCarBoxProvider = Provider<Box<CompanyCar>>((ref) => Hive.box<CompanyCar>(companyCarBoxName));

final budgetBoxProvider = Provider<Box<Budget>>((ref) => Hive.box<Budget>(budgetBoxName));

final accountBoxProvider = Provider<Box<Account>>((ref) => Hive.box<Account>(accountBoxName));

final assetBoxProvider = Provider<Box<Asset>>((ref) => Hive.box<Asset>(assetBoxName));

final importBatchBoxProvider = Provider<Box<ImportBatch>>((ref) => Hive.box<ImportBatch>(importBatchBoxName));

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(categoryBoxProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(transactionBoxProvider));
});

final salarySlipRepositoryProvider = Provider<SalarySlipRepository>((ref) {
  return SalarySlipRepository(ref.watch(salarySlipBoxProvider));
});

final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return PersonRepository(ref.watch(personBoxProvider));
});

final companyCarRepositoryProvider = Provider<CompanyCarRepository>((ref) {
  return CompanyCarRepository(ref.watch(companyCarBoxProvider));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(budgetBoxProvider));
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(accountBoxProvider));
});

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(ref.watch(assetBoxProvider));
});

final importBatchRepositoryProvider = Provider<ImportBatchRepository>((ref) {
  return ImportBatchRepository(ref.watch(importBatchBoxProvider));
});
