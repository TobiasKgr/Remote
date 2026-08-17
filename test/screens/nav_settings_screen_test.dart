import 'package:finance_analyzer/models/nav_tab.dart';
import 'package:finance_analyzer/providers/nav_settings_providers.dart';
import 'package:finance_analyzer/screens/nav_settings_screen.dart';
import 'package:finance_analyzer/theme/app_theme.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedNavOrderNotifier extends NavOrderNotifier {
  final List<String> calls = [];
  @override
  List<String> build() => kDefaultNavOrder;

  @override
  Future<void> moveUp(String key) async => calls.add('up:$key');

  @override
  Future<void> moveDown(String key) async => calls.add('down:$key');
}

class _FixedNavHiddenNotifier extends NavHiddenNotifier {
  final List<String> calls = [];
  @override
  Set<String> build() => const {};

  @override
  Future<void> setHidden(String key, bool hidden) async => calls.add('$key:$hidden');
}

void main() {
  testWidgets('listet alle konfigurierbaren Reiter, Übersicht ohne Sichtbarkeits-Schalter', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final orderNotifier = _FixedNavOrderNotifier();
    final hiddenNotifier = _FixedNavHiddenNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          navOrderProvider.overrideWith(() => orderNotifier),
          navHiddenProvider.overrideWith(() => hiddenNotifier),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const NavSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final tab in kConfigurableNavTabs) {
      expect(find.text(tab.label), findsOneWidget);
    }
    expect(find.text('Immer direkt erreichbar'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(kConfigurableNavTabs.where((t) => t.canHide).length));
  });

  testWidgets('Pfeil-Buttons rufen moveUp/moveDown mit dem richtigen Schlüssel auf', (tester) async {
    final orderNotifier = _FixedNavOrderNotifier();
    final hiddenNotifier = _FixedNavHiddenNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          navOrderProvider.overrideWith(() => orderNotifier),
          navHiddenProvider.overrideWith(() => hiddenNotifier),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const NavSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Erste Zeile: "Vermögen" - der Pfeil nach oben ist deaktiviert (erste
    // Position), der Pfeil nach unten aktiv.
    final firstRowDownButton = find.byIcon(CupertinoIcons.chevron_down).first;
    await tester.tap(firstRowDownButton);
    await tester.pumpAndSettle();

    expect(orderNotifier.calls, contains('down:vermoegen'));
  });

  testWidgets('Schalter für einen versteckbaren Reiter ruft setHidden auf', (tester) async {
    final orderNotifier = _FixedNavOrderNotifier();
    final hiddenNotifier = _FixedNavHiddenNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          navOrderProvider.overrideWith(() => orderNotifier),
          navHiddenProvider.overrideWith(() => hiddenNotifier),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const NavSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    // Der Schalter startet auf "sichtbar" (an) - ein Tap schaltet ihn aus,
    // ruft also setHidden(key, true) auf.
    expect(hiddenNotifier.calls, contains('vermoegen:true'));
  });
}
