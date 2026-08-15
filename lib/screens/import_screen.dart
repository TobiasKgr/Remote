import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/person.dart';
import '../models/transaction.dart';
import '../providers/account_providers.dart';
import '../providers/category_providers.dart';
import '../providers/person_providers.dart';
import '../providers/transaction_providers.dart';
import '../services/categorization_service.dart';
import '../services/pdf_import_service.dart' show PdfImportService, ParsedTransaction;
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';

class _DraftRow {
  _DraftRow({required this.date, required String description, required double amount, this.ambiguous = false})
      : descriptionController = TextEditingController(text: description),
        amountController = TextEditingController(text: amount.abs().toStringAsFixed(2)),
        isIncome = amount >= 0;

  bool selected = true;
  final DateTime date;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  bool isIncome;
  bool ambiguous;
  String? categoryId;
  String? subcategoryId;
  String? personId;
  String? accountId;
}

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _pdfImportService = PdfImportService();
  List<_DraftRow> _drafts = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final d in _drafts) {
      d.descriptionController.dispose();
      d.amountController.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndParse() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final categories = ref.read(categoryNotifierProvider);
      final history = ref.read(transactionNotifierProvider);
      final categorizer = CategorizationService(categories, history: history);

      final drafts = <_DraftRow>[];
      final failedFiles = <String>[];
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null) {
          failedFiles.add(file.name);
          continue;
        }
        List<ParsedTransaction> parsed;
        try {
          parsed = await _pdfImportService.importFromBytes(bytes);
        } catch (_) {
          failedFiles.add(file.name);
          continue;
        }
        if (parsed.isEmpty) {
          failedFiles.add(file.name);
          continue;
        }
        for (final p in parsed) {
          final draft = _DraftRow(date: p.date, description: p.description, amount: p.amount, ambiguous: p.amountAmbiguous);
          final match = categorizer.suggest(p.description);
          draft.categoryId = match?.categoryId ?? categorizer.fallbackCategoryId(p.amount >= 0);
          draft.subcategoryId = match?.subcategoryId;
          drafts.add(draft);
        }
      }

      setState(() {
        _drafts = drafts;
        _loading = false;
        if (failedFiles.isEmpty) {
          _error = null;
        } else if (drafts.isEmpty) {
          _error = 'Es konnten keine Buchungen aus ${failedFiles.length == 1 ? "der PDF-Datei" : "den PDF-Dateien"} erkannt werden '
              '(${failedFiles.join(", ")}). Das PDF-Format dieser Bank wird evtl. noch nicht unterstützt.';
        } else {
          _error = 'Bei ${failedFiles.length} von ${result.files.length} Dateien konnten keine Buchungen erkannt werden: '
              '${failedFiles.join(", ")}.';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Fehler beim Einlesen der PDF-Datei(en): $e';
      });
    }
  }

  Future<void> _saveSelected() async {
    final categories = ref.read(categoryNotifierProvider);
    final validCategoryIds = categories.map((c) => c.id).toSet();

    final transactions = <Transaction>[];
    for (final d in _drafts) {
      if (!d.selected) continue;
      if (d.categoryId == null || !validCategoryIds.contains(d.categoryId)) continue;
      final magnitude = double.tryParse(d.amountController.text.replaceAll(',', '.')) ?? 0;
      transactions.add(Transaction(
        id: const Uuid().v4(),
        date: d.date,
        amount: d.isIncome ? magnitude : -magnitude,
        description: d.descriptionController.text.trim(),
        categoryId: d.categoryId!,
        subcategoryId: d.subcategoryId,
        source: TransactionSource.pdfImport,
        personId: d.personId,
        accountId: d.accountId,
      ));
    }

    await ref.read(transactionNotifierProvider.notifier).upsertAll(transactions);

    if (!mounted) return;
    for (final d in _drafts) {
      d.descriptionController.dispose();
      d.amountController.dispose();
    }
    setState(() => _drafts = []);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${transactions.length} Buchungen importiert.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryNotifierProvider);
    final persons = ref.watch(personNotifierProvider);
    final accounts = ref.watch(accountNotifierProvider);
    final selectedCount = _drafts.where((d) => d.selected).length;

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          if (_drafts.isNotEmpty)
            TextButton(
              onPressed: selectedCount == 0 ? null : _saveSelected,
              child: Text('Speichern ($selectedCount)'),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _drafts.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: _drafts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return const AppleLargeTitle('PDF-Import');
                      return _buildDraftCard(context, _drafts[index - 1], categories, persons, accounts);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.appleColors;
    return ListView(
      children: [
        const AppleLargeTitle('PDF-Import'),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              Icon(CupertinoIcons.doc_text, size: 64, color: colors.secondaryLabel),
              const SizedBox(height: 16),
              Text(
                'Kontoauszug als PDF importieren',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Es können mehrere PDF-Dateien auf einmal ausgewählt werden. '
                'Die Erkennung ist eine Heuristik für gängige deutsche Kontoauszug-Layouts. '
                'Bitte alle erkannten Buchungen vor dem Speichern prüfen.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: colors.danger)),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _pickAndParse,
                icon: const Icon(CupertinoIcons.arrow_up_doc_fill),
                label: const Text('PDF auswählen'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDraftCard(
    BuildContext context,
    _DraftRow draft,
    List<Category> categories,
    List<Person> persons,
    List<Account> accounts,
  ) {
    final relevantCategories =
        categories.where((c) => c.id != 'umbuchung' && c.type == (draft.isIncome ? CategoryType.income : CategoryType.expense)).toList();
    final matchingCategory = relevantCategories.where((c) => c.id == draft.categoryId).toList();
    final subcategories = matchingCategory.isNotEmpty ? matchingCategory.first.subcategories : <Subcategory>[];
    if (draft.categoryId != null && matchingCategory.isEmpty && relevantCategories.isNotEmpty) {
      draft.categoryId = relevantCategories.first.id;
      draft.subcategoryId = null;
    }

    final colors = context.appleColors;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      color: draft.ambiguous ? colors.warning.withValues(alpha: 0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(value: draft.selected, onChanged: (v) => setState(() => draft.selected = v ?? true)),
                Text(dateFormat.format(draft.date)),
                const Spacer(),
                if (draft.ambiguous)
                  Tooltip(
                    message: 'Vorzeichen (Einnahme/Ausgabe) konnte nicht sicher erkannt werden - bitte prüfen.',
                    child: Icon(CupertinoIcons.exclamationmark_triangle, color: colors.warning, size: 20),
                  ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Ausgabe'),
                  selected: !draft.isIncome,
                  onSelected: (_) => setState(() {
                    draft.isIncome = false;
                    draft.categoryId = null;
                  }),
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('Einnahme'),
                  selected: draft.isIncome,
                  onSelected: (_) => setState(() {
                    draft.isIncome = true;
                    draft.categoryId = null;
                  }),
                ),
              ],
            ),
            TextField(
              controller: draft.descriptionController,
              decoration: const InputDecoration(labelText: 'Beschreibung'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: draft.amountController,
                    decoration: const InputDecoration(labelText: 'Betrag (€)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: relevantCategories.any((c) => c.id == draft.categoryId) ? draft.categoryId : null,
                    decoration: const InputDecoration(labelText: 'Kategorie'),
                    items: relevantCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) => setState(() {
                      draft.categoryId = v;
                      draft.subcategoryId = null;
                    }),
                  ),
                ),
              ],
            ),
            if (subcategories.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: subcategories.any((s) => s.id == draft.subcategoryId) ? draft.subcategoryId : null,
                decoration: const InputDecoration(labelText: 'Unterkategorie (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  ...subcategories.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                ],
                onChanged: (v) => setState(() => draft.subcategoryId = v),
              ),
            if (persons.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: persons.any((p) => p.id == draft.personId) ? draft.personId : null,
                decoration: const InputDecoration(labelText: 'Person'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Gemeinsam')),
                  ...persons.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                ],
                onChanged: (v) => setState(() => draft.personId = v),
              ),
            if (accounts.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: accounts.any((a) => a.id == draft.accountId) ? draft.accountId : null,
                decoration: const InputDecoration(labelText: 'Konto (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  ...accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                ],
                onChanged: (v) => setState(() => draft.accountId = v),
              ),
          ],
        ),
      ),
    );
  }
}
