import '../models/transaction.dart';
import '../utils/description_normalizer.dart';

/// How often a detected [RecurringPaymentGroup] repeats.
enum RecurrenceRhythm { weekly, monthly, yearly }

extension RecurrenceRhythmLabel on RecurrenceRhythm {
  String get label => switch (this) {
        RecurrenceRhythm.weekly => 'Wöchentlich',
        RecurrenceRhythm.monthly => 'Monatlich',
        RecurrenceRhythm.yearly => 'Jährlich',
      };
}

/// One detected recurring payment: every booking the detector grouped
/// together as "the same subscription/contract", sorted oldest to newest.
class RecurringPaymentGroup {
  const RecurringPaymentGroup({required this.description, required this.rhythm, required this.transactions});

  final String description;
  final RecurrenceRhythm rhythm;

  /// Oldest first, newest last.
  final List<Transaction> transactions;

  Transaction get latest => transactions.last;
  DateTime get lastDate => latest.date;
  double get latestAmount => latest.amount;
  int get occurrenceCount => transactions.length;
}

/// Detects recurring payments (subscriptions/contracts) purely from booking
/// patterns - similar amount, similar/same description, regular interval -
/// without requiring the user to have flagged anything as recurring first.
/// Kept as its own class (rather than folded into [RecurringTransactionService]
/// or [OptimizationService], which both assume [Transaction.isRecurring] is
/// already set) so it stays independently extensible, e.g. for future
/// cancellation reminders.
class RecurringPaymentDetector {
  const RecurringPaymentDetector({
    this.minOccurrences = 3,
    this.amountTolerance = 0.05,
    this.rhythmMatchThreshold = 0.6,
  });

  /// Minimum number of bookings before a pattern counts as "recurring"
  /// rather than coincidence.
  final int minOccurrences;

  /// Relative amount tolerance (0.05 = ±5%) for two bookings to count as
  /// "the same" payment amount; a difference under one cent always counts
  /// regardless of tolerance (covers exact-match rounding).
  final double amountTolerance;

  /// Share of gaps between consecutive bookings that must fall within a
  /// rhythm's day-range for the whole group to count as that rhythm -
  /// below 1.0 so a single skipped/shifted payment doesn't disqualify an
  /// otherwise-regular series.
  final double rhythmMatchThreshold;

  List<RecurringPaymentGroup> detect(List<Transaction> transactions) {
    final relevant = transactions.where((t) => !t.isTransfer).toList();

    final byDescription = <String, List<Transaction>>{};
    for (final t in relevant) {
      final key = normalizeDescription(t.description);
      if (key.isEmpty) continue;
      byDescription.putIfAbsent(key, () => []).add(t);
    }

    final groups = <RecurringPaymentGroup>[];
    for (final entries in byDescription.values) {
      for (final cluster in _clusterByAmount(entries)) {
        if (cluster.length < minOccurrences) continue;
        cluster.sort((a, b) => a.date.compareTo(b.date));

        final rhythm = _detectRhythm(cluster);
        if (rhythm == null) continue;

        groups.add(RecurringPaymentGroup(description: cluster.last.description.trim(), rhythm: rhythm, transactions: cluster));
      }
    }

    groups.sort((a, b) => b.lastDate.compareTo(a.lastDate));
    return groups;
  }

  /// Greedily groups same-description bookings whose amounts are within
  /// [amountTolerance] of each other, so e.g. a weekly REWE run (same shop,
  /// wildly different totals) isn't mistaken for a subscription while a
  /// streaming Abo whose price nudges up once is still recognized as one
  /// series.
  List<List<Transaction>> _clusterByAmount(List<Transaction> entries) {
    final sorted = List<Transaction>.from(entries)..sort((a, b) => a.amount.abs().compareTo(b.amount.abs()));
    final clusters = <List<Transaction>>[];

    for (final t in sorted) {
      List<Transaction>? match;
      for (final cluster in clusters) {
        if (_amountsClose(_clusterAverage(cluster), t.amount)) {
          match = cluster;
          break;
        }
      }
      if (match != null) {
        match.add(t);
      } else {
        clusters.add([t]);
      }
    }
    return clusters;
  }

  double _clusterAverage(List<Transaction> cluster) => cluster.fold<double>(0, (s, t) => s + t.amount) / cluster.length;

  bool _amountsClose(double a, double b) {
    final diff = (a.abs() - b.abs()).abs();
    if (diff < 0.01) return true;
    if (a == 0) return false;
    return diff / a.abs() <= amountTolerance;
  }

  RecurrenceRhythm? _detectRhythm(List<Transaction> sortedByDate) {
    final gaps = <int>[];
    for (var i = 1; i < sortedByDate.length; i++) {
      gaps.add(sortedByDate[i].date.difference(sortedByDate[i - 1].date).inDays);
    }
    if (gaps.isEmpty) return null;

    double shareInRange(int lo, int hi) => gaps.where((g) => g >= lo && g <= hi).length / gaps.length;

    if (shareInRange(5, 9) >= rhythmMatchThreshold) return RecurrenceRhythm.weekly;
    if (shareInRange(24, 36) >= rhythmMatchThreshold) return RecurrenceRhythm.monthly;
    if (shareInRange(350, 380) >= rhythmMatchThreshold) return RecurrenceRhythm.yearly;
    return null;
  }
}
