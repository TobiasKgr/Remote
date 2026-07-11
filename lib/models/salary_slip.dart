import 'package:hive/hive.dart';

/// A parsed (or manually entered) "Gehaltsabrechnung" for one pay period.
///
/// This is kept separate from [Transaction]: it is a detail/breakdown record
/// (Brutto vs. Netto vs. Abzüge) and does not by itself count towards the
/// income shown on the Dashboard. When saving a slip, the user can
/// optionally also create a matching income [Transaction] for the net
/// amount - see the Gehalt screen.
class SalarySlip extends HiveObject {
  SalarySlip({
    required this.id,
    required this.period,
    required this.gross,
    required this.net,
    this.incomeTax = 0,
    this.socialSecurity = 0,
    this.otherDeductions = 0,
    this.employer,
    this.linkedTransactionId,
    this.personId,
  });

  final String id;

  /// First day of the month this payslip covers.
  DateTime period;

  double gross;
  double net;

  /// Lohnsteuer + Solidaritätszuschlag + Kirchensteuer.
  double incomeTax;

  /// Kranken-, Renten-, Arbeitslosen- und Pflegeversicherung.
  double socialSecurity;

  /// Remainder of gross - net that could not be attributed to tax or
  /// social security (e.g. vermögenswirksame Leistungen, Sachbezüge).
  double otherDeductions;

  String? employer;

  /// Id of the [Transaction] created from this slip's net amount, if any.
  String? linkedTransactionId;

  /// Household member this payslip belongs to. `null` means "Gemeinsam".
  String? personId;
}

class SalarySlipAdapter extends TypeAdapter<SalarySlip> {
  @override
  final int typeId = 5;

  @override
  SalarySlip read(BinaryReader reader) {
    final map = reader.readMap();
    return SalarySlip(
      id: map['id'] as String,
      period: DateTime.fromMillisecondsSinceEpoch(map['period'] as int),
      gross: map['gross'] as double,
      net: map['net'] as double,
      incomeTax: map['incomeTax'] as double,
      socialSecurity: map['socialSecurity'] as double,
      otherDeductions: map['otherDeductions'] as double,
      employer: map['employer'] as String?,
      linkedTransactionId: map['linkedTransactionId'] as String?,
      personId: map['personId'] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SalarySlip obj) {
    writer.writeMap({
      'id': obj.id,
      'period': obj.period.millisecondsSinceEpoch,
      'gross': obj.gross,
      'net': obj.net,
      'incomeTax': obj.incomeTax,
      'socialSecurity': obj.socialSecurity,
      'otherDeductions': obj.otherDeductions,
      'employer': obj.employer,
      'linkedTransactionId': obj.linkedTransactionId,
      'personId': obj.personId,
    });
  }
}
