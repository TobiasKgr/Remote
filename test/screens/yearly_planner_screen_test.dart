import 'package:finance_analyzer/data/default_categories.dart';
import 'package:finance_analyzer/models/category.dart';
import 'package:finance_analyzer/models/person.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/providers/category_providers.dart';
import 'package:finance_analyzer/providers/person_providers.dart';
import 'package:finance_analyzer/providers/transaction_providers.dart';
import 'package:finance_analyzer/screens/yearly_planner_screen.dart';
import 'package:finance_analyzer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedTransactionNotifier extends TransactionNotifier {
  _FixedTransactionNotifier(this._data);
  final List<Transaction> _data;
  @override
  List<Transaction> build() => _data;
}

class _FixedCategoryNotifier extends CategoryNotifier {
  _FixedCategoryNotifier(this._data);
  final List<Category> _data;
  @override
  List<Category> build() => _data;
}

class _EmptyPersonNotifier extends PersonNotifier {
  @override
  List<Person> build() => [];
}

void main() {
  testWidgets('Jahresplaner rendert eine gefüllte Tabelle (mehrere Kategorien) ohne Exception', (tester) async {
    // Regression test für einen Absturz: die Kategorie-Titelzeile der Tabelle
    // hatte eine Spalte zu wenig ("Table contains irregular row lengths"),
    // was erst auffiel, sobald wirklich Buchungen mit Kategorien vorhanden
    // waren - mit leeren Daten (nur der "Keine Buchungen"-Text) trat der
    // Fehler nie auf.
    final categories = buildDefaultCategories();
    final transactions = [
      Transaction(id: 't1', date: DateTime(2026, 1, 1), amount: 3000, description: 'Gehalt Januar', categoryId: 'income', subcategoryId: 'income_gehalt'),
      Transaction(id: 't2', date: DateTime(2026, 1, 1), amount: -750, description: 'Miete', categoryId: 'wohnen', subcategoryId: 'wohnen_miete'),
      Transaction(id: 't3', date: DateTime(2026, 1, 5), amount: -50, description: 'Rewe', categoryId: 'lebensmittel', subcategoryId: 'lebensmittel_supermarkt'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionNotifierProvider.overrideWith(() => _FixedTransactionNotifier(transactions)),
          categoryNotifierProvider.overrideWith(() => _FixedCategoryNotifier(categories)),
          personNotifierProvider.overrideWith(_EmptyPersonNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const YearlyPlannerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Jahresplaner'), findsOneWidget);
    expect(find.text('Miete'), findsOneWidget);
  });

  testWidgets('zeigt bei einer erkannten wiederkehrenden Zahlung eine Prognose-Legende', (tester) async {
    final categories = buildDefaultCategories();
    final now = DateTime.now();
    DateTime monthsAgo(int n) => DateTime(now.year, now.month - n, 1);
    final transactions = [
      for (var i = 3; i >= 1; i--)
        Transaction(id: 'miete_$i', date: monthsAgo(i), amount: -750, description: 'Miete', categoryId: 'wohnen', subcategoryId: 'wohnen_miete'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionNotifierProvider.overrideWith(() => _FixedTransactionNotifier(transactions)),
          categoryNotifierProvider.overrideWith(() => _FixedCategoryNotifier(categories)),
          personNotifierProvider.overrideWith(_EmptyPersonNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const YearlyPlannerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Kursiv = Prognose'), findsOneWidget);
  });
}
