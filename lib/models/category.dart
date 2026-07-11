import 'package:hive/hive.dart';

enum CategoryType { income, expense }

class CategoryTypeAdapter extends TypeAdapter<CategoryType> {
  @override
  final int typeId = 3;

  @override
  CategoryType read(BinaryReader reader) => CategoryType.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, CategoryType obj) => writer.writeByte(obj.index);
}

/// A subcategory belongs to exactly one [Category], e.g. "Streaming" under "Fixkosten & Abos".
class Subcategory {
  Subcategory({
    required this.id,
    required this.name,
    List<String>? keywords,
  }) : keywords = keywords ?? [];

  final String id;
  String name;

  /// Lower-case description keywords used for automatic categorization when
  /// importing bank statement lines (e.g. "netflix", "spotify").
  final List<String> keywords;
}

class SubcategoryAdapter extends TypeAdapter<Subcategory> {
  @override
  final int typeId = 1;

  @override
  Subcategory read(BinaryReader reader) {
    final map = reader.readMap();
    return Subcategory(
      id: map['id'] as String,
      name: map['name'] as String,
      keywords: (map['keywords'] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Subcategory obj) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'keywords': obj.keywords,
    });
  }
}

class Category extends HiveObject {
  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.colorValue,
    List<Subcategory>? subcategories,
  }) : subcategories = subcategories ?? [];

  final String id;
  String name;
  CategoryType type;
  int colorValue;
  final List<Subcategory> subcategories;
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 0;

  @override
  Category read(BinaryReader reader) {
    final map = reader.readMap();
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: CategoryType.values[map['type'] as int],
      colorValue: map['colorValue'] as int,
      subcategories: (map['subcategories'] as List).cast<Subcategory>(),
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'type': obj.type.index,
      'colorValue': obj.colorValue,
      'subcategories': obj.subcategories,
    });
  }
}
