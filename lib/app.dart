import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/root_shell.dart';

class FinanceAnalyzerApp extends StatelessWidget {
  const FinanceAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finanzen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true, brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      locale: const Locale('de', 'DE'),
      supportedLocales: const [Locale('de', 'DE'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootShell(),
    );
  }
}
