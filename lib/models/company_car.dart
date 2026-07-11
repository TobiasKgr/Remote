import 'package:hive/hive.dart';

/// A company car ("Dienstwagen") made available to a household member.
///
/// [monthlyBenefitInKind] (geldwerter Vorteil, e.g. via the 1%-Regel) is
/// purely informational: it is normally already included as a taxable
/// addition in the payslip's Brutto and cancelled out again on the Netto
/// side, so it is intentionally *not* mixed into any income totals here to
/// avoid double counting. [monthlyEmployeeContribution] (Eigenanteil) is the
/// actual amount the person pays out of pocket for private use and can be
/// logged as a real expense [Transaction] from the Firmenwagen screen.
class CompanyCar extends HiveObject {
  CompanyCar({
    required this.id,
    required this.name,
    this.personId,
    this.monthlyBenefitInKind = 0,
    this.monthlyEmployeeContribution = 0,
    this.notes,
  });

  final String id;
  String name;
  String? personId;
  double monthlyBenefitInKind;
  double monthlyEmployeeContribution;
  String? notes;
}

class CompanyCarAdapter extends TypeAdapter<CompanyCar> {
  @override
  final int typeId = 7;

  @override
  CompanyCar read(BinaryReader reader) {
    final map = reader.readMap();
    return CompanyCar(
      id: map['id'] as String,
      name: map['name'] as String,
      personId: map['personId'] as String?,
      monthlyBenefitInKind: map['monthlyBenefitInKind'] as double,
      monthlyEmployeeContribution: map['monthlyEmployeeContribution'] as double,
      notes: map['notes'] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CompanyCar obj) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'personId': obj.personId,
      'monthlyBenefitInKind': obj.monthlyBenefitInKind,
      'monthlyEmployeeContribution': obj.monthlyEmployeeContribution,
      'notes': obj.notes,
    });
  }
}
