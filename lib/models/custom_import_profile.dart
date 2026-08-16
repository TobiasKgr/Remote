import 'package:hive/hive.dart';

/// Which date format a bank statement's lines use.
enum ImportDateFormat { ddMMyyyy, ddMMyy }

extension ImportDateFormatLabel on ImportDateFormat {
  String get label => switch (this) {
        ImportDateFormat.ddMMyyyy => 'TT.MM.JJJJ (z. B. 15.03.2026)',
        ImportDateFormat.ddMMyy => 'TT.MM.JJ (z. B. 15.03.26)',
      };
}

/// Where the amount sits relative to the date on a transaction line.
enum ImportAmountPosition { afterDate, endOfLine }

extension ImportAmountPositionLabel on ImportAmountPosition {
  String get label => switch (this) {
        ImportAmountPosition.afterDate => 'Direkt nach dem Datum',
        ImportAmountPosition.endOfLine => 'Am Ende der Buchungszeile',
      };
}

/// Which decimal separator amounts use.
enum ImportDecimalSeparator { comma, dot }

extension ImportDecimalSeparatorLabel on ImportDecimalSeparator {
  String get label => switch (this) {
        ImportDecimalSeparator.comma => 'Komma (1.234,56)',
        ImportDecimalSeparator.dot => 'Punkt (1,234.56)',
      };
}

/// A user-taught PDF layout ("Format anlernen") for banks the built-in
/// parsers don't recognize - a lightweight alternative to writing a new
/// bespoke parser (like [parseTargobankFinanzstatus]) for every institution.
/// Deliberately limited to the handful of variations that actually differ
/// between German bank statement layouts (date format, decimal separator,
/// amount position) rather than a fully general rule engine.
class CustomImportProfile extends HiveObject {
  CustomImportProfile({
    required this.id,
    required this.name,
    required this.dateFormat,
    required this.amountPosition,
    required this.decimalSeparator,
    required this.createdAt,
  });

  final String id;

  /// User-chosen label, e.g. the bank's name.
  final String name;

  final ImportDateFormat dateFormat;
  final ImportAmountPosition amountPosition;
  final ImportDecimalSeparator decimalSeparator;
  final DateTime createdAt;
}

class CustomImportProfileAdapter extends TypeAdapter<CustomImportProfile> {
  @override
  final int typeId = 15;

  @override
  CustomImportProfile read(BinaryReader reader) {
    final map = reader.readMap();
    return CustomImportProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      dateFormat: ImportDateFormat.values[map['dateFormat'] as int],
      amountPosition: ImportAmountPosition.values[map['amountPosition'] as int],
      decimalSeparator: ImportDecimalSeparator.values[map['decimalSeparator'] as int],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  @override
  void write(BinaryWriter writer, CustomImportProfile obj) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'dateFormat': obj.dateFormat.index,
      'amountPosition': obj.amountPosition.index,
      'decimalSeparator': obj.decimalSeparator.index,
      'createdAt': obj.createdAt.millisecondsSinceEpoch,
    });
  }
}
