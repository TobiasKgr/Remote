import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import '../providers/category_providers.dart';
import '../providers/transaction_filter_providers.dart';
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
    final monthTransactions = ref.watch(transactionsForSelectedMonthProvider);
    final filteredTransactions = ref.watch(filteredTransactionsProvider);
    final categoryFilter = ref.watch(transactionCategoryFilterProvider);
    final amountRange = ref.watch(transactionAmountRangeProvider);
    final filtersActive = categoryFilter != null || amountRange.isActive;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buchungen'),
        actions: [
          IconButton(
            tooltip: 'Filter',
            icon: Badge(isLabelVisible: filtersActive, child: const Icon(Icons.filter_list)),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => const _FilterSheetContent(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            MonthSelector(month: month, onChanged: (m) => ref.read(selectedMonthProvider.notifier).state = m),
            const PersonFilterBar(),
            const _SearchField(),
            const Divider(height: 1),
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Text(
                        monthTransactions.isEmpty ? 'Keine Buchungen in diesem Monat.' : 'Keine Buchungen entsprechen den Filtern.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredTransactions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) => _TransactionTile(transaction: filteredTransactions[index]),
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

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(transactionSearchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Suche nach Beschreibung...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    ref.read(transactionSearchQueryProvider.notifier).state = '';
                    setState(() {});
                  },
                ),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (value) {
          ref.read(transactionSearchQueryProvider.notifier).state = value;
          setState(() {});
        },
      ),
    );
  }
}

class _FilterSheetContent extends ConsumerStatefulWidget {
  const _FilterSheetContent();

  @override
  ConsumerState<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends ConsumerState<_FilterSheetContent> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    final range = ref.read(transactionAmountRangeProvider);
    _minController = TextEditingController(text: range.min == null ? '' : range.min!.toStringAsFixed(2));
    _maxController = TextEditingController(text: range.max == null ? '' : range.max!.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryNotifierProvider);
    final categoryFilter = ref.watch(transactionCategoryFilterProvider);
    final amountRange = ref.watch(transactionAmountRangeProvider);

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: categoryFilter,
            decoration: const InputDecoration(labelText: 'Kategorie'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Alle Kategorien')),
              ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
            ],
            onChanged: (v) => ref.read(transactionCategoryFilterProvider.notifier).state = v,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  decoration: const InputDecoration(labelText: 'Betrag von (€)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => ref.read(transactionAmountRangeProvider.notifier).state = AmountRange(
                    min: double.tryParse(v.replaceAll(',', '.')),
                    max: amountRange.max,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  decoration: const InputDecoration(labelText: 'Betrag bis (€)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => ref.read(transactionAmountRangeProvider.notifier).state = AmountRange(
                    min: amountRange.min,
                    max: double.tryParse(v.replaceAll(',', '.')),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  ref.read(transactionCategoryFilterProvider.notifier).state = null;
                  ref.read(transactionAmountRangeProvider.notifier).state = const AmountRange();
                  _minController.clear();
                  _maxController.clear();
                },
                child: const Text('Zurücksetzen'),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fertig')),
            ],
          ),
        ],
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
        title: Row(
          children: [
            Flexible(child: Text(transaction.description, overflow: TextOverflow.ellipsis)),
            if (transaction.source == TransactionSource.recurringGenerated) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Automatisch als wiederkehrende Buchung erzeugt',
                child: Icon(Icons.autorenew, size: 16, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ],
        ),
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
