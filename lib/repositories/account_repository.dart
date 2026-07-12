import 'package:hive/hive.dart';

import '../models/account.dart';

class AccountRepository {
  AccountRepository(this._box);

  final Box<Account> _box;

  List<Account> getAll() => _box.values.toList(growable: false);

  Future<void> save(Account account) => _box.put(account.id, account);

  Future<void> delete(String id) => _box.delete(id);
}
