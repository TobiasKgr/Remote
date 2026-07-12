import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/hive_setup.dart';
import 'models/transaction.dart';
import 'services/recurring_transaction_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  await initializeDateFormatting('de_DE');
  await _generateMissingRecurringTransactions();
  runApp(const ProviderScope(child: FinanceAnalyzerApp()));
}

/// Catches up recurring bookings (Abos) that are due since the app was last
/// opened, so the current month always already has them - see
/// [RecurringTransactionService].
Future<void> _generateMissingRecurringTransactions() async {
  final box = Hive.box<Transaction>(transactionBoxName);
  final generated = RecurringTransactionService().generateMissingOccurrences(box.values.toList());
  for (final transaction in generated) {
    await box.put(transaction.id, transaction);
  }
}
