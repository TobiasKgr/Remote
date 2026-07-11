import 'package:hive/hive.dart';

import '../models/company_car.dart';

class CompanyCarRepository {
  CompanyCarRepository(this._box);

  final Box<CompanyCar> _box;

  List<CompanyCar> getAll() => _box.values.toList(growable: false);

  Future<void> save(CompanyCar car) => _box.put(car.id, car);

  Future<void> delete(String id) => _box.delete(id);
}
