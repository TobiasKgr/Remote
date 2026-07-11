import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/person.dart';
import 'repository_providers.dart';

class PersonNotifier extends Notifier<List<Person>> {
  @override
  List<Person> build() {
    final list = ref.watch(personRepositoryProvider).getAll();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> upsert(Person person) async {
    await ref.read(personRepositoryProvider).save(person);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(personRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final personNotifierProvider = NotifierProvider<PersonNotifier, List<Person>>(PersonNotifier.new);

final personByIdProvider = Provider.family<Person?, String>((ref, id) {
  for (final person in ref.watch(personNotifierProvider)) {
    if (person.id == id) return person;
  }
  return null;
});

/// Sentinel value for [selectedPersonFilterProvider] meaning "Gemeinsam"
/// (items with `personId == null`). The provider's own `null` means "Alle"
/// (no filter, everyone combined).
const sharedPersonFilter = '__shared__';

final selectedPersonFilterProvider = StateProvider<String?>((ref) => null);

/// Filters [items] by the current person filter selection.
/// - `filter == null` -> no filtering (Alle)
/// - `filter == sharedPersonFilter` -> only items with `personIdOf(item) == null` (Gemeinsam)
/// - otherwise -> only items with `personIdOf(item) == filter`
Iterable<T> filterByPerson<T>(Iterable<T> items, String? filter, String? Function(T) personIdOf) {
  if (filter == null) return items;
  if (filter == sharedPersonFilter) return items.where((i) => personIdOf(i) == null);
  return items.where((i) => personIdOf(i) == filter);
}
