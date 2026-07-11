import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/salary_slip.dart';
import 'repository_providers.dart';
import 'transaction_providers.dart';

class SalarySlipNotifier extends Notifier<List<SalarySlip>> {
  @override
  List<SalarySlip> build() {
    return ref.watch(salarySlipRepositoryProvider).getAll();
  }

  Future<void> upsert(SalarySlip slip) async {
    await ref.read(salarySlipRepositoryProvider).save(slip);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(salarySlipRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final salarySlipNotifierProvider = NotifierProvider<SalarySlipNotifier, List<SalarySlip>>(SalarySlipNotifier.new);

final salarySlipsForSelectedYearProvider = Provider<List<SalarySlip>>((ref) {
  final year = ref.watch(selectedYearProvider);
  final all = ref.watch(salarySlipNotifierProvider);
  return all.where((s) => s.period.year == year).toList(growable: false);
});
