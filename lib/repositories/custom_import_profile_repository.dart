import 'package:hive/hive.dart';

import '../models/custom_import_profile.dart';

class CustomImportProfileRepository {
  CustomImportProfileRepository(this._box);

  final Box<CustomImportProfile> _box;

  List<CustomImportProfile> getAll() => _box.values.toList(growable: false);

  Future<void> save(CustomImportProfile profile) => _box.put(profile.id, profile);

  Future<void> delete(String id) => _box.delete(id);
}
