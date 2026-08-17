import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/default_categories.dart';
import '../providers/account_providers.dart';
import '../providers/asset_providers.dart';
import '../providers/budget_providers.dart';
import '../providers/category_providers.dart';
import '../providers/company_car_providers.dart';
import '../providers/import_batch_providers.dart';
import '../providers/person_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/salary_slip_providers.dart';
import '../providers/settings_providers.dart';
import '../providers/transaction_providers.dart';
import '../services/backup_service.dart';
import '../services/demo_data_service.dart';
import '../services/file_saver.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_widgets.dart';
import 'nav_settings_screen.dart';

enum _ResetExportChoice { cancel, withoutExport, export }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  bool get _demoDataLoaded => ref.watch(accountNotifierProvider).any((a) => DemoDataService.isDemoId(a.id));

  Future<void> _loadDemoData() async {
    setState(() => _busy = true);
    final bundle = DemoDataService().build();

    for (final p in bundle.persons) {
      await ref.read(personRepositoryProvider).save(p);
    }
    for (final a in bundle.accounts) {
      await ref.read(accountRepositoryProvider).save(a);
    }
    for (final c in bundle.companyCars) {
      await ref.read(companyCarRepositoryProvider).save(c);
    }
    for (final a in bundle.assets) {
      await ref.read(assetRepositoryProvider).save(a);
    }
    for (final s in bundle.salarySlips) {
      await ref.read(salarySlipRepositoryProvider).save(s);
    }
    await ref.read(transactionRepositoryProvider).saveAll(bundle.transactions);

    ref.invalidate(personNotifierProvider);
    ref.invalidate(accountNotifierProvider);
    ref.invalidate(companyCarNotifierProvider);
    ref.invalidate(assetNotifierProvider);
    ref.invalidate(salarySlipNotifierProvider);
    ref.invalidate(transactionNotifierProvider);

    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demodaten geladen - auf Dashboard, Buchungen, Konten & Co. ansehen.')),
    );
  }

  Future<void> _removeDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demodaten entfernen?'),
        content: const Text('Entfernt alle Beispiel-Buchungen, -Konten, -Personen und weiteren Demo-Einträge wieder. Eigene Daten bleiben unberührt.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Entfernen')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);

    final transactionRepo = ref.read(transactionRepositoryProvider);
    for (final t in transactionRepo.getAll().where((t) => DemoDataService.isDemoId(t.id))) {
      await transactionRepo.delete(t.id);
    }
    final personRepo = ref.read(personRepositoryProvider);
    for (final p in personRepo.getAll().where((p) => DemoDataService.isDemoId(p.id))) {
      await personRepo.delete(p.id);
    }
    final accountRepo = ref.read(accountRepositoryProvider);
    for (final a in accountRepo.getAll().where((a) => DemoDataService.isDemoId(a.id))) {
      await accountRepo.delete(a.id);
    }
    final carRepo = ref.read(companyCarRepositoryProvider);
    for (final c in carRepo.getAll().where((c) => DemoDataService.isDemoId(c.id))) {
      await carRepo.delete(c.id);
    }
    final assetRepo = ref.read(assetRepositoryProvider);
    for (final a in assetRepo.getAll().where((a) => DemoDataService.isDemoId(a.id))) {
      await assetRepo.delete(a.id);
    }
    final salaryRepo = ref.read(salarySlipRepositoryProvider);
    for (final s in salaryRepo.getAll().where((s) => DemoDataService.isDemoId(s.id))) {
      await salaryRepo.delete(s.id);
    }

    ref.invalidate(transactionNotifierProvider);
    ref.invalidate(personNotifierProvider);
    ref.invalidate(accountNotifierProvider);
    ref.invalidate(companyCarNotifierProvider);
    ref.invalidate(assetNotifierProvider);
    ref.invalidate(salarySlipNotifierProvider);

    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demodaten entfernt.')));
  }

  /// Full data reset - deletes every booking, category (reseeded to
  /// defaults), account, person, asset, company car, salary slip, budget
  /// and the import history. App-level settings (Navigation, Erinnerungen)
  /// and taught PDF-Formate are left untouched, since those aren't
  /// financial data. Guarded by two confirmations: whether to export first,
  /// then a final "really delete everything" check.
  Future<void> _resetAllData() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle Daten zurücksetzen?'),
        content: const Text(
          'Löscht unwiderruflich alle Buchungen, Konten, Personen, Vermögenswerte/Kredite, Firmenwagen, '
          'Gehaltsabrechnungen, Budgets und den Import-Verlauf. Kategorien werden auf die Standard-Kategorien '
          'zurückgesetzt. App-Einstellungen (Navigation, Erinnerungen) und angelernte PDF-Formate bleiben erhalten.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Weiter')),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    final choice = await showDialog<_ResetExportChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daten vorher exportieren?'),
        content: const Text('Ein Backup lässt sich später wieder über "Backup importieren" einspielen.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(_ResetExportChoice.cancel), child: const Text('Abbrechen')),
          TextButton(onPressed: () => Navigator.of(context).pop(_ResetExportChoice.withoutExport), child: const Text('Ohne Export löschen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(_ResetExportChoice.export), child: const Text('Zuerst exportieren')),
        ],
      ),
    );
    if (choice == null || choice == _ResetExportChoice.cancel || !mounted) return;

    if (choice == _ResetExportChoice.export) {
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
      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Export abgebrochen - Zurücksetzen wurde nicht durchgeführt.')));
        return;
      }
    }

    setState(() => _busy = true);

    final transactionRepo = ref.read(transactionRepositoryProvider);
    for (final t in transactionRepo.getAll()) {
      await transactionRepo.delete(t.id);
    }
    final personRepo = ref.read(personRepositoryProvider);
    for (final p in personRepo.getAll()) {
      await personRepo.delete(p.id);
    }
    final accountRepo = ref.read(accountRepositoryProvider);
    for (final a in accountRepo.getAll()) {
      await accountRepo.delete(a.id);
    }
    final assetRepo = ref.read(assetRepositoryProvider);
    for (final a in assetRepo.getAll()) {
      await assetRepo.delete(a.id);
    }
    final carRepo = ref.read(companyCarRepositoryProvider);
    for (final c in carRepo.getAll()) {
      await carRepo.delete(c.id);
    }
    final salaryRepo = ref.read(salarySlipRepositoryProvider);
    for (final s in salaryRepo.getAll()) {
      await salaryRepo.delete(s.id);
    }
    final budgetRepo = ref.read(budgetRepositoryProvider);
    for (final b in budgetRepo.getAll()) {
      await budgetRepo.delete(b.id);
    }
    final importBatchRepo = ref.read(importBatchRepositoryProvider);
    for (final b in importBatchRepo.getAll()) {
      await importBatchRepo.delete(b.id);
    }
    final categoryRepo = ref.read(categoryRepositoryProvider);
    for (final c in categoryRepo.getAll()) {
      await categoryRepo.delete(c.id);
    }
    for (final c in buildDefaultCategories()) {
      await categoryRepo.save(c);
    }

    ref.invalidate(transactionNotifierProvider);
    ref.invalidate(personNotifierProvider);
    ref.invalidate(accountNotifierProvider);
    ref.invalidate(assetNotifierProvider);
    ref.invalidate(companyCarNotifierProvider);
    ref.invalidate(salarySlipNotifierProvider);
    ref.invalidate(budgetNotifierProvider);
    ref.invalidate(importBatchNotifierProvider);
    ref.invalidate(categoryNotifierProvider);

    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alle Daten wurden zurückgesetzt.')));
  }

  @override
  Widget build(BuildContext context) {
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final demoDataLoaded = _demoDataLoaded;

    final colors = context.appleColors;

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: SafeArea(
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const AppleLargeTitle('Einstellungen'),
                  const AppleSectionHeader('Navigation'),
                  AppleGroupedSection(
                    children: [
                      ListTile(
                        leading: const Icon(CupertinoIcons.rectangle_stack),
                        title: const Text('Navigation anpassen'),
                        subtitle: const Text('Reihenfolge der Reiter ändern, einzelne unter "Mehr" verstecken'),
                        trailing: Icon(CupertinoIcons.chevron_right, size: 15, color: colors.secondaryLabel),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NavSettingsScreen())),
                      ),
                    ],
                  ),
                  const AppleSectionHeader('Erinnerungen'),
                  AppleGroupedSection(
                    children: [
                      SwitchListTile(
                        title: const Text('Erinnerungen'),
                        subtitle: const Text(
                          'Benachrichtigt dich, während die App geöffnet ist, wenn ein Budget '
                          'überschritten oder eine Ausgabenspitze erkannt wird. Keine '
                          'Hintergrund-Benachrichtigungen bei geschlossener App; unter Windows '
                          'derzeit nicht unterstützt.',
                        ),
                        value: notificationsEnabled,
                        onChanged: (value) async {
                          if (value) {
                            await const NotificationService().initialize();
                          }
                          await ref.read(notificationsEnabledProvider.notifier).setEnabled(value);
                        },
                      ),
                    ],
                  ),
                  const AppleSectionHeader('Demo-Modus'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Lädt realistische Beispieldaten (Personen, Konten, Buchungen über 3 Monate, '
                      'Firmenwagen, Gehaltsabrechnungen, Vermögenswerte) zum Ausprobieren aller Funktionen. '
                      'Alle Demo-Einträge sind klar mit "(Demo)" gekennzeichnet und lassen sich jederzeit '
                      'gesammelt wieder entfernen, ohne eigene Daten zu berühren.',
                      style: TextStyle(color: colors.secondaryLabel),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppleGroupedSection(
                    children: [
                      ListTile(
                        leading: const Icon(CupertinoIcons.sparkles),
                        title: Text(demoDataLoaded ? 'Demodaten aktualisieren' : 'Demodaten laden'),
                        onTap: _loadDemoData,
                      ),
                      if (demoDataLoaded)
                        ListTile(
                          leading: Icon(CupertinoIcons.trash, color: colors.danger),
                          title: Text('Demodaten entfernen', style: TextStyle(color: colors.danger)),
                          onTap: _removeDemoData,
                        ),
                    ],
                  ),
                  const AppleSectionHeader('Datenreset'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Löscht unwiderruflich alle Buchungen, Konten, Personen, Vermögenswerte/Kredite, '
                      'Firmenwagen, Gehaltsabrechnungen, Budgets und den Import-Verlauf; Kategorien werden auf '
                      'die Standard-Kategorien zurückgesetzt. Vor dem Zurücksetzen kannst du wählen, ob deine '
                      'Daten vorher als Backup exportiert werden sollen.',
                      style: TextStyle(color: colors.secondaryLabel),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppleGroupedSection(
                    children: [
                      ListTile(
                        leading: Icon(CupertinoIcons.exclamationmark_triangle_fill, color: colors.danger),
                        title: Text('Alle Daten zurücksetzen', style: TextStyle(color: colors.danger)),
                        onTap: _resetAllData,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
