import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/import_batch.dart';
import '../models/salary_slip.dart';
import '../models/transaction.dart';
import '../providers/category_providers.dart';
import '../providers/import_batch_providers.dart';
import '../providers/person_providers.dart';
import '../providers/salary_slip_providers.dart';
import '../providers/transaction_providers.dart';
import '../services/categorization_service.dart';
import '../services/salary_duplicate_detection_service.dart';
import '../services/salary_slip_parser_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';

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

    // A PDF re-import (existing != null *and* prefill != null, i.e. a slip
    // for this Abrechnungsmonat was already saved) should show the freshly
    // parsed numbers, not the stale ones already on disk - prefill wins.
    _period = prefill?.period ?? existing?.period ?? DateTime(now.year, now.month);
    _grossController = TextEditingController(text: _fmt(prefill?.gross ?? existing?.gross));
    _netController = TextEditingController(text: _fmt(prefill?.net ?? existing?.net));
    _incomeTaxController = TextEditingController(text: _fmt(prefill?.incomeTax ?? existing?.incomeTax));
    _socialSecurityController = TextEditingController(text: _fmt(prefill?.socialSecurity ?? existing?.socialSecurity));
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
              icon: Icon(CupertinoIcons.trash, color: context.appleColors.danger),
              onPressed: () async {
                final existing = widget.existing!;
                if (existing.linkedTransactionId != null) {
                  await ref.read(transactionNotifierProvider.notifier).remove(existing.linkedTransactionId!);
                }
                await ref.read(salarySlipNotifierProvider.notifier).remove(existing.id);
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
            if (widget.prefill != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  widget.existing != null
                      ? 'Für ${monthYearFormat.format(_period)} gibt es bereits eine Abrechnung - sie wird beim Speichern mit diesen Werten aktualisiert statt doppelt angelegt.'
                      : 'Aus PDF erkannt - bitte alle Werte prüfen, bevor du speicherst.',
                  style: TextStyle(color: widget.existing != null ? context.appleColors.warning : context.appleColors.secondaryLabel),
                ),
              ),
            const AppleSectionHeader('Zeitraum', padding: EdgeInsets.fromLTRB(20, 0, 20, 6)),
            AppleGroupedSection(
              children: [
                ListTile(
                  title: const Text('Abrechnungsmonat'),
                  subtitle: Text(monthYearFormat.format(_period)),
                  trailing: const Icon(CupertinoIcons.calendar),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextFormField(
                    controller: _employerController,
                    decoration: const InputDecoration(labelText: 'Arbeitgeber (optional)', filled: false, border: InputBorder.none),
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
              ],
            ),
            const AppleSectionHeader('Beträge'),
            AppleGroupedSection(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextFormField(
                    controller: _grossController,
                    decoration: const InputDecoration(labelText: 'Brutto (€)', filled: false, border: InputBorder.none),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) <= 0 ? 'Bitte angeben' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextFormField(
                    controller: _netController,
                    decoration: const InputDecoration(labelText: 'Netto / Auszahlungsbetrag (€)', filled: false, border: InputBorder.none),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) <= 0 ? 'Bitte angeben' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextFormField(
                    controller: _incomeTaxController,
                    decoration: const InputDecoration(labelText: 'Steuern (Lohnsteuer, Soli, Kirchensteuer) (€)', filled: false, border: InputBorder.none),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextFormField(
                    controller: _socialSecurityController,
                    decoration: const InputDecoration(labelText: 'Sozialversicherung (KV/RV/AV/PV) (€)', filled: false, border: InputBorder.none),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                ListTile(
                  title: const Text('Sonstige Abzüge (berechnet)'),
                  subtitle: const Text('Brutto − Netto − Steuern − Sozialversicherung'),
                  trailing: Text(currencyFormat.format(otherDeductions)),
                ),
              ],
            ),
            const AppleSectionHeader('Buchung'),
            AppleGroupedSection(
              children: [
                SwitchListTile(
                  title: const Text('Auch als Einnahme in Buchungen erfassen'),
                  subtitle: const Text('Legt/aktualisiert eine Buchung über den Netto-Betrag im Monat der Abrechnung.'),
                  value: _createTransaction,
                  onChanged: (v) => setState(() => _createTransaction = v),
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
    var createTransaction = _createTransaction;

    // Only relevant when a transaction would be newly created - if one is
    // already linked, this save is just updating it in place, not adding a
    // second booking.
    if (createTransaction && slip.linkedTransactionId == null) {
      final match = findLikelyMatchingIncome(date: slip.period, amount: slip.net, existing: ref.read(transactionNotifierProvider));
      if (match != null) {
        final takeOver = await _confirmDuplicateIncome(match);
        if (!mounted) return;
        createTransaction = takeOver;
      }
    }

    if (createTransaction) {
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

    // Only a brand-new import (not a manual entry, and not a re-import that
    // updated an already-existing slip in place) gets its own undo-able
    // history entry - an in-place update doesn't cleanly "undo" back to a
    // single prior state, so it's left out of the history for now.
    if (widget.prefill != null && widget.existing == null) {
      await ref.read(importBatchNotifierProvider.notifier).add(ImportBatch(
            id: const Uuid().v4(),
            timestamp: DateTime.now(),
            source: ImportSource.gehalt,
            label: 'Gehaltsabrechnung ${monthYearFormat.format(slip.period)}',
            salarySlipIds: [slip.id],
            transactionIds: slip.linkedTransactionId != null ? [slip.linkedTransactionId!] : [],
          ));
    }

    if (mounted) Navigator.of(context).pop();
  }

  /// Asks whether to still create the Gehalt-linked transaction even though
  /// [match] - an existing income transaction in the same month with a
  /// similar amount, most likely picked up via a Kontoauszug-Import - looks
  /// like it could be the same payment.
  Future<bool> _confirmDuplicateIncome(Transaction match) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mögliches Duplikat'),
        content: Text(
          'Im selben Monat existiert bereits eine ähnliche Einnahme-Buchung (vermutlich aus einem '
          'Kontoauszug-Import): "${match.description}" über ${currencyFormat.format(match.amount)} am '
          '${dateFormat.format(match.date)}.\n\nTrotzdem eine zusätzliche Gehalt-Buchung anlegen?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Nicht übernehmen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Übernehmen')),
        ],
      ),
    );
    return result ?? false;
  }
}
