import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/account_providers.dart';
import '../providers/person_providers.dart';
import '../providers/transaction_providers.dart';
import '../utils/formatters.dart';

const _availableColors = [
  Colors.blue,
  Colors.teal,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.brown,
  Colors.blueGrey,
  Colors.pink,
];

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountNotifierProvider);
    final balances = ref.watch(accountBalancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Konten')),
      body: SafeArea(
        child: accounts.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Noch keine Konten angelegt. Lege Konten an, um Kontostände zu verfolgen und '
                    'interne Überträge (Umbuchungen) nicht doppelt als Ein-/Ausgabe zu zählen.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final account in accounts) _AccountTile(account: account, balance: balances[account.id] ?? 0),
                ],
              ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (accounts.length >= 2)
            FloatingActionButton.extended(
              heroTag: 'account_transfer',
              onPressed: () => _showTransferDialog(context, ref, accounts),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Umbuchung'),
            ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'account_add',
            onPressed: () => _showAccountDialog(context, ref),
            icon: const Icon(Icons.add),
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
  Color color = existing != null ? Color(existing.colorValue) : _availableColors.first;

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
              TextField(
                controller: startingBalanceController,
                decoration: const InputDecoration(
                  labelText: 'Startguthaben (€)',
                  helperText: 'Kontostand zum Zeitpunkt, ab dem Buchungen hier erfasst werden.',
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
    final account = Account(
      id: existing?.id ?? const Uuid().v4(),
      name: nameController.text.trim(),
      startingBalance: double.tryParse(startingBalanceController.text.replaceAll(',', '.')) ?? 0,
      colorValue: color.toARGB32(),
      personId: personId,
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

    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Color(account.colorValue), child: const Icon(Icons.account_balance, color: Colors.white, size: 18)),
        title: Text(account.name),
        subtitle: person != null ? Text(person.name) : null,
        trailing: Text(
          currencyFormat.format(balance),
          style: TextStyle(fontWeight: FontWeight.bold, color: balance >= 0 ? Colors.green : Colors.red),
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
      ),
    );
  }
}
