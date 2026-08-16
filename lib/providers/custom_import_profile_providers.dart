import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/custom_import_profile.dart';
import 'repository_providers.dart';

class CustomImportProfileNotifier extends Notifier<List<CustomImportProfile>> {
  @override
  List<CustomImportProfile> build() {
    final list = ref.watch(customImportProfileRepositoryProvider).getAll();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> add(CustomImportProfile profile) async {
    await ref.read(customImportProfileRepositoryProvider).save(profile);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(customImportProfileRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final customImportProfileNotifierProvider =
    NotifierProvider<CustomImportProfileNotifier, List<CustomImportProfile>>(CustomImportProfileNotifier.new);
