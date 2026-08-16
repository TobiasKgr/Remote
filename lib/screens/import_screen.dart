import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/import_batch.dart';
import '../models/person.dart';
import '../models/transaction.dart';
import '../providers/account_providers.dart';
import '../providers/category_providers.dart';
import '../providers/custom_import_profile_providers.dart';
import '../providers/import_batch_providers.dart';
import '../providers/person_providers.dart';
import '../providers/transaction_providers.dart';
import '../providers/salary_slip_providers.dart';
import '../services/categorization_service.dart';
import '../services/duplicate_detection_service.dart';
import '../services/pdf_import_service.dart' show PdfImportService, PdfImportResult;
import '../services/recurring_payment_detector.dart';
import '../services/salary_duplicate_detection_service.dart';
import '../theme/app_theme.dart';
import '../utils/description_normalizer.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';
import 'format_assistant_screen.dart';
import 'recurring_payments_screen.dart';

class _DraftRow {
  _DraftRow({
    required this.date,
    required String description,
    required double amount,
    this.ambiguous = false,
    this.isDuplicate = false,
    this.matchedSalaryTransaction,
  })  : descriptionController = TextEditingController(text: description),
        amountController = TextEditingController(text: amount.abs().toStringAsFixed(2)),
        isIncome = amount >= 0,
        selected = !isDuplicate && matchedSalaryTransaction == null;

  bool selected;
  final DateTime date;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  bool isIncome;
  bool ambiguous;

  /// True when a booking with the same date, amount and description
  /// already exists (either already saved, or earlier in this same
  /// picked batch) - pre-unchecked so it isn't booked twice by accident,
  /// but still shown and editable in case it's a legitimate repeat charge.
  bool isDuplicate;

  /// Set when this booking looks like it could be the same payment as an
  /// existing Gehaltsabrechnung-linked transaction (same month, similar
  /// amount) - the user is asked to confirm whether to take it over anyway
  /// right after parsing; pre-unchecked until answered.
  Transaction? matchedSalaryTransaction;

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
  bool _dragHighlighted = false;

  /// One entry per file whose "Anfangssaldo + Buchungen" didn't add up to
  /// its own "Endsaldo" - shown as a non-blocking warning, since it means
  /// a booking was likely missed rather than the import being unusable.
  List<String> _balanceWarnings = [];

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
      _balanceWarnings = [];
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

      final files = <(String, Uint8List?)>[for (final f in result.files) (f.name, f.bytes)];
      await _parseFiles(files, totalPicked: result.files.length);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Fehler beim Einlesen der PDF-Datei(en): $e';
      });
    }
  }

  /// Handles PDFs dropped onto the screen (desktop/web drag & drop) - reads
  /// each dropped file's bytes and feeds them through the same parsing path
  /// as the file picker.
  Future<void> _handleDroppedFiles(DropDoneDetails details) async {
    final pdfFiles = details.files.where((f) => f.name.toLowerCase().endsWith('.pdf')).toList();
    if (pdfFiles.isEmpty) {
      setState(() => _error = 'Nur PDF-Dateien werden unterstützt.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _balanceWarnings = [];
    });
    try {
      final files = <(String, Uint8List?)>[for (final f in pdfFiles) (f.name, await f.readAsBytes())];
      await _parseFiles(files, totalPicked: pdfFiles.length);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Fehler beim Einlesen der PDF-Datei(en): $e';
      });
    }
  }

  Future<void> _parseFiles(List<(String name, Uint8List? bytes)> files, {required int totalPicked}) async {
    final categories = ref.read(categoryNotifierProvider);
    final history = ref.read(transactionNotifierProvider);
    final categorizer = CategorizationService(categories, history: history);
    final customProfiles = ref.read(customImportProfileNotifierProvider);

    // Existing bookings that came from a Gehaltsabrechnung-Import - checked
    // against so a salary payment that also shows up on the Kontoauszug
    // isn't silently counted twice.
    final salaryLinkedIds = ref.read(salarySlipNotifierProvider).map((s) => s.linkedTransactionId).whereType<String>().toSet();
    final salaryLinkedTransactions = history.where((t) => salaryLinkedIds.contains(t.id)).toList();

    // Checked against as each new draft is produced, so duplicates are
    // caught both against already-saved bookings and against earlier
    // rows within this same picked batch (e.g. two files whose date
    // ranges overlap).
    final seenSoFar = <Transaction>[...history];

    final drafts = <_DraftRow>[];
    final failedFiles = <String>[];
    final balanceWarnings = <String>[];
    for (final (name, bytes) in files) {
      if (bytes == null) {
        failedFiles.add(name);
        continue;
      }
      PdfImportResult importResult;
      try {
        importResult = await _pdfImportService.importFromBytesWithBalanceCheck(bytes, customProfiles: customProfiles);
      } catch (_) {
        failedFiles.add(name);
        continue;
      }
      final parsed = importResult.transactions;
      if (parsed.isEmpty) {
        failedFiles.add(name);
        continue;
      }
      if (importResult.hasBalanceMismatch) {
        final diff = importResult.balanceDifference!;
        balanceWarnings.add(
          '$name: Differenz von ${currencyFormat.format(diff.abs())} zwischen erkannten Buchungen und '
          'Endsaldo - bitte Import prüfen.',
        );
      }
      for (final p in parsed) {
        final isDuplicate = isDuplicateBooking(date: p.date, amount: p.amount, description: p.description, existing: seenSoFar);
        final salaryMatch =
            isDuplicate ? null : findLikelyMatchingIncome(date: p.date, amount: p.amount, existing: salaryLinkedTransactions);
        final draft = _DraftRow(
          date: p.date,
          description: p.description,
          amount: p.amount,
          ambiguous: p.amountAmbiguous,
          isDuplicate: isDuplicate,
          matchedSalaryTransaction: salaryMatch,
        );
        final match = categorizer.suggest(p.description);
        draft.categoryId = match?.categoryId ?? categorizer.fallbackCategoryId(p.amount >= 0);
        draft.subcategoryId = match?.subcategoryId;
        drafts.add(draft);
        seenSoFar.add(Transaction(id: 'seen', date: p.date, amount: p.amount, description: p.description, categoryId: 'sonstiges'));
      }
    }

    setState(() {
      _drafts = drafts;
      _loading = false;
      _balanceWarnings = balanceWarnings;
      if (failedFiles.isEmpty) {
        _error = null;
      } else if (drafts.isEmpty) {
        _error = 'Es konnten keine Buchungen aus ${failedFiles.length == 1 ? "der PDF-Datei" : "den PDF-Dateien"} erkannt werden '
            '(${failedFiles.join(", ")}). Das PDF-Format dieser Bank wird evtl. noch nicht unterstützt.';
      } else {
        _error = 'Bei ${failedFiles.length} von $totalPicked Dateien konnten keine Buchungen erkannt werden: '
            '${failedFiles.join(", ")}.';
      }
    });

    // Asked one at a time, right after parsing, so the decision is made
    // with the Gehaltsabrechnung still in mind rather than buried in a
    // passive banner among dozens of other rows.
    for (final draft in drafts) {
      final match = draft.matchedSalaryTransaction;
      if (match == null) continue;
      if (!mounted) return;
      final takeOver = await _confirmSalaryDuplicate(draft, match);
      if (!mounted) return;
      setState(() => draft.selected = takeOver);
    }
  }

  /// Asks whether to still take over [draft] even though [match] - an
  /// existing Gehaltsabrechnung-linked booking in the same month with a
  /// similar amount - looks like it could be the same payment.
  Future<bool> _confirmSalaryDuplicate(_DraftRow draft, Transaction match) async {
    final amount = double.tryParse(draft.amountController.text.replaceAll(',', '.')) ?? 0;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mögliches Gehalts-Duplikat'),
        content: Text(
          'Die Buchung "${draft.descriptionController.text}" über ${currencyFormat.format(amount)} am '
          '${dateFormat.format(draft.date)} ähnelt einer bereits erfassten Gehaltsabrechnung: "${match.description}" über '
          '${currencyFormat.format(match.amount)} am ${dateFormat.format(match.date)}.\n\nTrotzdem übernehmen?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Nicht übernehmen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Übernehmen')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _saveSelected() async {
    // Snapshot which recurring-payment series already existed *before* this
    // import, so a series that only now crosses the detector's occurrence
    // threshold can be pointed out afterwards instead of silently sitting
    // in "Abos & Verträge" until the user happens to check.
    final beforeRecurringKeys = const RecurringPaymentDetector()
        .detect(ref.read(transactionNotifierProvider))
        .map((g) => normalizeDescription(g.description))
        .toSet();

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

    if (transactions.isNotEmpty) {
      await ref.read(importBatchNotifierProvider.notifier).add(ImportBatch(
            id: const Uuid().v4(),
            timestamp: DateTime.now(),
            source: ImportSource.kontoauszug,
            label: '${transactions.length} Buchungen importiert',
            transactionIds: transactions.map((t) => t.id).toList(),
          ));
    }

    if (!mounted) return;
    for (final d in _drafts) {
      d.descriptionController.dispose();
      d.amountController.dispose();
    }
    setState(() {
      _drafts = [];
      _balanceWarnings = [];
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text('${transactions.length} Buchungen importiert.')));

    final newRecurringGroups = const RecurringPaymentDetector()
        .detect(ref.read(transactionNotifierProvider))
        .where((g) => !beforeRecurringKeys.contains(normalizeDescription(g.description)))
        .toList();
    if (newRecurringGroups.isNotEmpty) {
      final names = newRecurringGroups.map((g) => g.description).join(', ');
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(
          '${newRecurringGroups.length} neue${newRecurringGroups.length == 1 ? "s" : ""} '
          'potenzielle${newRecurringGroups.length == 1 ? "s" : ""} '
          '${newRecurringGroups.length == 1 ? "Abo" : "Abos"} erkannt: $names',
        ),
        action: SnackBarAction(
          label: 'Anzeigen',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecurringPaymentsScreen())),
        ),
      ));
    }
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
        child: DropTarget(
          onDragEntered: (_) => setState(() => _dragHighlighted = true),
          onDragExited: (_) => setState(() => _dragHighlighted = false),
          onDragDone: (details) {
            setState(() => _dragHighlighted = false);
            _handleDroppedFiles(details);
          },
          child: Stack(
            children: [
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _drafts.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: _drafts.length + 1 + (_balanceWarnings.isEmpty ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (index == 0) return const AppleLargeTitle('PDF-Import');
                            if (_balanceWarnings.isNotEmpty) {
                              if (index == 1) return _buildBalanceWarningBanner(context);
                              return _buildDraftCard(context, _drafts[index - 2], categories, persons, accounts);
                            }
                            return _buildDraftCard(context, _drafts[index - 1], categories, persons, accounts);
                          },
                        ),
              if (_dragHighlighted) _buildDragOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragOverlay(BuildContext context) {
    final colors = context.appleColors;
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: AppleColors.blue.withValues(alpha: 0.12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(color: colors.secondaryGroupedBackground, borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.arrow_down_doc_fill, size: 40, color: AppleColors.blue),
                  const SizedBox(height: 8),
                  const Text('PDF(s) hier ablegen', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceWarningBanner(BuildContext context) {
    final colors = context.appleColors;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      color: colors.warning.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.exclamationmark_triangle_fill, color: colors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Achtung: Saldo-Abgleich zeigt eine Abweichung - Import als unsicher markiert',
                    style: TextStyle(color: colors.warning, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final warning in _balanceWarnings)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(warning, style: TextStyle(color: colors.warning)),
              ),
          ],
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
                'Es können mehrere PDF-Dateien auf einmal ausgewählt oder per Drag & Drop hierher gezogen werden. '
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
              if (_error != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FormatAssistantScreen())),
                  icon: const Icon(CupertinoIcons.wand_stars),
                  label: const Text('Format anlernen'),
                ),
              ],
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
    final flagged = draft.isDuplicate || draft.matchedSalaryTransaction != null;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      color: flagged ? colors.warning.withValues(alpha: 0.15) : (draft.ambiguous ? colors.warning.withValues(alpha: 0.1) : null),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (draft.isDuplicate)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.exclamationmark_triangle_fill, color: colors.warning, size: 16),
                    const SizedBox(width: 6),
                    Text('Bereits vorhanden - vermutlich Duplikat', style: TextStyle(color: colors.warning, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            if (draft.matchedSalaryTransaction != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.exclamationmark_triangle_fill, color: colors.warning, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ähnelt Gehaltsabrechnung "${draft.matchedSalaryTransaction!.description}" - Antwort auf die Rückfrage bestimmt die Auswahl.',
                        style: TextStyle(color: colors.warning, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
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
