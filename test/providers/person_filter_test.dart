import 'package:finance_analyzer/providers/person_providers.dart';
import 'package:flutter_test/flutter_test.dart';

class _Item {
  _Item(this.id, this.personId);
  final String id;
  final String? personId;
}

void main() {
  final items = [
    _Item('a', 'alice'),
    _Item('b', 'bob'),
    _Item('c', null),
    _Item('d', 'alice'),
  ];

  test('null filter (Alle) gibt alle Elemente zurück', () {
    final result = filterByPerson(items, null, (i) => i.personId);
    expect(result.map((i) => i.id), ['a', 'b', 'c', 'd']);
  });

  test('sharedPersonFilter gibt nur Elemente ohne Person zurück (Gemeinsam)', () {
    final result = filterByPerson(items, sharedPersonFilter, (i) => i.personId);
    expect(result.map((i) => i.id), ['c']);
  });

  test('konkrete Person-ID filtert nur deren Elemente', () {
    final result = filterByPerson(items, 'alice', (i) => i.personId);
    expect(result.map((i) => i.id), ['a', 'd']);
  });

  test('unbekannte Person-ID liefert leere Liste', () {
    final result = filterByPerson(items, 'unknown', (i) => i.personId);
    expect(result, isEmpty);
  });
}
