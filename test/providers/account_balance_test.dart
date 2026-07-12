import 'package:finance_analyzer/models/account.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/providers/account_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final girokonto = Account(id: 'giro', name: 'Girokonto', startingBalance: 100);
  final sparkonto = Account(id: 'spar', name: 'Sparkonto', startingBalance: 500);

  test('computeAccountBalance addiert Buchungen auf den Startsaldo', () {
    final transactions = [
      Transaction(id: 't1', date: DateTime(2026, 7, 1), amount: -20, description: 'Einkauf', categoryId: 'sonstiges', accountId: 'giro'),
      Transaction(id: 't2', date: DateTime(2026, 7, 2), amount: 500, description: 'Gehalt', categoryId: 'gehalt', accountId: 'giro'),
    ];
    expect(computeAccountBalance(girokonto, transactions), 580);
  });

  test('computeAccountBalance ignoriert Buchungen anderer Konten', () {
    final transactions = [
      Transaction(id: 't1', date: DateTime(2026, 7, 1), amount: -20, description: 'Einkauf', categoryId: 'sonstiges', accountId: 'spar'),
    ];
    expect(computeAccountBalance(girokonto, transactions), 100);
  });

  test('Umbuchung wirkt sich gegenläufig auf beide Konten aus, ohne den Gesamtsaldo zu verändern', () {
    final transactions = [
      Transaction(
        id: 'out',
        date: DateTime(2026, 7, 3),
        amount: -150,
        description: 'Umbuchung zu Sparkonto',
        categoryId: 'umbuchung',
        accountId: 'giro',
        isTransfer: true,
        transferGroupId: 'g1',
      ),
      Transaction(
        id: 'in',
        date: DateTime(2026, 7, 3),
        amount: 150,
        description: 'Umbuchung von Girokonto',
        categoryId: 'umbuchung',
        accountId: 'spar',
        isTransfer: true,
        transferGroupId: 'g1',
      ),
    ];
    final balances = computeAccountBalances([girokonto, sparkonto], transactions);
    expect(balances['giro'], -50);
    expect(balances['spar'], 650);
    expect(balances.values.reduce((a, b) => a + b), 600);
  });
}
