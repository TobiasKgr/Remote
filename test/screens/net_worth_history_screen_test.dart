import 'package:finance_analyzer/models/account.dart';
import 'package:finance_analyzer/models/asset.dart';
import 'package:finance_analyzer/models/person.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/providers/account_providers.dart';
import 'package:finance_analyzer/providers/asset_providers.dart';
import 'package:finance_analyzer/providers/person_providers.dart';
import 'package:finance_analyzer/providers/transaction_providers.dart';
import 'package:finance_analyzer/screens/net_worth_history_screen.dart';
import 'package:finance_analyzer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedAccountNotifier extends AccountNotifier {
  _FixedAccountNotifier(this._data);
  final List<Account> _data;
  @override
  List<Account> build() => _data;
}

class _FixedTransactionNotifier extends TransactionNotifier {
  _FixedTransactionNotifier(this._data);
  final List<Transaction> _data;
  @override
  List<Transaction> build() => _data;
}

class _FixedAssetNotifier extends AssetNotifier {
  _FixedAssetNotifier(this._data);
  final List<Asset> _data;
  @override
  List<Asset> build() => _data;
}

class _EmptyPersonNotifier extends PersonNotifier {
  @override
  List<Person> build() => [];
}

void main() {
  testWidgets('Vermögensentwicklung rendert den Chart mit echten Daten ohne Exception', (tester) async {
    final account = Account(id: 'a1', name: 'Giro', startingBalance: 1000);
    final transactions = [
      Transaction(id: 't1', date: DateTime(2026, 1, 10), amount: -100, description: 'Miete', categoryId: 'wohnen', accountId: 'a1'),
      Transaction(id: 't2', date: DateTime(2026, 3, 5), amount: 500, description: 'Gehalt', categoryId: 'income', accountId: 'a1'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountNotifierProvider.overrideWith(() => _FixedAccountNotifier([account])),
          transactionNotifierProvider.overrideWith(() => _FixedTransactionNotifier(transactions)),
          assetNotifierProvider.overrideWith(() => _FixedAssetNotifier(const [])),
          personNotifierProvider.overrideWith(_EmptyPersonNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const NetWorthHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Vermögensentwicklung'), findsOneWidget);
  });

  testWidgets('leerer Zustand (keine Konten) rendert ohne Exception', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountNotifierProvider.overrideWith(() => _FixedAccountNotifier(const [])),
          transactionNotifierProvider.overrideWith(() => _FixedTransactionNotifier(const [])),
          assetNotifierProvider.overrideWith(() => _FixedAssetNotifier(const [])),
          personNotifierProvider.overrideWith(_EmptyPersonNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const NetWorthHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Noch nicht genug Buchungsverlauf'), findsOneWidget);
  });
}
