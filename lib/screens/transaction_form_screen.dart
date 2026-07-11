import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/category_providers.dart';
import '../providers/person_providers.dart';
import '../providers/transaction_providers.dart';
import '../utils/formatters.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.existing});

  final Transaction? existing;

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  bool _isIncome = false;
  bool _isRecurring = false;
  String? _categoryId;
  String? _subcategoryId;
  String? _personId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _date = existing?.date ?? DateTime.now();
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _amountController = TextEditingController(text: existing != null ? existing.amount.abs().toStringAsFixed(2) : '');
    _isIncome = existing?.isIncome ?? false;
    _isRecurring = existing?.isRecurring ?? false;
    _categoryId = existing?.categoryId;
    _subcategoryId = existing?.subcategoryId;
    _personId = existing?.personId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryNotifierProvider);
    final persons = ref.watch(personNotifierProvider);
    final relevantCategories = categories
        .where((c) => c.type == (_isIncome ? CategoryType.income : CategoryType.expense))
        .toList();
    if (_categoryId != null && !relevantCategories.any((c) => c.id == _categoryId)) {
      _categoryId = null;
      _subcategoryId = null;
    }
    final selectedCategory = relevantCategories.where((c) => c.id == _categoryId).toList();
    final subcategories = selectedCategory.isNotEmpty ? selectedCategory.first.subcategories : <Subcategory>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Neue Buchung' : 'Buchung bearbeiten'),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ref.read(transactionNotifierProvider.notifier).remove(widget.existing!.id);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Ausgabe'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: true, label: Text('Einnahme'), icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_isIncome},
              onSelectionChanged: (s) => setState(() {
                _isIncome = s.first;
                _categoryId = null;
                _subcategoryId = null;
              }),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Datum'),
              subtitle: Text(dateFormat.format(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Beschreibung'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bitte angeben' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Betrag (€)', prefixText: '€ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Bitte angeben';
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) return 'Ungültiger Betrag';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Kategorie'),
              items: relevantCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() {
                _categoryId = v;
                _subcategoryId = null;
              }),
              validator: (v) => v == null ? 'Bitte wählen' : null,
            ),
            if (subcategories.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _subcategoryId,
                decoration: const InputDecoration(labelText: 'Unterkategorie (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  ...subcategories.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                ],
                onChanged: (v) => setState(() => _subcategoryId = v),
              ),
            ],
            if (persons.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _personId,
                decoration: const InputDecoration(labelText: 'Person'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Gemeinsam')),
                  ...persons.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                ],
                onChanged: (v) => setState(() => _personId = v),
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Wiederkehrend (z. B. Abo)'),
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final magnitude = double.parse(_amountController.text.replaceAll(',', '.'));
    final signedAmount = _isIncome ? magnitude : -magnitude;

    final transaction = Transaction(
      id: widget.existing?.id ?? const Uuid().v4(),
      date: _date,
      amount: signedAmount,
      description: _descriptionController.text.trim(),
      categoryId: _categoryId!,
      subcategoryId: _subcategoryId,
      source: widget.existing?.source ?? TransactionSource.manual,
      isRecurring: _isRecurring,
      personId: _personId,
    );

    await ref.read(transactionNotifierProvider.notifier).upsert(transaction);
    if (mounted) Navigator.of(context).pop();
  }
}
