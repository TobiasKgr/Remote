import 'package:hive/hive.dart';

/// A spending limit ("Sparziel") for one expense [Category].
///
/// A budget with [year] and [month] both null is the recurring **default**
/// limit that applies to every month. A budget with [year]/[month] set is a
/// one-off **override** for that specific month (e.g. a higher limit for
/// December), which takes priority over the default when both exist.
class Budget extends HiveObject {
  Budget({
    required this.id,
    required this.categoryId,
    required this.monthlyLimit,
    this.year,
    this.month,
  });

  /// Builds the id for the recurring default budget of a category.
  static String defaultId(String categoryId) => categoryId;

  /// Builds the id for a month-specific override.
  static String overrideId(String categoryId, int year, int month) => '$categoryId::$year-$month';

  final String id;
  final String categoryId;
  double monthlyLimit;
  final int? year;
  final int? month;

  bool get isOverride => year != null && month != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'monthlyLimit': monthlyLimit,
        'year': year,
        'month': month,
      };

  static Budget fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
        year: json['year'] as int?,
        month: json['month'] as int?,
      );
}

class BudgetAdapter extends TypeAdapter<Budget> {
  @override
  final int typeId = 8;

  @override
  Budget read(BinaryReader reader) {
    final map = reader.readMap();
    return Budget(
      id: map['id'] as String,
      categoryId: map['categoryId'] as String,
      monthlyLimit: map['monthlyLimit'] as double,
      year: map['year'] as int?,
      month: map['month'] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Budget obj) {
    writer.writeMap({
      'id': obj.id,
      'categoryId': obj.categoryId,
      'monthlyLimit': obj.monthlyLimit,
      'year': obj.year,
      'month': obj.month,
    });
  }
}
