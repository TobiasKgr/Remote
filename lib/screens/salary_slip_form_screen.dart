import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/salary_slip.dart';
import '../models/transaction.dart';
import '../providers/category_providers.dart';
import '../providers/person_providers.dart';
import '../providers/salary_slip_providers.dart';
import '../providers/transaction_providers.dart';
import '../services/categorization_service.dart';
import '../services/salary_slip_parser_service.dart';
import '../utils/formatters.dart';

class SalarySlipFormScreen extends ConsumerStatefulWidget {
  const SalarySlipFormScreen({super.key, this.existing, this.prefill});

  final SalarySlip? existing;

  /// Pre-fills the form right after a PDF was parsed, still awaiting review.
  final SalarySlipParseResult? prefill;

  @override
  ConsumerState<SalarySlipFormScreen> createState() => _SalarySlipFormScreenState();
}

class _SalarySlipFormScreenState extends ConsumerState<SalarySlipFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _period;
  late TextEditingController _grossController;
  late TextEditingController _netController;
  late TextEditingController _incomeTaxController;
  late TextEditingController _socialSecurityController;
  late TextEditingController _employerController;
  bool _createTransaction = true;
  String? _personId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final prefill = widget.prefill;
    final now = DateTime.now();

    _period = existing?.period ?? prefill?.period ?? DateTime(now.year, now.month);
    _grossController = TextEditingController(text: _fmt(existing?.gross ?? prefill?.gross));
    _netController = TextEditingController(text: _fmt(existing?.net ?? prefill?.net));
    _incomeTaxController = TextEditingController(text: _fmt(existing?.incomeTax ?? prefill?.incomeTax));
    _socialSecurityController = TextEditingController(text: _fmt(existing?.socialSecurity ?? prefill?.socialSecurity));
    _employerController = TextEditingController(text: existing?.employer ?? '');
    _createTransaction = existing == null || existing.linkedTransactionId != null;
    _personId = existing?.personId;
  }

  String _fmt(double? value) => value == null || value == 0 ? '' : value.toStringAsFixed(2);

  @override
  void dispose() {
    _grossController.dispose();
    _netController.dispose();
    _incomeTaxController.dispose();
    _socialSecurityController.dispose();
    _employerController.dispose();
    super.dispose();
  }

  double _parse(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final persons = ref.watch(personNotifierProvider);
    final gross = _parse(_grossController);
    final net = _parse(_netController);
    final incomeTax = _parse(_incomeTaxController);
    final socialSecurity = _parse(_socialSecurityController);
    final otherDeductions = (gross - net - incomeTax - socialSecurity).clamp(0, double.infinity).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Neue Gehaltsabrechnung' : 'Gehaltsabrechnung bearbeiten'),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final existing = widget.existing!;
                if (existing.linkedTransactionId != null) {
                  await ref.read(transactionNotifierProvider.notifier).remove(existing.linkedTransactionId!);
                }
                await ref.read(salarySlipNotifierProvider.notifier).remove(existing.id);
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
            if (widget.prefill != null)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Aus PDF erkannt - bitte alle Werte prüfen, bevor du speicherst.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Abrechnungsmonat'),
              subtitle: Text(monthYearFormat.format(_period)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _period,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (picked != null) setState(() => _period = DateTime(picked.year, picked.month));
              },
            ),
            TextFormField(
              controller: _employerController,
              decoration: const InputDecoration(labelText: 'Arbeitgeber (optional)'),
            ),
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
            TextFormField(
              controller: _grossController,
              decoration: const InputDecoration(labelText: 'Brutto (€)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) <= 0 ? 'Bitte angeben' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _netController,
              decoration: const InputDecoration(labelText: 'Netto / Auszahlungsbetrag (€)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) <= 0 ? 'Bitte angeben' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _incomeTaxController,
              decoration: const InputDecoration(labelText: 'Steuern (Lohnsteuer, Soli, Kirchensteuer) (€)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _socialSecurityController,
              decoration: const InputDecoration(labelText: 'Sozialversicherung (KV/RV/AV/PV) (€)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sonstige Abzüge (berechnet)'),
              subtitle: const Text('Brutto − Netto − Steuern − Sozialversicherung'),
              trailing: Text(currencyFormat.format(otherDeductions)),
            ),
            const Divider(height: 32),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auch als Einnahme in Buchungen erfassen'),
              subtitle: const Text('Legt/aktualisiert eine Buchung über den Netto-Betrag im Monat der Abrechnung.'),
              value: _createTransaction,
              onChanged: (v) => setState(() => _createTransaction = v),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final gross = _parse(_grossController);
    final net = _parse(_netController);
    final incomeTax = _parse(_incomeTaxController);
    final socialSecurity = _parse(_socialSecurityController);
    final otherDeductions = (gross - net - incomeTax - socialSecurity).clamp(0, double.infinity).toDouble();

    final slip = SalarySlip(
      id: widget.existing?.id ?? const Uuid().v4(),
      period: _period,
      gross: gross,
      net: net,
      incomeTax: incomeTax,
      socialSecurity: socialSecurity,
      otherDeductions: otherDeductions,
      employer: _employerController.text.trim().isEmpty ? null : _employerController.text.trim(),
      linkedTransactionId: widget.existing?.linkedTransactionId,
      personId: _personId,
    );

    final txNotifier = ref.read(transactionNotifierProvider.notifier);

    if (_createTransaction) {
      final categories = ref.read(categoryNotifierProvider);
      final match = CategorizationService(categories).suggest('gehalt');
      final categoryId = match?.categoryId ?? CategorizationService(categories).fallbackCategoryId(true);
      final subcategoryId = match?.subcategoryId;

      final transaction = Transaction(
        id: slip.linkedTransactionId ?? const Uuid().v4(),
        date: slip.period,
        amount: slip.net,
        description: slip.employer != null ? 'Gehalt ${slip.employer}' : 'Gehalt',
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        source: TransactionSource.manual,
        personId: slip.personId,
      );
      await txNotifier.upsert(transaction);
      slip.linkedTransactionId = transaction.id;
    } else if (slip.linkedTransactionId != null) {
      await txNotifier.remove(slip.linkedTransactionId!);
      slip.linkedTransactionId = null;
    }

    await ref.read(salarySlipNotifierProvider.notifier).upsert(slip);
    if (mounted) Navigator.of(context).pop();
  }
}
