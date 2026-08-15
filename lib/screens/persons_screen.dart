import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/person.dart';
import '../providers/person_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_widgets.dart';

class PersonsScreen extends ConsumerWidget {
  const PersonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persons = ref.watch(personNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: SafeArea(
        child: persons.isEmpty
            ? ListView(
                children: [
                  const AppleLargeTitle('Personen'),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Noch keine Personen angelegt. Buchungen ohne Person gelten als "Gemeinsam".\n\n'
                      'Füge z. B. dich und eine zweite Person im Haushalt hinzu, um Buchungen '
                      'getrennt oder gemeinsam auszuwerten.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.appleColors.secondaryLabel),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  const AppleLargeTitle('Personen'),
                  AppleGroupedSection(children: [for (final person in persons) _PersonTile(person: person)]),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPersonDialog(context, ref),
        icon: const Icon(CupertinoIcons.person_add),
        label: const Text('Person'),
      ),
    );
  }
}

Future<void> _showPersonDialog(BuildContext context, WidgetRef ref, {Person? existing}) async {
  final nameController = TextEditingController(text: existing?.name ?? '');
  Color color = existing != null ? Color(existing.colorValue) : AppleColors.pickerPalette.first;

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
              children: AppleColors.pickerPalette
                  .map((c) => GestureDetector(
                        onTap: () => setStateDialog(() => color = c),
                        child: CircleAvatar(
                          backgroundColor: c,
                          radius: 16,
                          child: color.toARGB32() == c.toARGB32() ? const Icon(CupertinoIcons.check_mark, color: Colors.white, size: 18) : null,
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
    return ListTile(
      leading: CircleAvatar(backgroundColor: Color(person.colorValue), child: Text(person.name.isNotEmpty ? person.name[0] : '?')),
      title: Text(person.name),
      trailing: IconButton(
        icon: Icon(CupertinoIcons.trash, color: context.appleColors.danger),
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
    );
  }
}
