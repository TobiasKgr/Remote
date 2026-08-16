import 'dart:io';

import 'package:finance_analyzer/models/custom_import_profile.dart';
import 'package:finance_analyzer/repositories/custom_import_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<CustomImportProfile> box;
  late CustomImportProfileRepository repository;
  var boxCounter = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('finance_analyzer_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(CustomImportProfileAdapter());
    box = await Hive.openBox<CustomImportProfile>('custom_import_profiles_test_${boxCounter++}');
    repository = CustomImportProfileRepository(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  CustomImportProfile makeProfile(String id) {
    return CustomImportProfile(
      id: id,
      name: 'Meine Bank $id',
      dateFormat: ImportDateFormat.ddMMyy,
      amountPosition: ImportAmountPosition.afterDate,
      decimalSeparator: ImportDecimalSeparator.dot,
      createdAt: DateTime(2026, 3, 1),
    );
  }

  test('save and getAll roundtrip, inklusive aller Format-Einstellungen', () async {
    await repository.save(makeProfile('a'));
    final all = repository.getAll();
    expect(all, hasLength(1));
    expect(all.single.name, 'Meine Bank a');
    expect(all.single.dateFormat, ImportDateFormat.ddMMyy);
    expect(all.single.amountPosition, ImportAmountPosition.afterDate);
    expect(all.single.decimalSeparator, ImportDecimalSeparator.dot);
  });

  test('delete removes the profile', () async {
    await repository.save(makeProfile('a'));
    await repository.delete('a');
    expect(repository.getAll(), isEmpty);
  });
}
