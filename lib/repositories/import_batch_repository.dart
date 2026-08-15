import 'package:hive/hive.dart';

import '../models/import_batch.dart';

class ImportBatchRepository {
  ImportBatchRepository(this._box);

  final Box<ImportBatch> _box;

  List<ImportBatch> getAll() => _box.values.toList(growable: false);

  Future<void> save(ImportBatch batch) => _box.put(batch.id, batch);

  Future<void> delete(String id) => _box.delete(id);
}
