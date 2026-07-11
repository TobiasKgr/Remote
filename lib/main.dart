import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/hive_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  await initializeDateFormatting('de_DE');
  runApp(const ProviderScope(child: FinanceAnalyzerApp()));
}
