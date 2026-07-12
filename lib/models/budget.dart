import 'package:hive/hive.dart';

/// A monthly spending limit ("Sparziel") for one expense [Category].
/// One budget per category, keyed by [categoryId].
class Budget extends HiveObject {
  Budget({required this.categoryId, required this.monthlyLimit});

  final String categoryId;
  double monthlyLimit;

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'monthlyLimit': monthlyLimit,
      };

  static Budget fromJson(Map<String, dynamic> json) => Budget(
        categoryId: json['categoryId'] as String,
        monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
      );
}

class BudgetAdapter extends TypeAdapter<Budget> {
  @override
  final int typeId = 8;

  @override
  Budget read(BinaryReader reader) {
    final map = reader.readMap();
    return Budget(
      categoryId: map['categoryId'] as String,
      monthlyLimit: map['monthlyLimit'] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Budget obj) {
    writer.writeMap({
      'categoryId': obj.categoryId,
      'monthlyLimit': obj.monthlyLimit,
    });
  }
}
