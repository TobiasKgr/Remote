import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/description_normalizer.dart';
import '../utils/formatters.dart';

enum InsightSeverity { info, warning }

class Insight {
  const Insight({required this.title, required this.description, this.severity = InsightSeverity.info});

  final String title;
  final String description;
  final InsightSeverity severity;
}

/// Rule-based optimization hints derived purely from locally stored
/// transactions for the given reference month. No external data, no
/// assumptions about whether a subscription is actually still used - only
/// factual observations (recurring charges, spikes, duplicates) that
/// prompt the user to check for themselves.
class OptimizationService {
  static const _spikeThresholdRatio = 1.3; // flag at +30% vs. trailing average
  static const _spikeMinAbsoluteDifference = 20.0; // ignore noise on tiny categories
  static const _dormantMinStreakMonths = 3;
  static const _anomalyMinHistory = 3; // need at least this many earlier bookings at the same merchant
  static const _anomalyRatioThreshold = 1.6; // flag at +60% vs. that merchant's own historical median
  static const _anomalyMinAbsoluteDifference = 15.0;

  List<Insight> analyze(List<Transaction> transactions, List<Category> categories, DateTime referenceMonth) {
    final categoryById = {for (final c in categories) c.id: c};
    final expenses = transactions.where((t) => !t.isIncome && !t.isTransfer).toList();

    final insights = <Insight>[
      ..._recurringCostSummary(expenses, referenceMonth),
      ..._duplicateSubscriptions(expenses, categoryById, referenceMonth),
      ..._spendingSpikes(expenses, categoryById, referenceMonth),
      ..._merchantAnomalies(expenses, referenceMonth),
      ..._longRunningSubscriptions(expenses, referenceMonth),
    ];

    insights.sort((a, b) => a.severity == b.severity ? 0 : (a.severity == InsightSeverity.warning ? -1 : 1));
    return insights;
  }

  Iterable<Insight> _recurringCostSummary(List<Transaction> expenses, DateTime month) {
    final recurring = _inMonth(expenses, month).where((t) => t.isRecurring).toList();
    if (recurring.isEmpty) return const [];
    final total = recurring.fold<double>(0, (s, t) => s + t.amount.abs());
    return [
      Insight(
        title: 'Wiederkehrende Kosten',
        description: 'Diesen Monat ${recurring.length} wiederkehrende Buchung(en) '
            '(z. B. Abos) mit insgesamt ${currencyFormat.format(total)}.',
      ),
    ];
  }

  Iterable<Insight> _duplicateSubscriptions(List<Transaction> expenses, Map<String, Category> categoryById, DateTime month) {
    final recurringThisMonth = _inMonth(expenses, month).where((t) => t.isRecurring && t.subcategoryId != null);

    final bySubcategory = <String, List<Transaction>>{};
    for (final t in recurringThisMonth) {
      bySubcategory.putIfAbsent('${t.categoryId}::${t.subcategoryId}', () => []).add(t);
    }

    final insights = <Insight>[];
    for (final group in bySubcategory.values) {
      final distinct = <String, Transaction>{};
      for (final t in group) {
        distinct[t.description.trim().toLowerCase()] = t;
      }
      if (distinct.length < 2) continue;

      final total = group.fold<double>(0, (s, t) => s + t.amount.abs());
      final category = categoryById[group.first.categoryId];
      final subcategoryName = category?.subcategories
              .where((s) => s.id == group.first.subcategoryId)
              .map((s) => s.name)
              .firstOrNull ??
          'Unterkategorie';
      final names = distinct.values.map((t) => t.description.trim()).join(', ');

      insights.add(Insight(
        title: 'Mehrere Abos in "$subcategoryName"',
        description: 'Du zahlst für $names in der gleichen Unterkategorie – insgesamt '
            '${currencyFormat.format(total)}/Monat. Werden alle noch gebraucht?',
        severity: InsightSeverity.warning,
      ));
    }
    return insights;
  }

  Iterable<Insight> _spendingSpikes(List<Transaction> expenses, Map<String, Category> categoryById, DateTime month) {
    double sumForMonth(DateTime m, String categoryId) {
      return expenses
          .where((t) => t.categoryId == categoryId && t.date.year == m.year && t.date.month == m.month)
          .fold<double>(0, (s, t) => s + t.amount.abs());
    }

    final insights = <Insight>[];
    for (final categoryId in expenses.map((t) => t.categoryId).toSet()) {
      final current = sumForMonth(month, categoryId);
      if (current <= 0) continue;

      final priorSums = [1, 2, 3]
          .map((i) => sumForMonth(DateTime(month.year, month.month - i), categoryId))
          .where((v) => v > 0)
          .toList();
      if (priorSums.isEmpty) continue;

      final average = priorSums.reduce((a, b) => a + b) / priorSums.length;
      if (average <= 0) continue;

      final difference = current - average;
      if (current >= average * _spikeThresholdRatio && difference >= _spikeMinAbsoluteDifference) {
        final categoryName = categoryById[categoryId]?.name ?? categoryId;
        final percent = ((current / average) - 1) * 100;
        insights.add(Insight(
          title: 'Ausgabenspitze: $categoryName',
          description: '${currencyFormat.format(current)} diesen Monat, ${percent.round()}% mehr als im '
              'Schnitt der letzten Monate (${currencyFormat.format(average)}).',
          severity: InsightSeverity.warning,
        ));
      }
    }
    return insights;
  }

  /// Flags individual bookings in [month] that are unusually high compared
  /// to that specific merchant's *own* history - independent of category
  /// totals, so e.g. one oversized REWE run stands out even if groceries as
  /// a whole category look unremarkable that month.
  Iterable<Insight> _merchantAnomalies(List<Transaction> expenses, DateTime month) {
    final byMerchant = <String, List<Transaction>>{};
    for (final t in expenses) {
      final key = normalizeDescription(t.description);
      if (key.isEmpty) continue;
      byMerchant.putIfAbsent(key, () => []).add(t);
    }

    final insights = <Insight>[];
    for (final group in byMerchant.values) {
      final thisMonth = group.where((t) => t.date.year == month.year && t.date.month == month.month);
      final history = group.where((t) => !(t.date.year == month.year && t.date.month == month.month)).toList();
      if (history.length < _anomalyMinHistory) continue;

      final sortedAmounts = history.map((t) => t.amount.abs()).toList()..sort();
      final median = sortedAmounts[sortedAmounts.length ~/ 2];
      if (median <= 0) continue;

      for (final t in thisMonth) {
        final amount = t.amount.abs();
        final difference = amount - median;
        if (amount < median * _anomalyRatioThreshold || difference < _anomalyMinAbsoluteDifference) continue;

        final percent = ((amount / median) - 1) * 100;
        insights.add(Insight(
          title: 'Ungewöhnliche Buchung: ${t.description.trim()}',
          description: '${currencyFormat.format(amount)} am ${dateFormat.format(t.date)} - sonst meist rund '
              '${currencyFormat.format(median)} bei diesem Empfänger (+${percent.round()}%).',
          severity: InsightSeverity.warning,
        ));
      }
    }
    return insights;
  }

  Iterable<Insight> _longRunningSubscriptions(List<Transaction> expenses, DateTime month) {
    final recurring = expenses.where((t) => t.isRecurring);
    final byDescription = <String, List<Transaction>>{};
    for (final t in recurring) {
      byDescription.putIfAbsent(t.description.trim().toLowerCase(), () => []).add(t);
    }

    final insights = <Insight>[];
    for (final group in byDescription.values) {
      final months = group.map((t) => DateTime(t.date.year, t.date.month)).toSet();
      var streak = 0;
      var cursor = DateTime(month.year, month.month);
      while (months.contains(cursor)) {
        streak++;
        cursor = DateTime(cursor.year, cursor.month - 1);
      }
      if (streak < _dormantMinStreakMonths) continue;

      final latest = group.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
      insights.add(Insight(
        title: 'Läuft seit $streak Monaten: ${latest.description.trim()}',
        description: '${currencyFormat.format(latest.amount.abs())}/Monat seit mindestens $streak Monaten '
            'unverändert gebucht. Wird das noch benötigt?',
      ));
    }
    return insights;
  }

  List<Transaction> _inMonth(List<Transaction> transactions, DateTime month) {
    return transactions.where((t) => t.date.year == month.year && t.date.month == month.month).toList();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
