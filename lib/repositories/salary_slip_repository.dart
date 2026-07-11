import 'package:hive/hive.dart';

import '../models/salary_slip.dart';

class SalarySlipRepository {
  SalarySlipRepository(this._box);

  final Box<SalarySlip> _box;

  List<SalarySlip> getAll() {
    final list = _box.values.toList(growable: false);
    list.sort((a, b) => a.period.compareTo(b.period));
    return list;
  }

  List<SalarySlip> getForYear(int year) {
    return getAll().where((s) => s.period.year == year).toList(growable: false);
  }

  Future<void> save(SalarySlip slip) => _box.put(slip.id, slip);

  Future<void> delete(String id) => _box.delete(id);
}
