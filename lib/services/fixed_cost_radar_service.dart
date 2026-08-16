import '../models/transaction.dart';
import 'recurring_payment_detector.dart';

/// How much of the household's income is already committed to detected
/// recurring expenses - a well-known personal-finance sanity metric that
/// nothing in the app computed before. Pure function, no Riverpod
/// dependency, so it stays directly unit-testable.
class FixedCostRadarResult {
  const FixedCostRadarResult({required this.monthlyFixedCosts, required this.averageMonthlyIncome});

  /// Every detected recurring expense, converted to a monthly-equivalent
  /// amount (weekly *52/12, yearly /12) and summed.
  final double monthlyFixedCosts;

  /// Average of the last few months that actually had income booked
  /// (months with none are skipped rather than counted as zero, so a
  /// short history doesn't drag the average down artificially).
  final double averageMonthlyIncome;

  /// Null when there's no income to divide by.
  double? get ratio => averageMonthlyIncome <= 0 ? null : monthlyFixedCosts / averageMonthlyIncome;
}

double _monthlyEquivalent(RecurringPaymentGroup group) {
  final amount = group.latestAmount.abs();
  return switch (group.rhythm) {
    RecurrenceRhythm.weekly => amount * 52 / 12,
    RecurrenceRhythm.monthly => amount,
    RecurrenceRhythm.yearly => amount / 12,
  };
}

double computeAverageMonthlyIncome(List<Transaction> transactions, {DateTime? referenceDate, int lookbackMonths = 6}) {
  final reference = referenceDate ?? DateTime.now();
  final incomeByMonth = <String, double>{};

  for (final t in transactions) {
    if (!t.isIncome || t.isTransfer) continue;
    final monthsAgo = (reference.year - t.date.year) * 12 + (reference.month - t.date.month);
    if (monthsAgo < 0 || monthsAgo >= lookbackMonths) continue;
    final key = '${t.date.year}-${t.date.month}';
    incomeByMonth[key] = (incomeByMonth[key] ?? 0) + t.amount;
  }
  if (incomeByMonth.isEmpty) return 0;
  return incomeByMonth.values.fold<double>(0, (s, v) => s + v) / incomeByMonth.length;
}

FixedCostRadarResult computeFixedCostRadar({
  required List<RecurringPaymentGroup> recurringGroups,
  required List<Transaction> allTransactions,
  DateTime? referenceDate,
  int lookbackMonths = 6,
}) {
  final monthlyFixedCosts =
      recurringGroups.where((g) => g.latestAmount < 0).fold<double>(0, (s, g) => s + _monthlyEquivalent(g));
  final averageIncome = computeAverageMonthlyIncome(allTransactions, referenceDate: referenceDate, lookbackMonths: lookbackMonths);
  return FixedCostRadarResult(monthlyFixedCosts: monthlyFixedCosts, averageMonthlyIncome: averageIncome);
}
