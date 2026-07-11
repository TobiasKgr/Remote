import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../providers/category_providers.dart';

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
  Colors.blueGrey,
  Colors.grey,
];

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryNotifierProvider);
    final income = categories.where((c) => c.type == CategoryType.income).toList();
    final expense = categories.where((c) => c.type == CategoryType.expense).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Kategorien')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text('Einnahmen', style: Theme.of(context).textTheme.titleMedium),
            ...income.map((c) => _CategoryTile(category: c)),
            const SizedBox(height: 16),
            Text('Ausgaben', style: Theme.of(context).textTheme.titleMedium),
            ...expense.map((c) => _CategoryTile(category: c)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Kategorie'),
      ),
    );
  }

  Future<void> _showCategoryDialog(BuildContext context, WidgetRef ref, {Category? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    CategoryType type = existing?.type ?? CategoryType.expense;
    Color color = existing != null ? Color(existing.colorValue) : _availableColors.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(existing == null ? 'Neue Kategorie' : 'Kategorie bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 16),
                SegmentedButton<CategoryType>(
                  segments: const [
                    ButtonSegment(value: CategoryType.expense, label: Text('Ausgabe')),
                    ButtonSegment(value: CategoryType.income, label: Text('Einnahme')),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) => setStateDialog(() => type = s.first),
                ),
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
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Speichern')),
          ],
        ),
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      final category = Category(
        id: existing?.id ?? const Uuid().v4(),
        name: nameController.text.trim(),
        type: type,
        colorValue: color.toARGB32(),
        subcategories: existing?.subcategories,
      );
      await ref.read(categoryNotifierProvider.notifier).upsert(category);
    }
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(backgroundColor: Color(category.colorValue), radius: 12),
        title: Text(category.name),
        children: [
          for (final sub in category.subcategories)
            ListTile(
              dense: true,
              title: Text(sub.name),
              subtitle: sub.keywords.isNotEmpty ? Text(sub.keywords.join(', ')) : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () async {
                  category.subcategories.removeWhere((s) => s.id == sub.id);
                  await ref.read(categoryNotifierProvider.notifier).upsert(category);
                },
              ),
              onTap: () => _showSubcategoryDialog(context, ref, category, existing: sub),
            ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.add, size: 20),
            title: const Text('Unterkategorie hinzufügen'),
            onTap: () => _showSubcategoryDialog(context, ref, category),
          ),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Kategorie löschen'),
                onPressed: () async {
                  await ref.read(categoryNotifierProvider.notifier).remove(category.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showSubcategoryDialog(BuildContext context, WidgetRef ref, Category category, {Subcategory? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final keywordsController = TextEditingController(text: existing?.keywords.join(', ') ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Neue Unterkategorie' : 'Unterkategorie bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(
              controller: keywordsController,
              decoration: const InputDecoration(
                labelText: 'Suchbegriffe für Auto-Kategorisierung (Komma-getrennt)',
                hintText: 'z. B. netflix, spotify',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Speichern')),
        ],
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      final keywords = keywordsController.text.split(',').map((k) => k.trim().toLowerCase()).where((k) => k.isNotEmpty).toList();
      final newSub = Subcategory(id: existing?.id ?? const Uuid().v4(), name: nameController.text.trim(), keywords: keywords);
      if (existing != null) {
        category.subcategories.removeWhere((s) => s.id == existing.id);
      }
      category.subcategories.add(newSub);
      await ref.read(categoryNotifierProvider.notifier).upsert(category);
    }
  }
}
