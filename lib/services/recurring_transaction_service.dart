import 'package:uuid/uuid.dart';

import '../models/transaction.dart';

/// Generates the missing booking(s) for recurring transactions so a
/// subscription/Abo doesn't have to be re-entered or re-imported by hand
/// every month.
///
/// Transactions are grouped into a "series" by normalized description
/// (digits/punctuation stripped) + category + subcategory + person. For
/// each series, only the **most recent** transaction (by date) decides
/// whether it continues: if it is flagged [Transaction.isRecurring], one
/// new transaction is generated for every calendar month between it and
/// the reference date (default: today), copying its amount/category/
/// description/person as the template. If the most recent transaction is
/// *not* recurring (e.g. the user unchecked it after cancelling), the
/// series is considered stopped and nothing is generated for it.
class RecurringTransactionService {
  static const _maxMonthsToBackfill = 24;

  List<Transaction> generateMissingOccurrences(List<Transaction> transactions, {DateTime? referenceDate}) {
    final reference = referenceDate ?? DateTime.now();
    final referenceMonth = DateTime(reference.year, reference.month);

    final series = <String, List<Transaction>>{};
    for (final t in transactions) {
      series.putIfAbsent(_seriesKey(t), () => []).add(t);
    }

    final generated = <Transaction>[];
    for (final entries in series.values) {
      entries.sort((a, b) => a.date.compareTo(b.date));
      final latest = entries.last;
      if (!latest.isRecurring) continue;

      var cursor = DateTime(latest.date.year, latest.date.month);
      var monthsGenerated = 0;
      while (cursor.isBefore(referenceMonth) && monthsGenerated < _maxMonthsToBackfill) {
        cursor = DateTime(cursor.year, cursor.month + 1);
        generated.add(_copyForMonth(latest, cursor));
        monthsGenerated++;
      }
    }
    return generated;
  }

  String _seriesKey(Transaction t) {
    final normalizedDescription = t.description
        .toLowerCase()
        .replaceAll(RegExp(r'[0-9]+'), '')
        .replaceAll(RegExp(r'[^a-zäöüß\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '${t.categoryId}::${t.subcategoryId ?? ''}::${t.personId ?? ''}::$normalizedDescription';
  }

  Transaction _copyForMonth(Transaction source, DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final day = source.date.day > daysInMonth ? daysInMonth : source.date.day;

    return Transaction(
      id: const Uuid().v4(),
      date: DateTime(month.year, month.month, day),
      amount: source.amount,
      description: source.description,
      categoryId: source.categoryId,
      subcategoryId: source.subcategoryId,
      source: TransactionSource.recurringGenerated,
      isRecurring: true,
      personId: source.personId,
    );
  }
}
