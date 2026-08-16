import 'package:finance_analyzer/models/custom_import_profile.dart';
import 'package:finance_analyzer/providers/custom_import_profile_providers.dart';
import 'package:finance_analyzer/screens/format_assistant_screen.dart';
import 'package:finance_analyzer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FixedCustomImportProfileNotifier extends CustomImportProfileNotifier {
  @override
  List<CustomImportProfile> build() => const [];

  final List<CustomImportProfile> added = [];

  @override
  Future<void> add(CustomImportProfile profile) async {
    added.add(profile);
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('de_DE'));

  Widget buildApp(_FixedCustomImportProfileNotifier notifier) => ProviderScope(
        overrides: [customImportProfileNotifierProvider.overrideWith(() => notifier)],
        child: MaterialApp(theme: AppTheme.light, home: const FormatAssistantScreen()),
      );

  testWidgets('ohne Beispieltext ist "Format speichern" deaktiviert', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final notifier = _FixedCustomImportProfileNotifier();
    await tester.pumpWidget(buildApp(notifier));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Format anlernen'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byWidgetPredicate((w) => w is FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('Vorschau erkennt Buchungen aus eingefügtem Beispieltext', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final notifier = _FixedCustomImportProfileNotifier();
    await tester.pumpWidget(buildApp(notifier));

    await tester.enterText(find.byType(TextField).first, '15.03.2026 REWE SAGT DANKE -45,67');
    await tester.pumpAndSettle();

    expect(find.textContaining('1 Buchung(en) erkannt'), findsOneWidget);
    expect(find.text('REWE SAGT DANKE'), findsOneWidget);
  });

  testWidgets('Format speichern legt ein neues Profil an', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final notifier = _FixedCustomImportProfileNotifier();
    await tester.pumpWidget(buildApp(notifier));

    await tester.enterText(find.byType(TextField).first, '15.03.2026 REWE SAGT DANKE -45,67');
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name (z. B. Bankname)'), 'Meine Testbank');
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byWidgetPredicate((w) => w is FilledButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byWidgetPredicate((w) => w is FilledButton));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(notifier.added, hasLength(1));
    expect(notifier.added.single.name, 'Meine Testbank');
  });
}
