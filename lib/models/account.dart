import 'package:hive/hive.dart';

/// A bank account ("Konto"). Its current balance is derived, not stored:
/// [startingBalance] plus the sum of all [Transaction.amount] booked to it
/// (see `computeAccountBalance` in account_providers.dart).
class Account extends HiveObject {
  Account({
    required this.id,
    required this.name,
    this.startingBalance = 0,
    this.colorValue = 0xFF2196F3,
    this.personId,
  });

  final String id;
  String name;
  double startingBalance;
  int colorValue;

  /// Owning household member, if any. `null` means shared/not attributed.
  String? personId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startingBalance': startingBalance,
        'colorValue': colorValue,
        'personId': personId,
      };

  static Account fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
        startingBalance: (json['startingBalance'] as num).toDouble(),
        colorValue: json['colorValue'] as int,
        personId: json['personId'] as String?,
      );
}

class AccountAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = 9;

  @override
  Account read(BinaryReader reader) {
    final map = reader.readMap();
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      startingBalance: map['startingBalance'] as double,
      colorValue: map['colorValue'] as int,
      personId: map['personId'] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'startingBalance': obj.startingBalance,
      'colorValue': obj.colorValue,
      'personId': obj.personId,
    });
  }
}
