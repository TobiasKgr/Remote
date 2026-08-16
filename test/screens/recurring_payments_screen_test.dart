import 'package:finance_analyzer/models/person.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/providers/person_providers.dart';
import 'package:finance_analyzer/providers/transaction_providers.dart';
import 'package:finance_analyzer/screens/recurring_payments_screen.dart';
import 'package:finance_analyzer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FixedTransactionNotifier extends TransactionNotifier {
  _FixedTransactionNotifier(this._data);
  final List<Transaction> _data;
  @override
  List<Transaction> build() => _data;
}

class _EmptyPersonNotifier extends PersonNotifier {
  @override
  List<Person> build() => [];
}

void main() {
  setUpAll(() => initializeDateFormatting('de_DE'));

  testWidgets('Abos & Verträge rendert eine erkannte Serie ohne Exception', (tester) async {
    final transactions = [
      Transaction(id: 't1', date: DateTime(2026, 1, 15), amount: -12.99, description: 'Netflix.com', categoryId: 'fixkosten', subcategoryId: 'fixkosten_streaming'),
      Transaction(id: 't2', date: DateTime(2026, 2, 15), amount: -12.99, description: 'Netflix.com', categoryId: 'fixkosten', subcategoryId: 'fixkosten_streaming'),
      Transaction(id: 't3', date: DateTime(2026, 3, 15), amount: -12.99, description: 'Netflix.com', categoryId: 'fixkosten', subcategoryId: 'fixkosten_streaming'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionNotifierProvider.overrideWith(() => _FixedTransactionNotifier(transactions)),
          personNotifierProvider.overrideWith(_EmptyPersonNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const RecurringPaymentsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Abos & Verträge'), findsOneWidget);
    expect(find.textContaining('Netflix'), findsOneWidget);
    expect(find.textContaining('Monatlich ·'), findsOneWidget);
  });

  testWidgets('leerer Zustand rendert ohne Exception', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionNotifierProvider.overrideWith(() => _FixedTransactionNotifier(const [])),
          personNotifierProvider.overrideWith(_EmptyPersonNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const RecurringPaymentsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Noch keine wiederkehrenden Zahlungen'), findsOneWidget);
  });
}
