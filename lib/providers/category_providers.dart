import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import 'repository_providers.dart';

class CategoryNotifier extends Notifier<List<Category>> {
  @override
  List<Category> build() {
    final list = ref.watch(categoryRepositoryProvider).getAll();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> upsert(Category category) async {
    await ref.read(categoryRepositoryProvider).save(category);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(categoryRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final categoryNotifierProvider = NotifierProvider<CategoryNotifier, List<Category>>(CategoryNotifier.new);

final categoryByIdProvider = Provider.family<Category?, String>((ref, id) {
  final categories = ref.watch(categoryNotifierProvider);
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
});
