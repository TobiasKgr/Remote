import 'package:finance_analyzer/models/account.dart';
import 'package:finance_analyzer/models/category.dart';
import 'package:finance_analyzer/models/person.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/providers/account_providers.dart';
import 'package:finance_analyzer/providers/category_providers.dart';
import 'package:finance_analyzer/providers/person_providers.dart';
import 'package:finance_analyzer/providers/transaction_providers.dart';
import 'package:finance_analyzer/screens/quick_entry_screen.dart';
import 'package:finance_analyzer/screens/transaction_form_screen.dart';
import 'package:finance_analyzer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FixedCategoryNotifier extends CategoryNotifier {
  _FixedCategoryNotifier(this._data);
  final List<Category> _data;
  @override
  List<Category> build() => _data;
}

class _FixedTransactionNotifier extends TransactionNotifier {
  _FixedTransactionNotifier(this._data);
  final List<Transaction> _data;
  @override
  List<Transaction> build() => _data;
}

class _EmptyAccountNotifier extends AccountNotifier {
  @override
  List<Account> build() => [];
}

class _EmptyPersonNotifier extends PersonNotifier {
  @override
  List<Person> build() => [];
}

void main() {
  setUpAll(() => initializeDateFormatting('de_DE'));

  final categories = [
    Category(id: 'lebensmittel', name: 'Lebensmittel', type: CategoryType.expense, colorValue: 0xFF000000),
  ];

  Widget buildApp() => ProviderScope(
        overrides: [
          categoryNotifierProvider.overrideWith(() => _FixedCategoryNotifier(categories)),
          transactionNotifierProvider.overrideWith(() => _FixedTransactionNotifier(const [])),
          accountNotifierProvider.overrideWith(_EmptyAccountNotifier.new),
          personNotifierProvider.overrideWith(_EmptyPersonNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const QuickEntryScreen()),
      );

  testWidgets('zeigt eine Vorschau, sobald ein Betrag erkannt wurde', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextField), '50€ Rewe gestern');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Rewe'), findsOneWidget);
    expect(find.text('Weiter'), findsOneWidget);
  });

  testWidgets('ohne erkennbaren Betrag bleibt "Weiter" deaktiviert und ein Hinweis erscheint', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextField), 'Rewe gestern');
    await tester.pumpAndSettle();

    expect(find.textContaining('Betrag nicht erkannt'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('Weiter öffnet das Buchungsformular mit vorausgefüllten Werten', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextField), '12,99 Netflix vorgestern');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TransactionFormScreen), findsOneWidget);
    expect(find.text('Netflix'), findsWidgets);
    expect(find.text('12.99'), findsOneWidget);
  });
}
