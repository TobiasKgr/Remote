import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../providers/category_providers.dart';
import '../providers/transaction_filter_providers.dart';
import '../providers/transaction_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';
import '../widgets/month_selector.dart';
import '../widgets/person_filter_bar.dart';
import 'transaction_form_screen.dart';

final _weekdayDateFormat = DateFormat('EEEE, d. MMMM', 'de_DE');

/// Groups already date-sorted transactions into same-day buckets, preserving
/// their existing order (newest day first).
List<MapEntry<DateTime, List<Transaction>>> _groupByDay(List<Transaction> transactions) {
  final groups = <DateTime, List<Transaction>>{};
  for (final t in transactions) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    groups.putIfAbsent(day, () => []).add(t);
  }
  return groups.entries.toList();
}

String _dayLabel(DateTime day) {
  final today = DateTime.now();
  final todayDay = DateTime(today.year, today.month, today.day);
  final yesterday = todayDay.subtract(const Duration(days: 1));
  if (day == todayDay) return 'Heute';
  if (day == yesterday) return 'Gestern';
  return _weekdayDateFormat.format(day);
}

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
    final groups = _groupByDay(filteredTransactions);

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            tooltip: 'Filter',
            icon: Badge(isLabelVisible: filtersActive, child: const Icon(CupertinoIcons.slider_horizontal_3)),
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
            const AppleLargeTitle('Buchungen'),
            MonthSelector(month: month, onChanged: (m) => ref.read(selectedMonthProvider.notifier).state = m),
            const PersonFilterBar(),
            const _SearchField(),
            const SizedBox(height: 4),
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Text(
                        monthTransactions.isEmpty ? 'Keine Buchungen in diesem Monat.' : 'Keine Buchungen entsprechen den Filtern.',
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 96),
                      children: [
                        for (final group in groups) ...[
                          AppleSectionHeader(_dayLabel(group.key)),
                          AppleGroupedSection(
                            children: [for (final t in group.value) _TransactionTile(transaction: t)],
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
        ),
        icon: const Icon(CupertinoIcons.add),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Suche nach Beschreibung...',
          prefixIcon: const Icon(CupertinoIcons.search, size: 20),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18),
                  onPressed: () {
                    _controller.clear();
                    ref.read(transactionSearchQueryProvider.notifier).state = '';
                    setState(() {});
                  },
                ),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppleRadii.pill), borderSide: BorderSide.none),
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

    final colors = context.appleColors;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colors.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(CupertinoIcons.delete_simple, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(transactionNotifierProvider.notifier).remove(transaction.id),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category != null ? Color(category.colorValue) : colors.secondaryLabel,
          child: Icon(transaction.isIncome ? CupertinoIcons.arrow_down : CupertinoIcons.arrow_up, color: Colors.white, size: 18),
        ),
        title: Row(
          children: [
            Flexible(child: Text(transaction.description, overflow: TextOverflow.ellipsis)),
            if (transaction.source == TransactionSource.recurringGenerated) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Automatisch als wiederkehrende Buchung erzeugt',
                child: Icon(CupertinoIcons.refresh, size: 16, color: Theme.of(context).colorScheme.primary),
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
            color: transaction.isIncome ? colors.success : colors.danger,
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
