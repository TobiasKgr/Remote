import 'package:finance_analyzer/models/account.dart';
import 'package:finance_analyzer/models/asset.dart';
import 'package:finance_analyzer/models/budget.dart';
import 'package:finance_analyzer/models/category.dart';
import 'package:finance_analyzer/models/company_car.dart';
import 'package:finance_analyzer/models/person.dart';
import 'package:finance_analyzer/models/salary_slip.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = BackupService();

  final categories = [
    Category(
      id: 'fixkosten',
      name: 'Fixkosten & Abos',
      type: CategoryType.expense,
      colorValue: 0xFF123456,
      subcategories: [Subcategory(id: 'streaming', name: 'Streaming-Abos', keywords: ['netflix', 'spotify'])],
    ),
  ];
  final transactions = [
    Transaction(
      id: 't1',
      date: DateTime(2026, 7, 5),
      amount: -12.99,
      description: 'Netflix',
      categoryId: 'fixkosten',
      subcategoryId: 'streaming',
      isRecurring: true,
      personId: 'alice',
    ),
  ];
  final salarySlips = [
    SalarySlip(id: 's1', period: DateTime(2026, 7), gross: 4000, net: 2600, incomeTax: 800, socialSecurity: 600, personId: 'alice'),
  ];
  final persons = [Person(id: 'alice', name: 'Alice', colorValue: 0xFFAA0000)];
  final companyCars = [
    CompanyCar(id: 'car1', name: 'BMW 320d', personId: 'alice', monthlyBenefitInKind: 350, monthlyEmployeeContribution: 120, notes: 'Test'),
  ];
  final budgets = [
    Budget(id: Budget.overrideId('fixkosten', 2026, 12), categoryId: 'fixkosten', monthlyLimit: 200, year: 2026, month: 12),
  ];
  final accounts = [
    Account(id: 'acc1', name: 'Girokonto', startingBalance: 100, colorValue: 0xFF2196F3, personId: 'alice'),
  ];
  final assets = [
    Asset(id: 'asset1', name: 'ETF-Depot', category: AssetCategory.investment, value: 5000, personId: 'alice'),
  ];

  test('Export/Import-Roundtrip erhält alle Felder', () {
    final json = service.exportToJsonString(
      categories: categories,
      transactions: transactions,
      salarySlips: salarySlips,
      persons: persons,
      companyCars: companyCars,
      budgets: budgets,
      accounts: accounts,
      assets: assets,
    );

    final data = service.importFromJsonString(json);

    expect(data.categories, hasLength(1));
    expect(data.categories.first.id, 'fixkosten');
    expect(data.categories.first.subcategories.first.keywords, ['netflix', 'spotify']);

    expect(data.transactions, hasLength(1));
    expect(data.transactions.first.amount, -12.99);
    expect(data.transactions.first.date, DateTime(2026, 7, 5));
    expect(data.transactions.first.personId, 'alice');
    expect(data.transactions.first.isRecurring, isTrue);

    expect(data.salarySlips.first.gross, 4000);
    expect(data.salarySlips.first.period, DateTime(2026, 7));

    expect(data.persons.first.name, 'Alice');

    expect(data.companyCars.first.monthlyEmployeeContribution, 120);
    expect(data.companyCars.first.notes, 'Test');

    expect(data.budgets.first.monthlyLimit, 200);
    expect(data.budgets.first.year, 2026);
    expect(data.budgets.first.month, 12);
    expect(data.budgets.first.isOverride, isTrue);

    expect(data.accounts.first.name, 'Girokonto');
    expect(data.accounts.first.startingBalance, 100);
    expect(data.accounts.first.personId, 'alice');

    expect(data.assets.first.name, 'ETF-Depot');
    expect(data.assets.first.category, AssetCategory.investment);
    expect(data.assets.first.value, 5000);
    expect(data.assets.first.isLiability, isFalse);
  });

  test('leeres Dokument liefert leere Listen', () {
    final data = service.importFromJsonString('{"formatVersion": 1}');
    expect(data.categories, isEmpty);
    expect(data.transactions, isEmpty);
    expect(data.salarySlips, isEmpty);
    expect(data.persons, isEmpty);
    expect(data.companyCars, isEmpty);
    expect(data.budgets, isEmpty);
    expect(data.accounts, isEmpty);
    expect(data.assets, isEmpty);
  });

  test('wirft FormatException bei ungültigem JSON-Root', () {
    expect(() => service.importFromJsonString('[]'), throwsFormatException);
  });
}
