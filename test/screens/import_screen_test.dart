import 'package:desktop_drop/desktop_drop.dart';
import 'package:finance_analyzer/models/account.dart';
import 'package:finance_analyzer/models/category.dart';
import 'package:finance_analyzer/models/person.dart';
import 'package:finance_analyzer/providers/account_providers.dart';
import 'package:finance_analyzer/providers/category_providers.dart';
import 'package:finance_analyzer/providers/person_providers.dart';
import 'package:finance_analyzer/screens/import_screen.dart';
import 'package:finance_analyzer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyCategoryNotifier extends CategoryNotifier {
  @override
  List<Category> build() => [];
}

class _EmptyPersonNotifier extends PersonNotifier {
  @override
  List<Person> build() => [];
}

class _EmptyAccountNotifier extends AccountNotifier {
  @override
  List<Account> build() => [];
}

void main() {
  testWidgets('leerer Zustand rendert Hinweistext, Auswahl-Button und ist als Drop-Ziel eingerichtet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryNotifierProvider.overrideWith(_EmptyCategoryNotifier.new),
          personNotifierProvider.overrideWith(_EmptyPersonNotifier.new),
          accountNotifierProvider.overrideWith(_EmptyAccountNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ImportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('PDF-Import'), findsOneWidget);
    expect(find.text('PDF auswählen'), findsOneWidget);
    expect(find.textContaining('Drag & Drop'), findsOneWidget);
    expect(find.byType(DropTarget), findsOneWidget);
  });
}
