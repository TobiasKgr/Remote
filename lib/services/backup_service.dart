import 'dart:convert';

import '../models/account.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/company_car.dart';
import '../models/person.dart';
import '../models/salary_slip.dart';
import '../models/transaction.dart';

/// Everything restored from a backup file, ready to be written into the
/// respective repositories.
class BackupData {
  const BackupData({
    required this.categories,
    required this.transactions,
    required this.salarySlips,
    required this.persons,
    required this.companyCars,
    required this.budgets,
    required this.accounts,
  });

  final List<Category> categories;
  final List<Transaction> transactions;
  final List<SalarySlip> salarySlips;
  final List<Person> persons;
  final List<CompanyCar> companyCars;
  final List<Budget> budgets;
  final List<Account> accounts;
}

/// Exports/imports all locally stored data as a single human-readable JSON
/// document, independent of Hive's binary on-disk format. Used for manual
/// backups and moving data between installations.
class BackupService {
  static const formatVersion = 1;

  String exportToJsonString({
    required List<Category> categories,
    required List<Transaction> transactions,
    required List<SalarySlip> salarySlips,
    required List<Person> persons,
    required List<CompanyCar> companyCars,
    required List<Budget> budgets,
    required List<Account> accounts,
  }) {
    final document = {
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'salarySlips': salarySlips.map((s) => s.toJson()).toList(),
      'persons': persons.map((p) => p.toJson()).toList(),
      'companyCars': companyCars.map((c) => c.toJson()).toList(),
      'budgets': budgets.map((b) => b.toJson()).toList(),
      'accounts': accounts.map((a) => a.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(document);
  }

  BackupData importFromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map) {
      throw const FormatException('Ungültiges Backup-Format: Die Datei enthält kein JSON-Objekt.');
    }
    final document = Map<String, dynamic>.from(decoded);

    List<T> parseList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final raw = document[key];
      if (raw is! List) return <T>[];
      return raw.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }

    return BackupData(
      categories: parseList('categories', Category.fromJson),
      transactions: parseList('transactions', Transaction.fromJson),
      salarySlips: parseList('salarySlips', SalarySlip.fromJson),
      persons: parseList('persons', Person.fromJson),
      companyCars: parseList('companyCars', CompanyCar.fromJson),
      budgets: parseList('budgets', Budget.fromJson),
      accounts: parseList('accounts', Account.fromJson),
    );
  }
}
