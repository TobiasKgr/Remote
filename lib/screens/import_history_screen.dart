import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/import_batch.dart';
import '../providers/import_batch_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_widgets.dart';

final _historyDateFormat = DateFormat('dd.MM.yyyy, HH:mm', 'de_DE');

/// Every completed PDF import (Kontoauszug or Gehalt), newest first, with a
/// "Rückgängig machen" action per entry that deletes exactly what that
/// import added - a manual reset back to the state right before it ran.
class ImportHistoryScreen extends ConsumerWidget {
  const ImportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(importBatchNotifierProvider);
    final colors = context.appleColors;

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: SafeArea(
        child: batches.isEmpty
            ? ListView(
                children: [
                  const AppleLargeTitle('Import-Verlauf'),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Noch keine Importe. Jeder Kontoauszug- oder Gehalt-Import erscheint hier und lässt sich bei Bedarf rückgängig machen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.secondaryLabel),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const AppleLargeTitle('Import-Verlauf'),
                  AppleGroupedSection(children: [for (final batch in batches) _BatchTile(batch: batch)]),
                ],
              ),
      ),
    );
  }
}

class _BatchTile extends ConsumerWidget {
  const _BatchTile({required this.batch});

  final ImportBatch batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appleColors;
    final isGehalt = batch.source == ImportSource.gehalt;

    return ListTile(
      leading: Container(
        width: 29,
        height: 29,
        decoration: BoxDecoration(color: isGehalt ? AppleColors.green : AppleColors.blue, borderRadius: BorderRadius.circular(7)),
        child: Icon(isGehalt ? CupertinoIcons.money_euro_circle_fill : CupertinoIcons.arrow_up_doc_fill, color: Colors.white, size: 16),
      ),
      title: Text(batch.label),
      subtitle: Text(_historyDateFormat.format(batch.timestamp)),
      trailing: TextButton(
        onPressed: () => _confirmUndo(context, ref),
        child: Text('Rückgängig', style: TextStyle(color: colors.danger)),
      ),
    );
  }

  Future<void> _confirmUndo(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import rückgängig machen?'),
        content: Text(
          'Löscht "${batch.label}" wieder vollständig (alle dabei importierten Buchungen'
          '${batch.salarySlipIds.isNotEmpty ? ' und Gehaltsabrechnungen' : ''}). '
          'Der Stand von vor diesem Import wird wiederhergestellt.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Rückgängig machen')),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(importBatchNotifierProvider.notifier).undo(batch.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import rückgängig gemacht.')));
    }
  }
}
