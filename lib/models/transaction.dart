import 'package:hive/hive.dart';

enum TransactionSource { manual, pdfImport }

class TransactionSourceAdapter extends TypeAdapter<TransactionSource> {
  @override
  final int typeId = 4;

  @override
  TransactionSource read(BinaryReader reader) => TransactionSource.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, TransactionSource obj) => writer.writeByte(obj.index);
}

/// A single booked amount on an account. Positive [amount] is income,
/// negative [amount] is an expense.
class Transaction extends HiveObject {
  Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
    required this.categoryId,
    this.subcategoryId,
    this.source = TransactionSource.manual,
    this.isRecurring = false,
  });

  final String id;
  DateTime date;
  double amount;
  String description;
  String categoryId;
  String? subcategoryId;
  TransactionSource source;
  bool isRecurring;

  bool get isIncome => amount >= 0;
}

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 2;

  @override
  Transaction read(BinaryReader reader) {
    final map = reader.readMap();
    return Transaction(
      id: map['id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      amount: map['amount'] as double,
      description: map['description'] as String,
      categoryId: map['categoryId'] as String,
      subcategoryId: map['subcategoryId'] as String?,
      source: TransactionSource.values[map['source'] as int],
      isRecurring: map['isRecurring'] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer.writeMap({
      'id': obj.id,
      'date': obj.date.millisecondsSinceEpoch,
      'amount': obj.amount,
      'description': obj.description,
      'categoryId': obj.categoryId,
      'subcategoryId': obj.subcategoryId,
      'source': obj.source.index,
      'isRecurring': obj.isRecurring,
    });
  }
}
