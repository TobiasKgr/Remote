import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cost_trend_service.dart';
import 'category_providers.dart';
import 'person_providers.dart';
import 'recurring_payment_providers.dart';
import 'transaction_providers.dart';

/// "Kostentrends" year overview: recurring payment series plus category-level
/// spending trends, pivoted across [selectedYearProvider]'s 12 months. Uses
/// the full (not year-limited) booking history for detection, same as
/// [recurringPaymentsProvider], since a trend/rhythm needs more than one
/// year's data to recognize.
final costTrendProvider = Provider<CostTrendData>((ref) {
  final personFilter = ref.watch(selectedPersonFilterProvider);
  final all = ref.watch(transactionNotifierProvider);
  final filtered = filterByPerson(all, personFilter, (t) => t.personId).toList();
  final year = ref.watch(selectedYearProvider);
  final categories = ref.watch(categoryNotifierProvider);
  final recurringGroups = ref.watch(recurringPaymentsProvider);

  return computeCostTrends(
    allTransactions: filtered,
    categories: categories,
    recurringGroups: recurringGroups,
    year: year,
  );
});
