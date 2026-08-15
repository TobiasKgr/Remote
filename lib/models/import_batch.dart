import 'package:hive/hive.dart';

/// Which import flow produced an [ImportBatch].
enum ImportSource { kontoauszug, gehalt }

class ImportSourceAdapter extends TypeAdapter<ImportSource> {
  @override
  final int typeId = 14;

  @override
  ImportSource read(BinaryReader reader) => ImportSource.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, ImportSource obj) => writer.writeByte(obj.index);
}

/// One completed import action - a PDF (or several, picked together) parsed
/// and saved in one go. Recorded so the user can see an import history and
/// undo a whole import ("zu diesem Import-Stand zurückspringen") instead of
/// hunting down individual bookings by hand, and so future imports can be
/// checked against what a past import already added.
class ImportBatch extends HiveObject {
  ImportBatch({
    required this.id,
    required this.timestamp,
    required this.source,
    required this.label,
    this.transactionIds = const [],
    this.salarySlipIds = const [],
  });

  final String id;
  final DateTime timestamp;
  final ImportSource source;

  /// Short human-readable summary, e.g. "42 Buchungen aus 3 Dateien" or
  /// "Gehaltsabrechnung Juni 2026".
  final String label;

  final List<String> transactionIds;
  final List<String> salarySlipIds;
}

class ImportBatchAdapter extends TypeAdapter<ImportBatch> {
  @override
  final int typeId = 13;

  @override
  ImportBatch read(BinaryReader reader) {
    final map = reader.readMap();
    return ImportBatch(
      id: map['id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      source: ImportSource.values[map['source'] as int],
      label: map['label'] as String,
      transactionIds: (map['transactionIds'] as List).cast<String>(),
      salarySlipIds: (map['salarySlipIds'] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, ImportBatch obj) {
    writer.writeMap({
      'id': obj.id,
      'timestamp': obj.timestamp.millisecondsSinceEpoch,
      'source': obj.source.index,
      'label': obj.label,
      'transactionIds': obj.transactionIds,
      'salarySlipIds': obj.salarySlipIds,
    });
  }
}
