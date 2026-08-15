import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/account_providers.dart';
import '../providers/asset_providers.dart';
import '../providers/company_car_providers.dart';
import '../providers/person_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/salary_slip_providers.dart';
import '../providers/settings_providers.dart';
import '../providers/transaction_providers.dart';
import '../services/demo_data_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_widgets.dart';

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
                ],
              ),
      ),
    );
  }
}
