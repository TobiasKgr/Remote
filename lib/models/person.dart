import 'package:hive/hive.dart';

/// A household member that transactions/salary slips can be attributed to.
/// Absence of a person (`personId == null` on [Transaction]/[SalarySlip])
/// means "Gemeinsam" (shared, not attributed to one person).
class Person extends HiveObject {
  Person({required this.id, required this.name, required this.colorValue});

  final String id;
  String name;
  int colorValue;
}

class PersonAdapter extends TypeAdapter<Person> {
  @override
  final int typeId = 6;

  @override
  Person read(BinaryReader reader) {
    final map = reader.readMap();
    return Person(
      id: map['id'] as String,
      name: map['name'] as String,
      colorValue: map['colorValue'] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Person obj) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'colorValue': obj.colorValue,
    });
  }
}
