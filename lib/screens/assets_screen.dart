import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/asset.dart';
import '../providers/account_providers.dart';
import '../providers/asset_providers.dart';
import '../providers/person_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';

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

    final colors = context.appleColors;

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const AppleLargeTitle('Vermögensübersicht'),
            AppleHeroCard(
              label: 'Netto-Vermögen',
              value: currencyFormat.format(netWorth),
              subtitle: 'Summe aller Kontostände plus Vermögenswerte, abzüglich Kredite/Schulden.',
              valueColor: netWorth >= 0 ? colors.success : colors.danger,
            ),
            if (accounts.isNotEmpty) ...[
              const AppleSectionHeader('Konten'),
              AppleGroupedSection(
                children: [
                  for (final account in accounts)
                    ListTile(
                      leading: CircleAvatar(backgroundColor: Color(account.colorValue), child: const Icon(CupertinoIcons.building_2_fill, color: Colors.white, size: 18)),
                      title: Text(account.name),
                      trailing: Text(currencyFormat.format(accountBalances[account.id] ?? 0)),
                    ),
                ],
              ),
            ],
            const AppleSectionHeader('Vermögenswerte'),
            if (ownedAssets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Noch keine Vermögenswerte erfasst.', style: TextStyle(color: colors.secondaryLabel)),
              )
            else
              AppleGroupedSection(children: [for (final asset in ownedAssets) _AssetTile(asset: asset)]),
            const AppleSectionHeader('Kredite/Schulden'),
            if (liabilities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Keine Kredite/Schulden erfasst.', style: TextStyle(color: colors.secondaryLabel)),
              )
            else
              AppleGroupedSection(children: [for (final asset in liabilities) _AssetTile(asset: asset)]),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssetDialog(context, ref),
        icon: const Icon(CupertinoIcons.add),
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
  Color color = existing != null ? Color(existing.colorValue) : AppleColors.pickerPalette.first;

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
                children: AppleColors.pickerPalette
                    .map((c) => GestureDetector(
                          onTap: () => setStateDialog(() => color = c),
                          child: CircleAvatar(
                            backgroundColor: c,
                            radius: 16,
                            child: color.toARGB32() == c.toARGB32() ? const Icon(CupertinoIcons.check_mark, color: Colors.white, size: 18) : null,
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
    final colors = context.appleColors;

    return ListTile(
      leading: CircleAvatar(backgroundColor: Color(asset.colorValue), child: Icon(asset.isLiability ? CupertinoIcons.arrow_down_right : CupertinoIcons.arrow_up_right, color: Colors.white, size: 18)),
      title: Text(asset.name),
      subtitle: Text(subtitleParts.join(' · ')),
      trailing: Text(
        currencyFormat.format(asset.isLiability ? -asset.value : asset.value),
        style: TextStyle(fontWeight: FontWeight.bold, color: asset.isLiability ? colors.danger : colors.success),
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
    );
  }
}
