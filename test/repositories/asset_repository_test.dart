import 'dart:io';

import 'package:finance_analyzer/models/asset.dart';
import 'package:finance_analyzer/repositories/asset_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<Asset> box;
  late AssetRepository repository;
  var boxCounter = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('finance_analyzer_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(AssetAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(AssetCategoryAdapter());
    box = await Hive.openBox<Asset>('assets_test_${boxCounter++}');
    repository = AssetRepository(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('save and getAll roundtrip', () async {
    await repository.save(Asset(id: 'a', name: 'ETF-Depot', category: AssetCategory.investment, value: 5000));
    final all = repository.getAll();
    expect(all, hasLength(1));
    expect(all.first.name, 'ETF-Depot');
    expect(all.first.category, AssetCategory.investment);
    expect(all.first.value, 5000);
  });

  test('delete removes the asset', () async {
    await repository.save(Asset(id: 'a', name: 'ETF-Depot', category: AssetCategory.investment));
    await repository.delete('a');
    expect(repository.getAll(), isEmpty);
  });

  test('liability round-trips through the Hive adapter', () async {
    await repository.save(Asset(id: 'a', name: 'Hypothek', category: AssetCategory.liability, value: 150000, personId: 'alice', notes: 'Haus'));
    final saved = repository.getAll().single;
    expect(saved.isLiability, isTrue);
    expect(saved.personId, 'alice');
    expect(saved.notes, 'Haus');
  });
}
