import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/account_providers.dart';
import '../providers/category_providers.dart';
import '../providers/person_providers.dart';
import '../providers/transaction_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';

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
  String? _accountId;

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
    _accountId = existing?.accountId;
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
    final accounts = ref.watch(accountNotifierProvider);
    final relevantCategories = categories
        .where((c) => c.id != 'umbuchung' && c.type == (_isIncome ? CategoryType.income : CategoryType.expense))
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
              icon: Icon(CupertinoIcons.trash, color: context.appleColors.danger),
              onPressed: () async {
                await ref.read(transactionNotifierProvider.notifier).remove(widget.existing!.id);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          TextButton(onPressed: _save, child: const Text('Sichern')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Ausgabe'), icon: Icon(CupertinoIcons.arrow_up)),
                  ButtonSegment(value: true, label: Text('Einnahme'), icon: Icon(CupertinoIcons.arrow_down)),
                ],
                selected: {_isIncome},
                onSelectionChanged: (s) => setState(() {
                  _isIncome = s.first;
                  _categoryId = null;
                  _subcategoryId = null;
                }),
              ),
            ),
            const AppleSectionHeader('Details'),
            AppleGroupedSection(
              children: [
                ListTile(
                  title: const Text('Datum'),
                  subtitle: Text(dateFormat.format(_date)),
                  trailing: const Icon(CupertinoIcons.calendar_today),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Beschreibung', filled: false, border: InputBorder.none),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bitte angeben' : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Betrag (€)', prefixText: '€ ', filled: false, border: InputBorder.none),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Bitte angeben';
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) return 'Ungültiger Betrag';
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Kategorie', filled: false, border: InputBorder.none),
                    items: relevantCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) => setState(() {
                      _categoryId = v;
                      _subcategoryId = null;
                    }),
                    validator: (v) => v == null ? 'Bitte wählen' : null,
                  ),
                ),
                if (subcategories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: DropdownButtonFormField<String>(
                      initialValue: _subcategoryId,
                      decoration: const InputDecoration(labelText: 'Unterkategorie (optional)', filled: false, border: InputBorder.none),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ...subcategories.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (v) => setState(() => _subcategoryId = v),
                    ),
                  ),
                if (persons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: DropdownButtonFormField<String>(
                      initialValue: _personId,
                      decoration: const InputDecoration(labelText: 'Person', filled: false, border: InputBorder.none),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Gemeinsam')),
                        ...persons.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                      ],
                      onChanged: (v) => setState(() => _personId = v),
                    ),
                  ),
                if (accounts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: DropdownButtonFormField<String>(
                      initialValue: _accountId,
                      decoration: const InputDecoration(labelText: 'Konto (optional)', filled: false, border: InputBorder.none),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ...accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                      ],
                      onChanged: (v) => setState(() => _accountId = v),
                    ),
                  ),
              ],
            ),
            const AppleSectionHeader('Wiederholung'),
            AppleGroupedSection(
              children: [
                SwitchListTile(
                  title: const Text('Wiederkehrend (z. B. Abo)'),
                  value: _isRecurring,
                  onChanged: (v) => setState(() => _isRecurring = v),
                ),
              ],
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
      accountId: _accountId,
    );

    await ref.read(transactionNotifierProvider.notifier).upsert(transaction);
    if (mounted) Navigator.of(context).pop();
  }
}
