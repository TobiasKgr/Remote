import 'package:finance_analyzer/models/category.dart';
import 'package:finance_analyzer/models/person.dart';
import 'package:finance_analyzer/models/salary_slip.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/providers/category_providers.dart';
import 'package:finance_analyzer/providers/person_providers.dart';
import 'package:finance_analyzer/providers/salary_slip_providers.dart';
import 'package:finance_analyzer/providers/transaction_providers.dart';
import 'package:finance_analyzer/screens/salary_slip_form_screen.dart';
import 'package:finance_analyzer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FixedTransactionNotifier extends TransactionNotifier {
  _FixedTransactionNotifier(this._data);
  final List<Transaction> _data;
  final List<Transaction> upserted = [];

  @override
  List<Transaction> build() => _data;

  @override
  Future<void> upsert(Transaction transaction) async {
    upserted.add(transaction);
  }
}

class _FixedSalarySlipNotifier extends SalarySlipNotifier {
  final List<SalarySlip> upserted = [];

  @override
  List<SalarySlip> build() => const [];

  @override
  Future<void> upsert(SalarySlip slip) async {
    upserted.add(slip);
  }
}

class _EmptyPersonNotifier extends PersonNotifier {
  @override
  List<Person> build() => [];
}

class _FixedCategoryNotifier extends CategoryNotifier {
  @override
  List<Category> build() => [
        Category(id: 'income', name: 'Einkommen', type: CategoryType.income, colorValue: 0xFF00FF00),
      ];
}

void main() {
  setUpAll(() => initializeDateFormatting('de_DE'));

  Widget buildApp({required _FixedTransactionNotifier txNotifier, required _FixedSalarySlipNotifier slipNotifier}) {
    return ProviderScope(
      overrides: [
        transactionNotifierProvider.overrideWith(() => txNotifier),
        salarySlipNotifierProvider.overrideWith(() => slipNotifier),
        personNotifierProvider.overrideWith(_EmptyPersonNotifier.new),
        categoryNotifierProvider.overrideWith(_FixedCategoryNotifier.new),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const SalarySlipFormScreen()),
    );
  }

  testWidgets('ohne bestehende ähnliche Einnahme wird direkt gespeichert, ohne Rückfrage', (tester) async {
    final txNotifier = _FixedTransactionNotifier(const []);
    final slipNotifier = _FixedSalarySlipNotifier();
    await tester.pumpWidget(buildApp(txNotifier: txNotifier, slipNotifier: slipNotifier));

    await tester.enterText(find.widgetWithText(TextFormField, 'Brutto (€)'), '3000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Netto / Auszahlungsbetrag (€)'), '2000');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sichern'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(txNotifier.upserted, hasLength(1));
    expect(slipNotifier.upserted, hasLength(1));
  });

  testWidgets('bei ähnlicher bestehender Einnahme erscheint eine Rückfrage - "Nicht übernehmen" verhindert die Buchung', (tester) async {
    final now = DateTime.now();
    final existingIncome = Transaction(
      id: 'existing1',
      date: DateTime(now.year, now.month, 15),
      amount: 2000,
      description: 'GEHALT MUSTER GMBH',
      categoryId: 'income',
    );
    final txNotifier = _FixedTransactionNotifier([existingIncome]);
    final slipNotifier = _FixedSalarySlipNotifier();
    await tester.pumpWidget(buildApp(txNotifier: txNotifier, slipNotifier: slipNotifier));

    await tester.enterText(find.widgetWithText(TextFormField, 'Brutto (€)'), '3000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Netto / Auszahlungsbetrag (€)'), '2000');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sichern'));
    await tester.pumpAndSettle();

    expect(find.text('Mögliches Duplikat'), findsOneWidget);

    await tester.tap(find.text('Nicht übernehmen'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(txNotifier.upserted, isEmpty);
    expect(slipNotifier.upserted, hasLength(1));
    expect(slipNotifier.upserted.single.linkedTransactionId, isNull);
  });

  testWidgets('bei ähnlicher bestehender Einnahme "Übernehmen" legt trotzdem eine Buchung an', (tester) async {
    final now = DateTime.now();
    final existingIncome = Transaction(
      id: 'existing1',
      date: DateTime(now.year, now.month, 15),
      amount: 2000,
      description: 'GEHALT MUSTER GMBH',
      categoryId: 'income',
    );
    final txNotifier = _FixedTransactionNotifier([existingIncome]);
    final slipNotifier = _FixedSalarySlipNotifier();
    await tester.pumpWidget(buildApp(txNotifier: txNotifier, slipNotifier: slipNotifier));

    await tester.enterText(find.widgetWithText(TextFormField, 'Brutto (€)'), '3000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Netto / Auszahlungsbetrag (€)'), '2000');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sichern'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Übernehmen'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(txNotifier.upserted, hasLength(1));
    expect(slipNotifier.upserted.single.linkedTransactionId, isNotNull);
  });
}
