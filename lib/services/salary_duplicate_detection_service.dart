import '../models/transaction.dart';

/// Finds an existing income transaction in [existing] that looks like it
/// could be the *same* payment as [date]/[amount] - same month, and the
/// amount matching exactly (to the cent) or within [relativeTolerance].
/// Used to catch a salary payment being counted twice: once via a
/// Gehaltsabrechnung import (which creates its own income transaction) and
/// once via a Kontoauszug import (which independently picks up the same
/// payment as it landed in the account) - neither import flow otherwise has
/// any way of knowing about the other.
Transaction? findLikelyMatchingIncome({
  required DateTime date,
  required double amount,
  required Iterable<Transaction> existing,
  double relativeTolerance = 0.02,
}) {
  final target = amount.abs();
  if (target <= 0) return null;

  for (final t in existing) {
    if (t.amount < 0) continue;
    if (t.date.year != date.year || t.date.month != date.month) continue;
    final diff = (t.amount.abs() - target).abs();
    if (diff < 0.01 || diff / target <= relativeTolerance) return t;
  }
  return null;
}
