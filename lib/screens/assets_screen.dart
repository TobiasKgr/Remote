import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/asset.dart';
import '../providers/account_providers.dart';
import '../providers/asset_providers.dart';
import '../providers/person_providers.dart';
import '../utils/formatters.dart';

const _availableColors = [
  Colors.indigo,
  Colors.teal,
  Colors.orange,
  Colors.green,
  Colors.purple,
  Colors.brown,
  Colors.blueGrey,
  Colors.red,
];

String assetCategoryLabel(AssetCategory category) => switch (category) {
      AssetCategory.investment => 'Investment/Depot',
      AssetCategory.realEstate => 'Immobilie',
      AssetCategory.other => 'Sonstiger Vermögenswert',
      AssetCategory.liability => 'Kredit/Schulden',
    };

class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetNotifierProvider);
    final accounts = ref.watch(accountNotifierProvider);
    final accountBalances = ref.watch(accountBalancesProvider);
    final netWorth = ref.watch(netWorthProvider);

    final ownedAssets = assets.where((a) => !a.isLiability).toList();
    final liabilities = assets.where((a) => a.isLiability).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Vermögensübersicht')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Netto-Vermögen', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(netWorth),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Summe aller Kontostände plus Vermögenswerte, abzüglich Kredite/Schulden.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (accounts.isNotEmpty) ...[
              Text('Konten', style: Theme.of(context).textTheme.titleMedium),
              for (final account in accounts)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Color(account.colorValue), child: const Icon(Icons.account_balance, color: Colors.white, size: 18)),
                    title: Text(account.name),
                    trailing: Text(currencyFormat.format(accountBalances[account.id] ?? 0)),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            Text('Vermögenswerte', style: Theme.of(context).textTheme.titleMedium),
            if (ownedAssets.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Noch keine Vermögenswerte erfasst.')),
            for (final asset in ownedAssets) _AssetTile(asset: asset),
            const SizedBox(height: 16),
            Text('Kredite/Schulden', style: Theme.of(context).textTheme.titleMedium),
            if (liabilities.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Keine Kredite/Schulden erfasst.')),
            for (final asset in liabilities) _AssetTile(asset: asset),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssetDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Eintrag'),
      ),
    );
  }
}

Future<void> _showAssetDialog(BuildContext context, WidgetRef ref, {Asset? existing}) async {
  final nameController = TextEditingController(text: existing?.name ?? '');
  final valueController = TextEditingController(text: existing == null || existing.value == 0 ? '' : existing.value.toStringAsFixed(2));
  final notesController = TextEditingController(text: existing?.notes ?? '');
  final persons = ref.read(personNotifierProvider);
  AssetCategory category = existing?.category ?? AssetCategory.investment;
  String? personId = existing?.personId;
  Color color = existing != null ? Color(existing.colorValue) : _availableColors.first;

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) => AlertDialog(
        title: Text(existing == null ? 'Neuer Eintrag' : 'Eintrag bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name (z. B. ETF-Depot, Hypothek)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<AssetCategory>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Art'),
                items: AssetCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(assetCategoryLabel(c)))).toList(),
                onChanged: (v) => setStateDialog(() => category = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(labelText: 'Aktueller Wert (€)'),
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
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notiz (optional)')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _availableColors
                    .map((c) => GestureDetector(
                          onTap: () => setStateDialog(() => color = c),
                          child: CircleAvatar(
                            backgroundColor: c,
                            radius: 16,
                            child: color.toARGB32() == c.toARGB32() ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                          ),
                        ))
                    .toList(),
              ),
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
    final asset = Asset(
      id: existing?.id ?? const Uuid().v4(),
      name: nameController.text.trim(),
      category: category,
      value: double.tryParse(valueController.text.replaceAll(',', '.')) ?? 0,
      colorValue: color.toARGB32(),
      personId: personId,
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
    );
    await ref.read(assetNotifierProvider.notifier).upsert(asset);
  }
}

class _AssetTile extends ConsumerWidget {
  const _AssetTile({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = asset.personId != null ? ref.watch(personByIdProvider(asset.personId!)) : null;
    final subtitleParts = [assetCategoryLabel(asset.category), if (person != null) person.name, if (asset.notes != null) asset.notes!];

    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Color(asset.colorValue), child: Icon(asset.isLiability ? Icons.trending_down : Icons.trending_up, color: Colors.white, size: 18)),
        title: Text(asset.name),
        subtitle: Text(subtitleParts.join(' · ')),
        trailing: Text(
          currencyFormat.format(asset.isLiability ? -asset.value : asset.value),
          style: TextStyle(fontWeight: FontWeight.bold, color: asset.isLiability ? Colors.red : Colors.green),
        ),
        onTap: () => _showAssetDialog(context, ref, existing: asset),
        onLongPress: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Eintrag löschen?'),
              content: Text('"${asset.name}" wirklich löschen?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
                FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Löschen')),
              ],
            ),
          );
          if (confirmed == true) {
            await ref.read(assetNotifierProvider.notifier).remove(asset.id);
          }
        },
      ),
    );
  }
}
