import 'package:hive/hive.dart';

import '../models/person.dart';

class PersonRepository {
  PersonRepository(this._box);

  final Box<Person> _box;

  List<Person> getAll() => _box.values.toList(growable: false);

  Person? getById(String id) => _box.get(id);

  Future<void> save(Person person) => _box.put(person.id, person);

  Future<void> delete(String id) => _box.delete(id);
}
