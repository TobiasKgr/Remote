import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import '../models/category.dart';
import '../providers/budget_providers.dart';
import '../providers/category_providers.dart';
import '../utils/formatters.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryNotifierProvider).where((c) => c.type == CategoryType.expense).toList();
    final budgets = {for (final b in ref.watch(budgetNotifierProvider)) b.categoryId: b};

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets / Sparziele')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Lege ein monatliches Limit pro Ausgaben-Kategorie fest. Auf dem Dashboard '
                'siehst du dann den Fortschritt für den aktuell ausgewählten Monat.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            for (final category in categories) _BudgetTile(category: category, budget: budgets[category.id]),
          ],
        ),
      ),
    );
  }
}

class _BudgetTile extends ConsumerWidget {
  const _BudgetTile({required this.category, required this.budget});

  final Category category;
  final Budget? budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Color(category.colorValue), radius: 12),
        title: Text(category.name),
        subtitle: Text(budget == null ? 'Kein Budget gesetzt' : '${currencyFormat.format(budget!.monthlyLimit)} / Monat'),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showBudgetDialog(context, ref, category, budget),
            ),
            if (budget != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(budgetNotifierProvider.notifier).remove(category.id),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBudgetDialog(BuildContext context, WidgetRef ref, Category category, Budget? existing) async {
    final controller = TextEditingController(
      text: existing == null || existing.monthlyLimit == 0 ? '' : existing.monthlyLimit.toStringAsFixed(2),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Budget: ${category.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Monatliches Limit (€)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Speichern')),
        ],
      ),
    );

    if (saved != true) return;
    final limit = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
    if (limit <= 0) {
      await ref.read(budgetNotifierProvider.notifier).remove(category.id);
    } else {
      await ref.read(budgetNotifierProvider.notifier).upsert(Budget(categoryId: category.id, monthlyLimit: limit));
    }
  }
}
