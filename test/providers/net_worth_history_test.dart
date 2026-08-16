import 'package:finance_analyzer/models/account.dart';
import 'package:finance_analyzer/models/asset.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/providers/net_worth_history_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final account = Account(id: 'a1', name: 'Giro', startingBalance: 1000);

  Transaction tx(String id, DateTime date, double amount, {String accountId = 'a1'}) {
    return Transaction(id: id, date: date, amount: amount, description: 'Test', categoryId: 'sonstiges', accountId: accountId);
  }

  test('kumuliert den Kontostand monatsweise aus Startsaldo + Buchungen bis zu diesem Monat', () {
    final transactions = [
      tx('t1', DateTime(2026, 1, 10), -100),
      tx('t2', DateTime(2026, 2, 5), 200),
      tx('t3', DateTime(2026, 3, 20), -50),
    ];

    final points = computeNetWorthHistory(
      accounts: [account],
      transactions: transactions,
      assets: const [],
      referenceDate: DateTime(2026, 3, 25),
    );

    expect(points, hasLength(3));
    expect(points[0].month, DateTime(2026, 1));
    expect(points[0].netWorth, closeTo(900, 0.001)); // 1000 - 100
    expect(points[1].month, DateTime(2026, 2));
    expect(points[1].netWorth, closeTo(1100, 0.001)); // 900 + 200
    expect(points[2].month, DateTime(2026, 3));
    expect(points[2].netWorth, closeTo(1050, 0.001)); // 1100 - 50
    expect(points.every((p) => p.hasData), isTrue);
  });

  test('ein Monat ohne Buchung wird als Lücke markiert, der Wert bleibt aber unverändert fortgeschrieben', () {
    final transactions = [
      tx('t1', DateTime(2026, 1, 10), -100),
      // Februar: keine Buchung.
      tx('t3', DateTime(2026, 3, 20), 50),
    ];

    final points = computeNetWorthHistory(
      accounts: [account],
      transactions: transactions,
      assets: const [],
      referenceDate: DateTime(2026, 3, 25),
    );

    expect(points, hasLength(3));
    expect(points[1].month, DateTime(2026, 2));
    expect(points[1].hasData, isFalse);
    expect(points[1].netWorth, closeTo(900, 0.001)); // unverändert von Januar
    expect(points[0].hasData, isTrue);
    expect(points[2].hasData, isTrue);
  });

  test('mehrere Konten werden pro Monat aufsummiert', () {
    final account2 = Account(id: 'a2', name: 'Tagesgeld', startingBalance: 500);
    final transactions = [
      tx('t1', DateTime(2026, 1, 10), -100, accountId: 'a1'),
      tx('t2', DateTime(2026, 1, 15), 300, accountId: 'a2'),
    ];

    final points = computeNetWorthHistory(
      accounts: [account, account2],
      transactions: transactions,
      assets: const [],
      referenceDate: DateTime(2026, 1, 20),
    );

    expect(points, hasLength(1));
    expect(points.single.netWorth, closeTo(900 + 800, 0.001)); // (1000-100) + (500+300)
  });

  test('statische Vermögenswerte/Kredite werden als konstanter Aufschlag über den ganzen Zeitraum addiert', () {
    final transactions = [tx('t1', DateTime(2026, 1, 10), 0)];
    final assets = [
      Asset(id: 'inv1', name: 'Depot', category: AssetCategory.investment, value: 5000),
      Asset(id: 'loan1', name: 'Kredit', category: AssetCategory.liability, value: 2000),
    ];

    final points = computeNetWorthHistory(
      accounts: [account],
      transactions: transactions,
      assets: assets,
      referenceDate: DateTime(2026, 1, 15),
    );

    expect(points.single.netWorth, closeTo(1000 + 5000 - 2000, 0.001));
  });

  test('ohne Konten liefert eine leere Liste', () {
    expect(computeNetWorthHistory(accounts: const [], transactions: const [], assets: const []), isEmpty);
  });

  test('Konten ganz ohne Buchungshistorie liefern eine leere Liste (kein Zeitraum bekannt)', () {
    expect(computeNetWorthHistory(accounts: [account], transactions: const [], assets: const []), isEmpty);
  });
}
