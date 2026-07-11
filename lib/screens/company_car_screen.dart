import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/company_car.dart';
import '../models/transaction.dart';
import '../providers/category_providers.dart';
import '../providers/company_car_providers.dart';
import '../providers/person_providers.dart';
import '../providers/transaction_providers.dart';
import '../utils/formatters.dart';
import '../widgets/month_selector.dart';

const _firmenwagenCategoryId = 'mobilitaet';
const _firmenwagenSubcategoryId = 'mobilitaet_firmenwagen';

class CompanyCarScreen extends ConsumerWidget {
  const CompanyCarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(companyCarNotifierProvider);
    final month = ref.watch(selectedMonthProvider);
    final monthTransactions = ref.watch(transactionsForSelectedMonthProvider);
    final yearTransactions = ref.watch(transactionsForSelectedYearProvider);

    final monthCost = monthTransactions
        .where((t) => t.categoryId == _firmenwagenCategoryId && t.subcategoryId == _firmenwagenSubcategoryId)
        .fold<double>(0, (s, t) => s + t.amount.abs());
    final yearCost = yearTransactions
        .where((t) => t.categoryId == _firmenwagenCategoryId && t.subcategoryId == _firmenwagenSubcategoryId)
        .fold<double>(0, (s, t) => s + t.amount.abs());

    return Scaffold(
      appBar: AppBar(title: const Text('Firmenwagen')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MonthSelector(month: month, onChanged: (m) => ref.read(selectedMonthProvider.notifier).state = m),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tatsächliche Firmenwagen-Kosten', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Summe aller Buchungen in Kategorie "Mobilität → Firmenwagen" '
                      '(z. B. Eigenanteil, Kraftstoff, Versicherung).',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${monthYearFormat.format(month)}:'),
                        Text(currencyFormat.format(monthCost), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Jahr ${month.year}:'),
                        Text(currencyFormat.format(yearCost), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Fahrzeuge', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (cars.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Noch kein Firmenwagen erfasst.'),
              )
            else
              for (final car in cars) _CompanyCarTile(car: car, month: month),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCarDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Firmenwagen'),
      ),
    );
  }
}

Future<void> _showCarDialog(BuildContext context, WidgetRef ref, {CompanyCar? existing}) async {
  final nameController = TextEditingController(text: existing?.name ?? '');
  final benefitController = TextEditingController(text: _fmt(existing?.monthlyBenefitInKind));
  final contributionController = TextEditingController(text: _fmt(existing?.monthlyEmployeeContribution));
  final notesController = TextEditingController(text: existing?.notes ?? '');
  final persons = ref.read(personNotifierProvider);
  String? personId = existing?.personId;

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) => AlertDialog(
        title: Text(existing == null ? 'Neuer Firmenwagen' : 'Firmenwagen bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Bezeichnung (z. B. Modell)')),
              const SizedBox(height: 12),
              TextField(
                controller: benefitController,
                decoration: const InputDecoration(
                  labelText: 'Geldwerter Vorteil / Monat (€)',
                  helperText: 'Nur informativ - bereits in der Gehaltsabrechnung versteuert.',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contributionController,
                decoration: const InputDecoration(
                  labelText: 'Eigenanteil / Monat (€)',
                  helperText: 'Tatsächliche eigene Kosten für die Privatnutzung.',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              if (persons.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: personId,
                  decoration: const InputDecoration(labelText: 'Person'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Gemeinsam')),
                    ...persons.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                  ],
                  onChanged: (v) => setStateDialog(() => personId = v),
                ),
              ],
              const SizedBox(height: 12),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notizen (optional)')),
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
    final car = CompanyCar(
      id: existing?.id ?? const Uuid().v4(),
      name: nameController.text.trim(),
      personId: personId,
      monthlyBenefitInKind: double.tryParse(benefitController.text.replaceAll(',', '.')) ?? 0,
      monthlyEmployeeContribution: double.tryParse(contributionController.text.replaceAll(',', '.')) ?? 0,
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
    );
    await ref.read(companyCarNotifierProvider.notifier).upsert(car);
  }
}

String _fmt(double? value) => value == null || value == 0 ? '' : value.toStringAsFixed(2);

class _CompanyCarTile extends ConsumerWidget {
  const _CompanyCarTile({required this.car, required this.month});

  final CompanyCar car;
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = car.personId != null ? ref.watch(personByIdProvider(car.personId!)) : null;
    final firmenwagenCategory = ref.watch(categoryByIdProvider(_firmenwagenCategoryId));
    final hasFirmenwagenSubcategory = firmenwagenCategory?.subcategories.any((s) => s.id == _firmenwagenSubcategoryId) ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(car.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (person != null) Text(person.name, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showCarDialog(context, ref, existing: car),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref.read(companyCarNotifierProvider.notifier).remove(car.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Geldwerter Vorteil (informativ)'),
                Text(currencyFormat.format(car.monthlyBenefitInKind)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Eigenanteil / Monat'),
                Text(currencyFormat.format(car.monthlyEmployeeContribution)),
              ],
            ),
            if (car.notes != null) ...[
              const SizedBox(height: 4),
              Text(car.notes!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
            if (car.monthlyEmployeeContribution > 0) ...[
              const SizedBox(height: 8),
              if (hasFirmenwagenSubcategory)
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text('Eigenanteil für ${monthYearFormat.format(month)} erfassen'),
                    onPressed: () async {
                      final transaction = Transaction(
                        id: const Uuid().v4(),
                        date: DateTime(month.year, month.month, 1),
                        amount: -car.monthlyEmployeeContribution,
                        description: 'Firmenwagen Eigenanteil - ${car.name}',
                        categoryId: _firmenwagenCategoryId,
                        subcategoryId: _firmenwagenSubcategoryId,
                        isRecurring: true,
                        personId: car.personId,
                      );
                      await ref.read(transactionNotifierProvider.notifier).upsert(transaction);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Eigenanteil als Buchung erfasst.')),
                        );
                      }
                    },
                  ),
                )
              else
                const Text(
                  'Kategorie "Mobilität → Firmenwagen" wurde gelöscht/umbenannt - bitte in den '
                  'Kategorien wiederherstellen, um den Eigenanteil hier direkt erfassen zu können.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
