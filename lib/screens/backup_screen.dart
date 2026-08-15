import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/account_providers.dart';
import '../providers/asset_providers.dart';
import '../providers/budget_providers.dart';
import '../providers/category_providers.dart';
import '../providers/company_car_providers.dart';
import '../providers/person_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/salary_slip_providers.dart';
import '../providers/transaction_providers.dart';
import '../services/backup_service.dart';
import '../services/file_saver.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_widgets.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final json = BackupService().exportToJsonString(
        categories: ref.read(categoryNotifierProvider),
        transactions: ref.read(transactionNotifierProvider),
        salarySlips: ref.read(salarySlipNotifierProvider),
        persons: ref.read(personNotifierProvider),
        companyCars: ref.read(companyCarNotifierProvider),
        budgets: ref.read(budgetNotifierProvider),
        accounts: ref.read(accountNotifierProvider),
        assets: ref.read(assetNotifierProvider),
      );
      final dateStamp = DateTime.now().toIso8601String().split('T').first;
      final result = await saveTextFile(fileName: 'finanzen_backup_$dateStamp.json', content: json);
      setState(() {
        _busy = false;
        _messageIsError = false;
        _message = result == null ? 'Export abgebrochen.' : 'Backup gespeichert: $result';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _messageIsError = true;
        _message = 'Fehler beim Export: $e';
      });
    }
  }

  Future<void> _import() async {
    setState(() => _message = null);
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
    if (result == null || result.files.isEmpty || result.files.single.bytes == null) return;

    BackupData data;
    try {
      data = BackupService().importFromJsonString(utf8.decode(result.files.single.bytes!));
    } catch (e) {
      setState(() {
        _messageIsError = true;
        _message = 'Ungültige Backup-Datei: $e';
      });
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup importieren?'),
        content: Text(
          'Enthält ${data.transactions.length} Buchungen, ${data.categories.length} Kategorien, '
          '${data.salarySlips.length} Gehaltsabrechnungen, ${data.persons.length} Personen, '
          '${data.companyCars.length} Firmenwagen, ${data.budgets.length} Budgets, '
          '${data.accounts.length} Konten und ${data.assets.length} Vermögenswerte/Kredite.\n\n'
          'Bestehende Einträge mit gleicher ID werden überschrieben, alles andere bleibt erhalten.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Importieren')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);

    for (final c in data.categories) {
      await ref.read(categoryRepositoryProvider).save(c);
    }
    await ref.read(transactionRepositoryProvider).saveAll(data.transactions);
    for (final s in data.salarySlips) {
      await ref.read(salarySlipRepositoryProvider).save(s);
    }
    for (final p in data.persons) {
      await ref.read(personRepositoryProvider).save(p);
    }
    for (final c in data.companyCars) {
      await ref.read(companyCarRepositoryProvider).save(c);
    }
    for (final b in data.budgets) {
      await ref.read(budgetRepositoryProvider).save(b);
    }
    for (final a in data.accounts) {
      await ref.read(accountRepositoryProvider).save(a);
    }
    for (final a in data.assets) {
      await ref.read(assetRepositoryProvider).save(a);
    }

    ref.invalidate(categoryNotifierProvider);
    ref.invalidate(transactionNotifierProvider);
    ref.invalidate(salarySlipNotifierProvider);
    ref.invalidate(personNotifierProvider);
    ref.invalidate(companyCarNotifierProvider);
    ref.invalidate(budgetNotifierProvider);
    ref.invalidate(accountNotifierProvider);
    ref.invalidate(assetNotifierProvider);

    setState(() {
      _busy = false;
      _messageIsError = false;
      _message = 'Backup importiert.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: SafeArea(
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  const AppleLargeTitle('Backup'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Exportiert alle lokal gespeicherten Daten (Buchungen, Kategorien, Gehaltsabrechnungen, '
                      'Personen, Firmenwagen, Budgets, Konten, Vermögenswerte/Kredite) als JSON-Datei. Diese Datei '
                      'kannst du sichern oder auf einer anderen Installation wieder importieren.',
                      style: TextStyle(color: context.appleColors.secondaryLabel),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        FilledButton.icon(
                          onPressed: _export,
                          icon: const Icon(CupertinoIcons.arrow_down_doc),
                          label: const Text('Backup exportieren'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _import,
                          icon: const Icon(CupertinoIcons.square_arrow_up),
                          label: const Text('Backup importieren'),
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 16),
                          Text(_message!, style: TextStyle(color: _messageIsError ? context.appleColors.danger : null)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
