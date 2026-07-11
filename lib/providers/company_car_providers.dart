import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company_car.dart';
import 'repository_providers.dart';

class CompanyCarNotifier extends Notifier<List<CompanyCar>> {
  @override
  List<CompanyCar> build() {
    final list = ref.watch(companyCarRepositoryProvider).getAll();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> upsert(CompanyCar car) async {
    await ref.read(companyCarRepositoryProvider).save(car);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(companyCarRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final companyCarNotifierProvider = NotifierProvider<CompanyCarNotifier, List<CompanyCar>>(CompanyCarNotifier.new);
