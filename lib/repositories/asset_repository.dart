import 'package:hive/hive.dart';

import '../models/asset.dart';

class AssetRepository {
  AssetRepository(this._box);

  final Box<Asset> _box;

  List<Asset> getAll() => _box.values.toList(growable: false);

  Future<void> save(Asset asset) => _box.put(asset.id, asset);

  Future<void> delete(String id) => _box.delete(id);
}
