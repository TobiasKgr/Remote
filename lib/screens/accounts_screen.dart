import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/account_providers.dart';
import '../providers/person_providers.dart';
import '../providers/transaction_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';
import '../widgets/person_filter_bar.dart';

String accountTypeLabel(AccountType type) => switch (type) {
      AccountType.girokonto => 'Girokonto',
      AccountType.tagesgeld => 'Tagesgeldkonto',
      AccountType.kreditkarte => 'Kreditkarte',
      AccountType.kredit => 'Kredit',
    };

IconData accountTypeIcon(AccountType type) => switch (type) {
      AccountType.girokonto => CupertinoIcons.building_2_fill,
      AccountType.tagesgeld => CupertinoIcons.graph_circle_fill,
      AccountType.kreditkarte => CupertinoIcons.creditcard_fill,
      AccountType.kredit => CupertinoIcons.arrow_down_right_circle_fill,
    };

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAccounts = ref.watch(accountNotifierProvider);
    final balances = ref.watch(accountBalancesProvider);
    final personFilter = ref.watch(selectedPersonFilterProvider);
    final accounts = filterByPerson(allAccounts, personFilter, (a) => a.personId).toList();

    final groups = <AccountType, List<Account>>{};
    for (final account in accounts) {
      groups.putIfAbsent(account.type, () => []).add(account);
    }

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: SafeArea(
        child: allAccounts.isEmpty
            ? ListView(
                children: [
                  const AppleLargeTitle('Konten'),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Noch keine Konten angelegt. Lege Konten an, um Kontostände zu verfolgen und '
                      'interne Überträge (Umbuchungen) nicht doppelt als Ein-/Ausgabe zu zählen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.appleColors.secondaryLabel),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  const AppleLargeTitle('Konten'),
                  const PersonFilterBar(),
                  Expanded(
                    child: accounts.isEmpty
                        ? Center(
                            child: Text(
                              'Keine Konten für diesen Filter.',
                              style: TextStyle(color: context.appleColors.secondaryLabel),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 96, top: 8),
                            children: [
                              for (final type in AccountType.values)
                                if (groups[type] != null) ...[
                                  AppleSectionHeader(accountTypeLabel(type)),
                                  AppleGroupedSection(
                                    children: [for (final account in groups[type]!) _AccountTile(account: account, balance: balances[account.id] ?? 0)],
                                  ),
                                ],
                            ],
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (allAccounts.length >= 2)
            FloatingActionButton.extended(
              heroTag: 'account_transfer',
              onPressed: () => _showTransferDialog(context, ref, allAccounts),
              icon: const Icon(CupertinoIcons.arrow_right_arrow_left),
              label: const Text('Umbuchung'),
            ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'account_add',
            onPressed: () => _showAccountDialog(context, ref),
            icon: const Icon(CupertinoIcons.add),
            label: const Text('Konto'),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAccountDialog(BuildContext context, WidgetRef ref, {Account? existing}) async {
  final nameController = TextEditingController(text: existing?.name ?? '');
  final startingBalanceController = TextEditingController(
    text: existing == null || existing.startingBalance == 0 ? '' : existing.startingBalance.toStringAsFixed(2),
  );
  final persons = ref.read(personNotifierProvider);
  String? personId = existing?.personId;
  AccountType type = existing?.type ?? AccountType.girokonto;
  Color color = existing != null ? Color(existing.colorValue) : AppleColors.pickerPalette.first;

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) => AlertDialog(
        title: Text(existing == null ? 'Neues Konto' : 'Konto bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name (z. B. Girokonto)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<AccountType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Art'),
                items: AccountType.values.map((t) => DropdownMenuItem(value: t, child: Text(accountTypeLabel(t)))).toList(),
                onChanged: (v) => setStateDialog(() => type = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startingBalanceController,
                decoration: InputDecoration(
                  labelText: 'Startguthaben (€)',
                  helperText: type == AccountType.kreditkarte || type == AccountType.kredit
                      ? 'Bereits vorhandene Schulden als negativer Betrag eintragen (z. B. -500).'
                      : 'Kontostand zum Zeitpunkt, ab dem Buchungen hier erfasst werden.',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
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
    final account = Account(
      id: existing?.id ?? const Uuid().v4(),
      name: nameController.text.trim(),
      startingBalance: double.tryParse(startingBalanceController.text.replaceAll(',', '.')) ?? 0,
      colorValue: color.toARGB32(),
      personId: personId,
      type: type,
    );
    await ref.read(accountNotifierProvider.notifier).upsert(account);
  }
}

Future<void> _showTransferDialog(BuildContext context, WidgetRef ref, List<Account> accounts) async {
  String fromId = accounts.first.id;
  String toId = accounts.firstWhere((a) => a.id != fromId, orElse: () => accounts[1]).id;
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  String? errorText;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) => AlertDialog(
        title: const Text('Umbuchung zwischen eigenen Konten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: fromId,
                decoration: const InputDecoration(labelText: 'Von Konto'),
                items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                onChanged: (v) => setStateDialog(() => fromId = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: toId,
                decoration: const InputDecoration(labelText: 'Nach Konto'),
                items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                onChanged: (v) => setStateDialog(() => toId = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Betrag (€)', errorText: errorText),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Beschreibung (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
              if (fromId == toId) {
                setStateDialog(() => errorText = 'Von- und Nach-Konto müssen sich unterscheiden.');
                return;
              }
              if (amount == null || amount <= 0) {
                setStateDialog(() => errorText = 'Bitte einen gültigen Betrag angeben.');
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Umbuchen'),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true) return;

  final amount = double.parse(amountController.text.replaceAll(',', '.'));
  final fromAccount = accounts.firstWhere((a) => a.id == fromId);
  final toAccount = accounts.firstWhere((a) => a.id == toId);
  final groupId = const Uuid().v4();
  final now = DateTime.now();
  final customDescription = descriptionController.text.trim();

  final outgoing = Transaction(
    id: const Uuid().v4(),
    date: now,
    amount: -amount,
    description: customDescription.isEmpty ? 'Umbuchung zu ${toAccount.name}' : customDescription,
    categoryId: 'umbuchung',
    accountId: fromAccount.id,
    isTransfer: true,
    transferGroupId: groupId,
  );
  final incoming = Transaction(
    id: const Uuid().v4(),
    date: now,
    amount: amount,
    description: customDescription.isEmpty ? 'Umbuchung von ${fromAccount.name}' : customDescription,
    categoryId: 'umbuchung',
    accountId: toAccount.id,
    isTransfer: true,
    transferGroupId: groupId,
  );

  await ref.read(transactionNotifierProvider.notifier).upsertAll([outgoing, incoming]);
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({required this.account, required this.balance});

  final Account account;
  final double balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = account.personId != null ? ref.watch(personByIdProvider(account.personId!)) : null;
    final colors = context.appleColors;

    return ListTile(
      leading: CircleAvatar(backgroundColor: Color(account.colorValue), child: Icon(accountTypeIcon(account.type), color: Colors.white, size: 18)),
      title: Text(account.name),
      subtitle: Text(person != null ? '${accountTypeLabel(account.type)} · ${person.name}' : accountTypeLabel(account.type)),
      trailing: Text(
        currencyFormat.format(balance),
        style: TextStyle(fontWeight: FontWeight.bold, color: balance >= 0 ? colors.success : colors.danger),
      ),
      onTap: () => _showAccountDialog(context, ref, existing: account),
      onLongPress: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konto löschen?'),
            content: Text(
              '"${account.name}" löschen? Bereits zugeordnete Buchungen bleiben erhalten, '
              'gelten danach aber als keinem Konto zugeordnet.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Löschen')),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(accountNotifierProvider.notifier).remove(account.id);
        }
      },
    );
  }
}
