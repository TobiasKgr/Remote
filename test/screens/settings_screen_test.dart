import 'dart:io';

import 'package:finance_analyzer/models/account.dart';
import 'package:finance_analyzer/models/asset.dart';
import 'package:finance_analyzer/models/budget.dart';
import 'package:finance_analyzer/models/category.dart';
import 'package:finance_analyzer/models/company_car.dart';
import 'package:finance_analyzer/models/import_batch.dart';
import 'package:finance_analyzer/models/person.dart';
import 'package:finance_analyzer/models/salary_slip.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/providers/repository_providers.dart';
import 'package:finance_analyzer/providers/settings_providers.dart';
import 'package:finance_analyzer/screens/settings_screen.dart';
import 'package:finance_analyzer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _FixedNotificationsNotifier extends NotificationsEnabledNotifier {
  @override
  bool build() => false;
}

void main() {
  late Directory tempDir;
  late Box<Category> categoryBox;
  late Box<Transaction> transactionBox;
  late Box<Person> personBox;
  late Box<Account> accountBox;
  late Box<Asset> assetBox;
  late Box<CompanyCar> companyCarBox;
  late Box<SalarySlip> salarySlipBox;
  late Box<Budget> budgetBox;
  late Box<ImportBatch> importBatchBox;
  var boxCounter = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('finance_analyzer_test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SubcategoryAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(CategoryTypeAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(TransactionSourceAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(SalarySlipAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(PersonAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(CompanyCarAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(BudgetAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(AccountAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(AccountTypeAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(AssetAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(AssetCategoryAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(ImportBatchAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(ImportSourceAdapter());

    final suffix = boxCounter++;
    categoryBox = await Hive.openBox<Category>('category_test_$suffix');
    transactionBox = await Hive.openBox<Transaction>('transaction_test_$suffix');
    personBox = await Hive.openBox<Person>('person_test_$suffix');
    accountBox = await Hive.openBox<Account>('account_test_$suffix');
    assetBox = await Hive.openBox<Asset>('asset_test_$suffix');
    companyCarBox = await Hive.openBox<CompanyCar>('companycar_test_$suffix');
    salarySlipBox = await Hive.openBox<SalarySlip>('salaryslip_test_$suffix');
    budgetBox = await Hive.openBox<Budget>('budget_test_$suffix');
    importBatchBox = await Hive.openBox<ImportBatch>('importbatch_test_$suffix');

    // Seed a bit of data in every box so the reset has something to delete.
    await categoryBox.put('cat1', Category(id: 'cat1', name: 'Eigene Kategorie', type: CategoryType.expense, colorValue: 0xFF000000));
    await transactionBox.put('t1', Transaction(id: 't1', date: DateTime(2026, 1, 1), amount: -50, description: 'Test', categoryId: 'cat1'));
    await personBox.put('p1', Person(id: 'p1', name: 'Alice', colorValue: 0xFF0000FF));
    await accountBox.put('a1', Account(id: 'a1', name: 'Giro', startingBalance: 100));
    await assetBox.put('as1', Asset(id: 'as1', name: 'Auto', value: 5000, category: AssetCategory.other));
    await companyCarBox.put('c1', CompanyCar(id: 'c1', name: 'Dienstwagen'));
    await salarySlipBox.put('s1', SalarySlip(id: 's1', period: DateTime(2026, 1), gross: 3000, net: 2000, incomeTax: 500, socialSecurity: 500));
    await budgetBox.put('b1', Budget(id: 'b1', categoryId: 'cat1', monthlyLimit: 200));
    await importBatchBox.put('ib1', ImportBatch(id: 'ib1', timestamp: DateTime(2026, 1, 1), source: ImportSource.kontoauszug, label: '1 Buchung'));
  });

  tearDown(() async {
    for (final box in [categoryBox, transactionBox, personBox, accountBox, assetBox, companyCarBox, salarySlipBox, budgetBox, importBatchBox]) {
      await box.deleteFromDisk();
    }
    await tempDir.delete(recursive: true);
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        categoryBoxProvider.overrideWithValue(categoryBox),
        transactionBoxProvider.overrideWithValue(transactionBox),
        personBoxProvider.overrideWithValue(personBox),
        accountBoxProvider.overrideWithValue(accountBox),
        assetBoxProvider.overrideWithValue(assetBox),
        companyCarBoxProvider.overrideWithValue(companyCarBox),
        salarySlipBoxProvider.overrideWithValue(salarySlipBox),
        budgetBoxProvider.overrideWithValue(budgetBox),
        importBatchBoxProvider.overrideWithValue(importBatchBox),
        notificationsEnabledProvider.overrideWith(_FixedNotificationsNotifier.new),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const SettingsScreen()),
    );
  }

  testWidgets('Abbrechen bei der ersten Sicherheitsabfrage löscht nichts', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alle Daten zurücksetzen'));
    await tester.pumpAndSettle();
    expect(find.text('Alle Daten zurücksetzen?'), findsOneWidget);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(transactionBox.isNotEmpty, isTrue);
    expect(categoryBox.get('cat1'), isNotNull);
  });

  testWidgets('Abbrechen bei der Export-Abfrage löscht nichts', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alle Daten zurücksetzen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Daten vorher exportieren?'), findsOneWidget);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(transactionBox.isNotEmpty, isTrue);
  });

  testWidgets('"Ohne Export löschen" leert alle Boxen und setzt Kategorien auf Standard zurück', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alle Daten zurücksetzen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    // The reset handler awaits real Hive disk I/O (this test uses real boxes
    // on a temp dir, not fakes). Widget test bodies run inside a FakeAsync
    // zone by default, where real (non-Timer-based) I/O futures never
    // resolve - so the tap and the follow-up pumps must run inside
    // tester.runAsync() to let that I/O actually complete. Not
    // pumpAndSettle: while the reset is in progress, the screen shows an
    // indeterminate CircularProgressIndicator, whose repeating animation
    // means pumpAndSettle's "no more frames pending" check never succeeds -
    // a handful of fixed pumps gives the reset time to finish and flip back
    // to its non-busy state instead.
    await tester.runAsync(() async {
      await tester.tap(find.text('Ohne Export löschen'));
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    });

    expect(tester.takeException(), isNull);
    expect(transactionBox.isEmpty, isTrue);
    expect(personBox.isEmpty, isTrue);
    expect(accountBox.isEmpty, isTrue);
    expect(assetBox.isEmpty, isTrue);
    expect(companyCarBox.isEmpty, isTrue);
    expect(salarySlipBox.isEmpty, isTrue);
    expect(budgetBox.isEmpty, isTrue);
    expect(importBatchBox.isEmpty, isTrue);

    // Eigene Kategorie ist weg, Standard-Kategorien wurden neu angelegt.
    expect(categoryBox.get('cat1'), isNull);
    expect(categoryBox.isNotEmpty, isTrue);

    expect(find.text('Alle Daten wurden zurückgesetzt.'), findsOneWidget);
  });
}
