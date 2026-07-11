import 'dart:io';

import 'package:finance_analyzer/models/company_car.dart';
import 'package:finance_analyzer/repositories/company_car_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<CompanyCar> box;
  late CompanyCarRepository repository;
  var boxCounter = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('finance_analyzer_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(CompanyCarAdapter());
    box = await Hive.openBox<CompanyCar>('company_cars_test_${boxCounter++}');
    repository = CompanyCarRepository(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('save and getAll roundtrip', () async {
    await repository.save(CompanyCar(id: 'a', name: 'BMW 320d', monthlyBenefitInKind: 350, monthlyEmployeeContribution: 120));
    final all = repository.getAll();
    expect(all, hasLength(1));
    expect(all.first.name, 'BMW 320d');
    expect(all.first.monthlyBenefitInKind, 350);
    expect(all.first.monthlyEmployeeContribution, 120);
  });

  test('delete removes the car', () async {
    await repository.save(CompanyCar(id: 'a', name: 'BMW 320d'));
    await repository.delete('a');
    expect(repository.getAll(), isEmpty);
  });

  test('personId and notes round-trip through the Hive adapter', () async {
    await repository.save(CompanyCar(id: 'a', name: 'Audi A4', personId: 'alice', notes: 'Werkstatttermin im Mai'));
    final saved = repository.getAll().single;
    expect(saved.personId, 'alice');
    expect(saved.notes, 'Werkstatttermin im Mai');
  });
}
