import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/person.dart';
import '../providers/person_providers.dart';

const _availableColors = [
  Colors.red,
  Colors.orange,
  Colors.amber,
  Colors.green,
  Colors.teal,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
  Colors.pink,
  Colors.brown,
];

class PersonsScreen extends ConsumerWidget {
  const PersonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persons = ref.watch(personNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Personen')),
      body: SafeArea(
        child: persons.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Noch keine Personen angelegt. Buchungen ohne Person gelten als "Gemeinsam".\n\n'
                    'Füge z. B. dich und eine zweite Person im Haushalt hinzu, um Buchungen '
                    'getrennt oder gemeinsam auszuwerten.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [for (final person in persons) _PersonTile(person: person)],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPersonDialog(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Person'),
      ),
    );
  }
}

Future<void> _showPersonDialog(BuildContext context, WidgetRef ref, {Person? existing}) async {
  final nameController = TextEditingController(text: existing?.name ?? '');
  Color color = existing != null ? Color(existing.colorValue) : _availableColors.first;

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) => AlertDialog(
        title: Text(existing == null ? 'Neue Person' : 'Person bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _availableColors
                  .map((c) => GestureDetector(
                        onTap: () => setStateDialog(() => color = c),
                        child: CircleAvatar(
                          backgroundColor: c,
                          radius: 16,
                          child: color.toARGB32() == c.toARGB32() ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Speichern')),
        ],
      ),
    ),
  );

  if (saved == true && nameController.text.trim().isNotEmpty) {
    final person = Person(
      id: existing?.id ?? const Uuid().v4(),
      name: nameController.text.trim(),
      colorValue: color.toARGB32(),
    );
    await ref.read(personNotifierProvider.notifier).upsert(person);
  }
}

class _PersonTile extends ConsumerWidget {
  const _PersonTile({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Color(person.colorValue), child: Text(person.name.isNotEmpty ? person.name[0] : '?')),
        title: Text(person.name),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Person löschen?'),
                content: Text(
                  '"${person.name}" löschen? Bereits zugeordnete Buchungen/Gehaltsabrechnungen '
                  'bleiben erhalten, gelten danach aber als "Gemeinsam".',
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
                  FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Löschen')),
                ],
              ),
            );
            if (confirmed == true) {
              await ref.read(personNotifierProvider.notifier).remove(person.id);
            }
          },
        ),
        onTap: () => _showPersonDialog(context, ref, existing: person),
      ),
    );
  }
}
