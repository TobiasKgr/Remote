import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/person_providers.dart';

/// Row of filter chips ("Alle" / "Gemeinsam" / one per person) shown above
/// month/year data. Hidden entirely when no persons have been added yet, so
/// single-person households see no extra UI.
class PersonFilterBar extends ConsumerWidget {
  const PersonFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persons = ref.watch(personNotifierProvider);
    if (persons.isEmpty) return const SizedBox.shrink();

    final selected = ref.watch(selectedPersonFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Alle'),
              selected: selected == null,
              onSelected: (_) => ref.read(selectedPersonFilterProvider.notifier).state = null,
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Gemeinsam'),
              selected: selected == sharedPersonFilter,
              onSelected: (_) => ref.read(selectedPersonFilterProvider.notifier).state = sharedPersonFilter,
            ),
            for (final person in persons) ...[
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: CircleAvatar(backgroundColor: Color(person.colorValue), radius: 8),
                label: Text(person.name),
                selected: selected == person.id,
                onSelected: (_) => ref.read(selectedPersonFilterProvider.notifier).state = person.id,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
