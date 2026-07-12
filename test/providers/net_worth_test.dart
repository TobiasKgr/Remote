import 'package:finance_analyzer/models/account.dart';
import 'package:finance_analyzer/models/asset.dart';
import 'package:finance_analyzer/providers/asset_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final girokonto = Account(id: 'giro', name: 'Girokonto', startingBalance: 100);
  final sparkonto = Account(id: 'spar', name: 'Sparkonto', startingBalance: 500);

  test('computeNetWorth summiert Kontostände und Vermögenswerte', () {
    final netWorth = computeNetWorth(
      accounts: [girokonto, sparkonto],
      accountBalances: {'giro': 100, 'spar': 500},
      assets: [Asset(id: 'a1', name: 'ETF-Depot', category: AssetCategory.investment, value: 5000)],
    );
    expect(netWorth, 5600);
  });

  test('computeNetWorth zieht Kredite/Schulden ab', () {
    final netWorth = computeNetWorth(
      accounts: [girokonto],
      accountBalances: {'giro': 100},
      assets: [Asset(id: 'a1', name: 'Hypothek', category: AssetCategory.liability, value: 150000)],
    );
    expect(netWorth, -149900);
  });

  test('computeNetWorth ohne Konten und Vermögenswerte ist 0', () {
    final netWorth = computeNetWorth(accounts: [], accountBalances: {}, assets: []);
    expect(netWorth, 0);
  });
}
