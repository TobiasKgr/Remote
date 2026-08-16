import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/recurring_payment_detector.dart';
import 'person_providers.dart';
import 'transaction_providers.dart';

/// Auto-detected recurring payments across the whole booking history
/// (not just one month/year), filtered by the shared person filter like
/// the rest of the app's overview screens.
final recurringPaymentsProvider = Provider((ref) {
  final personFilter = ref.watch(selectedPersonFilterProvider);
  final all = ref.watch(transactionNotifierProvider);
  final filtered = filterByPerson(all, personFilter, (t) => t.personId).toList();
  return const RecurringPaymentDetector().detect(filtered);
});
