import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account.dart';
import '../models/asset.dart';
import 'account_providers.dart';
import 'person_providers.dart';
import 'repository_providers.dart';

class AssetNotifier extends Notifier<List<Asset>> {
  @override
  List<Asset> build() {
    final list = ref.watch(assetRepositoryProvider).getAll();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> upsert(Asset asset) async {
    await ref.read(assetRepositoryProvider).save(asset);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(assetRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final assetNotifierProvider = NotifierProvider<AssetNotifier, List<Asset>>(AssetNotifier.new);

/// Pure function: total net worth is every bank account's balance plus
/// every non-liability asset, minus every liability - independent of
/// Riverpod so it stays directly unit-testable.
double computeNetWorth({
  required List<Account> accounts,
  required Map<String, double> accountBalances,
  required List<Asset> assets,
}) {
  final accountsTotal = accounts.fold<double>(0, (s, a) => s + (accountBalances[a.id] ?? 0));
  final assetsTotal = assets.fold<double>(0, (s, a) => s + (a.isLiability ? -a.value : a.value));
  return accountsTotal + assetsTotal;
}

final netWorthProvider = Provider<double>((ref) {
  final personFilter = ref.watch(selectedPersonFilterProvider);
  final accounts = filterByPerson(ref.watch(accountNotifierProvider), personFilter, (a) => a.personId).toList();
  final assets = filterByPerson(ref.watch(assetNotifierProvider), personFilter, (a) => a.personId).toList();
  return computeNetWorth(accounts: accounts, accountBalances: ref.watch(accountBalancesProvider), assets: assets);
});
