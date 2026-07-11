import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/optimization_service.dart';
import 'category_providers.dart';
import 'person_providers.dart';
import 'transaction_providers.dart';

final insightsProvider = Provider<List<Insight>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final personFilter = ref.watch(selectedPersonFilterProvider);
  final allTransactions = ref.watch(transactionNotifierProvider);
  final categories = ref.watch(categoryNotifierProvider);

  final transactions = filterByPerson(allTransactions, personFilter, (t) => t.personId).toList();
  return OptimizationService().analyze(transactions, categories, month);
});
