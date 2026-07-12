import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import '../models/category.dart';
import '../providers/budget_providers.dart';
import '../providers/category_providers.dart';
import '../providers/transaction_providers.dart';
import '../utils/formatters.dart';
import '../widgets/month_selector.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final categories = ref.watch(categoryNotifierProvider).where((c) => c.type == CategoryType.expense).toList();
    final budgets = ref.watch(budgetNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets / Sparziele')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Standard-Limit gilt für jeden Monat. Zusätzlich kannst du für einzelne '
                'Monate (z. B. Dezember) ein abweichendes Limit planen - das hat dann Vorrang.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            MonthSelector(month: month, onChanged: (m) => ref.read(selectedMonthProvider.notifier).state = m),
            const SizedBox(height: 12),
            for (final category in categories)
              _BudgetTile(
                category: category,
                month: month,
                defaultBudget: _find(budgets, Budget.defaultId(category.id)),
                monthOverride: _find(budgets, Budget.overrideId(category.id, month.year, month.month)),
              ),
          ],
        ),
      ),
    );
  }

  Budget? _find(List<Budget> budgets, String id) {
    for (final b in budgets) {
      if (b.id == id) return b;
    }
    return null;
  }
}

class _BudgetTile extends ConsumerWidget {
  const _BudgetTile({
    required this.category,
    required this.month,
    required this.defaultBudget,
    required this.monthOverride,
  });

  final Category category;
  final DateTime month;
  final Budget? defaultBudget;
  final Budget? monthOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(backgroundColor: Color(category.colorValue), radius: 12),
              title: Text(category.name),
              subtitle: Text(
                defaultBudget == null ? 'Kein Standard-Budget' : '${currencyFormat.format(defaultBudget!.monthlyLimit)} / Monat (Standard)',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Standard-Budget bearbeiten',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editDefault(context, ref),
                  ),
                  if (defaultBudget != null)
                    IconButton(
                      tooltip: 'Standard-Budget löschen',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref.read(budgetNotifierProvider.notifier).remove(defaultBudget!.id),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      monthOverride == null
                          ? 'Keine Abweichung für ${monthYearFormat.format(month)}'
                          : 'Abweichung ${monthYearFormat.format(month)}: ${currencyFormat.format(monthOverride!.monthlyLimit)}',
                      style: TextStyle(color: monthOverride == null ? Colors.grey : Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  IconButton(
                    tooltip: monthOverride == null ? 'Abweichung planen' : 'Abweichung bearbeiten',
                    icon: Icon(monthOverride == null ? Icons.add_circle_outline : Icons.edit_outlined, size: 20),
                    onPressed: () => _editOverride(context, ref),
                  ),
                  if (monthOverride != null)
                    IconButton(
                      tooltip: 'Abweichung löschen',
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => ref.read(budgetNotifierProvider.notifier).remove(monthOverride!.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editDefault(BuildContext context, WidgetRef ref) async {
    final limit = await _showLimitDialog(context, '${category.name}: Standard-Budget', defaultBudget?.monthlyLimit);
    if (limit == null) return;
    if (limit <= 0) {
      await ref.read(budgetNotifierProvider.notifier).remove(Budget.defaultId(category.id));
    } else {
      await ref.read(budgetNotifierProvider.notifier).upsert(
            Budget(id: Budget.defaultId(category.id), categoryId: category.id, monthlyLimit: limit),
          );
    }
  }

  Future<void> _editOverride(BuildContext context, WidgetRef ref) async {
    final limit = await _showLimitDialog(
      context,
      '${category.name}: Abweichung ${monthYearFormat.format(month)}',
      monthOverride?.monthlyLimit,
    );
    if (limit == null) return;
    final id = Budget.overrideId(category.id, month.year, month.month);
    if (limit <= 0) {
      await ref.read(budgetNotifierProvider.notifier).remove(id);
    } else {
      await ref.read(budgetNotifierProvider.notifier).upsert(
            Budget(id: id, categoryId: category.id, monthlyLimit: limit, year: month.year, month: month.month),
          );
    }
  }

  Future<double?> _showLimitDialog(BuildContext context, String title, double? initialValue) async {
    final controller = TextEditingController(
      text: initialValue == null || initialValue == 0 ? '' : initialValue.toStringAsFixed(2),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Limit (€) - 0 zum Entfernen'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Speichern')),
        ],
      ),
    );

    if (saved != true) return null;
    return double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
  }
}
