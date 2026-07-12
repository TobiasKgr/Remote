import 'package:hive/hive.dart';

/// Which bucket a net-worth item falls into. Bank accounts are handled
/// separately (via [Account]) and are merged in only when computing the
/// total net worth - this enum is only for the manually maintained items.
enum AssetCategory {
  investment,
  realEstate,
  other,

  /// A debt (loan, mortgage, ...). [Asset.value] stays a positive amount
  /// owed; it is subtracted rather than added when summing net worth.
  liability,
}

class AssetCategoryAdapter extends TypeAdapter<AssetCategory> {
  @override
  final int typeId = 11;

  @override
  AssetCategory read(BinaryReader reader) => AssetCategory.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, AssetCategory obj) => writer.writeByte(obj.index);
}

/// A manually valued net-worth item outside of the tracked bank accounts:
/// an investment/depot, real estate, other assets, or a liability (loan/debt).
class Asset extends HiveObject {
  Asset({
    required this.id,
    required this.name,
    required this.category,
    this.value = 0,
    this.colorValue = 0xFF2196F3,
    this.personId,
    this.notes,
  });

  final String id;
  String name;
  AssetCategory category;

  /// Always a positive amount; whether it adds to or subtracts from net
  /// worth is derived from [category].
  double value;
  int colorValue;
  String? personId;
  String? notes;

  bool get isLiability => category == AssetCategory.liability;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.index,
        'value': value,
        'colorValue': colorValue,
        'personId': personId,
        'notes': notes,
      };

  static Asset fromJson(Map<String, dynamic> json) => Asset(
        id: json['id'] as String,
        name: json['name'] as String,
        category: AssetCategory.values[json['category'] as int],
        value: (json['value'] as num).toDouble(),
        colorValue: json['colorValue'] as int,
        personId: json['personId'] as String?,
        notes: json['notes'] as String?,
      );
}

class AssetAdapter extends TypeAdapter<Asset> {
  @override
  final int typeId = 10;

  @override
  Asset read(BinaryReader reader) {
    final map = reader.readMap();
    return Asset(
      id: map['id'] as String,
      name: map['name'] as String,
      category: AssetCategory.values[map['category'] as int],
      value: map['value'] as double,
      colorValue: map['colorValue'] as int,
      personId: map['personId'] as String?,
      notes: map['notes'] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Asset obj) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'category': obj.category.index,
      'value': obj.value,
      'colorValue': obj.colorValue,
      'personId': obj.personId,
      'notes': obj.notes,
    });
  }
}
