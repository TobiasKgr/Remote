import 'fixed_cost_radar_service.dart';
import 'recurring_payment_detector.dart';

/// Projected savings from cancelling a chosen set of detected recurring
/// payments ("Was wäre, wenn ich diese Abos kündige?").
class WhatIfResult {
  const WhatIfResult({required this.monthlySavings, required this.months, required this.totalSavings});

  /// Sum of the cancelled groups' monthly-equivalent amounts.
  final double monthlySavings;

  /// The simulated time horizon in months.
  final int months;

  /// [monthlySavings] * [months] - a simple projection, not compounded
  /// (this is about visualizing "what stays in my pocket", not an
  /// investment return).
  final double totalSavings;
}

/// Pure function (no Riverpod dependency): sums the monthly-equivalent cost
/// of [cancelledGroups] and projects it forward over [months]. Only expense
/// groups count - cancelling an income series wouldn't be a "saving".
WhatIfResult computeWhatIfSavings({required List<RecurringPaymentGroup> cancelledGroups, required int months}) {
  final monthlySavings = cancelledGroups.where((g) => g.latestAmount < 0).fold<double>(0, (s, g) => s + monthlyEquivalent(g));
  return WhatIfResult(monthlySavings: monthlySavings, months: months, totalSavings: monthlySavings * months);
}
