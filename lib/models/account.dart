import 'package:hive/hive.dart';

/// The kind of account, purely for icon/grouping/labeling purposes - every
/// type behaves identically in balance calculation (startingBalance + sum of
/// booked transactions) and can be transferred to/from like any other.
enum AccountType {
  girokonto,
  tagesgeld,
  kreditkarte,

  /// A tracked loan/credit: [Account.startingBalance] is typically negative
  /// (the amount owed), and repayment [Transaction]s (or Umbuchungen from
  /// another own account) reduce the debt over time. For a loan you don't
  /// want booking-by-booking tracking for, use an [Asset] with
  /// `AssetCategory.liability` instead - a plain manually-updated value.
  kredit,
}

class AccountTypeAdapter extends TypeAdapter<AccountType> {
  @override
  final int typeId = 12;

  @override
  AccountType read(BinaryReader reader) => AccountType.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, AccountType obj) => writer.writeByte(obj.index);
}

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
    this.type = AccountType.girokonto,
  });

  final String id;
  String name;
  double startingBalance;
  int colorValue;
  AccountType type;

  /// Owning household member, if any. `null` means shared/not attributed.
  String? personId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startingBalance': startingBalance,
        'colorValue': colorValue,
        'personId': personId,
        'type': type.index,
      };

  static Account fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
        startingBalance: (json['startingBalance'] as num).toDouble(),
        colorValue: json['colorValue'] as int,
        personId: json['personId'] as String?,
        type: AccountType.values[(json['type'] as int?) ?? 0],
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
      // Accounts persisted before AccountType existed have no 'type' key -
      // default them to the most common kind (Girokonto).
      type: AccountType.values[(map['type'] as int?) ?? 0],
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
      'type': obj.type.index,
    });
  }
}
