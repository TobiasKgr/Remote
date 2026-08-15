import 'dart:io';

import 'package:finance_analyzer/models/account.dart';
import 'package:finance_analyzer/repositories/account_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<Account> box;
  late AccountRepository repository;
  var boxCounter = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('finance_analyzer_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(AccountAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(AccountTypeAdapter());
    box = await Hive.openBox<Account>('accounts_test_${boxCounter++}');
    repository = AccountRepository(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('save and getAll roundtrip', () async {
    await repository.save(Account(id: 'a', name: 'Girokonto', startingBalance: 250, colorValue: 0xFF2196F3));
    final all = repository.getAll();
    expect(all, hasLength(1));
    expect(all.first.name, 'Girokonto');
    expect(all.first.startingBalance, 250);
    expect(all.first.colorValue, 0xFF2196F3);
  });

  test('delete removes the account', () async {
    await repository.save(Account(id: 'a', name: 'Girokonto'));
    await repository.delete('a');
    expect(repository.getAll(), isEmpty);
  });

  test('personId round-trips through the Hive adapter', () async {
    await repository.save(Account(id: 'a', name: 'Sparkonto', personId: 'alice'));
    final saved = repository.getAll().single;
    expect(saved.personId, 'alice');
  });

  test('type round-trips through the Hive adapter, defaults to girokonto', () async {
    await repository.save(Account(id: 'a', name: 'Girokonto'));
    await repository.save(Account(id: 'b', name: 'Kreditkarte', type: AccountType.kreditkarte, startingBalance: -300));
    final byId = {for (final a in repository.getAll()) a.id: a};
    expect(byId['a']!.type, AccountType.girokonto);
    expect(byId['b']!.type, AccountType.kreditkarte);
    expect(byId['b']!.startingBalance, -300);
  });
}
