import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import '../providers/category_providers.dart';
import '../providers/transaction_providers.dart';
import '../utils/formatters.dart';
import '../widgets/month_selector.dart';
import '../widgets/person_filter_bar.dart';
import 'transaction_form_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final transactions = ref.watch(transactionsForSelectedMonthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Buchungen')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            MonthSelector(month: month, onChanged: (m) => ref.read(selectedMonthProvider.notifier).state = m),
            const PersonFilterBar(),
            const Divider(height: 1),
            Expanded(
              child: transactions.isEmpty
                  ? const Center(child: Text('Keine Buchungen in diesem Monat.'))
                  : ListView.separated(
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) => _TransactionTile(transaction: transactions[index]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Buchung'),
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(transaction.categoryId));
    String? subcategoryName;
    if (category != null && transaction.subcategoryId != null) {
      for (final s in category.subcategories) {
        if (s.id == transaction.subcategoryId) {
          subcategoryName = s.name;
          break;
        }
      }
    }

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(transactionNotifierProvider.notifier).remove(transaction.id),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category != null ? Color(category.colorValue) : Colors.grey,
          child: Icon(transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.white, size: 18),
        ),
        title: Text(transaction.description),
        subtitle: Text(
          [dateFormat.format(transaction.date), category?.name, subcategoryName]
              .where((e) => e != null && e.isNotEmpty)
              .join(' · '),
        ),
        trailing: Text(
          currencyFormat.format(transaction.amount),
          style: TextStyle(
            color: transaction.isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TransactionFormScreen(existing: transaction)),
        ),
      ),
    );
  }
}
