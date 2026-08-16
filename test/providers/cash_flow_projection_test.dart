import 'package:finance_analyzer/models/account.dart';
import 'package:finance_analyzer/models/asset.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/providers/account_providers.dart';
import 'package:finance_analyzer/providers/asset_providers.dart';
import 'package:finance_analyzer/providers/cash_flow_projection_providers.dart';
import 'package:finance_analyzer/providers/transaction_providers.dart';
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

void main() {
  test('projiziert vom aktuellen Gesamtsaldo (Konten + statische Assets) ausgehend', () {
    final account = Account(id: 'a1', name: 'Giro', startingBalance: 1000);
    final now = DateTime.now();
    DateTime monthsAgo(int n) => DateTime(now.year, now.month - n, 5);
    final transactions = [
      for (var i = 2; i >= 0; i--)
        Transaction(id: 'sub$i', date: monthsAgo(i), amount: -12.99, description: 'Netflix.com', categoryId: 'fixkosten', accountId: 'a1'),
    ];

    final container = ProviderContainer(
      overrides: [
        accountNotifierProvider.overrideWith(() => _FixedAccountNotifier([account])),
        transactionNotifierProvider.overrideWith(() => _FixedTransactionNotifier(transactions)),
        assetNotifierProvider.overrideWith(() => _FixedAssetNotifier(const [])),
      ],
    );
    addTearDown(container.dispose);

    final projection = container.read(cashFlowProjectionProvider);
    final currentBalance = 1000 - 12.99 * transactions.length;

    expect(projection.first.balance, closeTo(currentBalance, 0.01));
    expect(projection.length, greaterThan(1)); // mindestens eine weitere Netflix-Abbuchung liegt in den nächsten 8 Wochen
    expect(projection.last.balance, lessThan(projection.first.balance));
    // Jede projizierte Abbuchung ist genau die erkannte Netflix-Rate.
    for (var i = 1; i < projection.length; i++) {
      expect(projection[i].balance, closeTo(projection[i - 1].balance - 12.99, 0.01));
    }
  });

  test('ohne wiederkehrende Zahlungen enthält die Prognose nur den aktuellen Stand', () {
    final account = Account(id: 'a1', name: 'Giro', startingBalance: 500);

    final container = ProviderContainer(
      overrides: [
        accountNotifierProvider.overrideWith(() => _FixedAccountNotifier([account])),
        transactionNotifierProvider.overrideWith(() => _FixedTransactionNotifier(const [])),
        assetNotifierProvider.overrideWith(() => _FixedAssetNotifier(const [])),
      ],
    );
    addTearDown(container.dispose);

    final projection = container.read(cashFlowProjectionProvider);
    expect(projection, hasLength(1));
    expect(projection.first.balance, 500);
  });
}
