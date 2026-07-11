import 'package:hive/hive.dart';

import '../models/category.dart';

class CategoryRepository {
  CategoryRepository(this._box);

  final Box<Category> _box;

  List<Category> getAll() => _box.values.toList(growable: false);

  Category? getById(String id) => _box.get(id);

  Future<void> save(Category category) => _box.put(category.id, category);

  Future<void> delete(String id) => _box.delete(id);
}
