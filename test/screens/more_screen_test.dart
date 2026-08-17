import 'package:finance_analyzer/models/nav_tab.dart';
import 'package:finance_analyzer/providers/nav_settings_providers.dart';
import 'package:finance_analyzer/screens/more_screen.dart';
import 'package:finance_analyzer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedNavOrderNotifier extends NavOrderNotifier {
  @override
  List<String> build() => kDefaultNavOrder;
}

class _FixedNavHiddenNotifier extends NavHiddenNotifier {
  _FixedNavHiddenNotifier(this._data);
  final Set<String> _data;
  @override
  Set<String> build() => _data;
}

void main() {
  Widget buildApp(Set<String> hidden) => ProviderScope(
        overrides: [
          navOrderProvider.overrideWith(_FixedNavOrderNotifier.new),
          navHiddenProvider.overrideWith(() => _FixedNavHiddenNotifier(hidden)),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const MoreScreen()),
      );

  testWidgets('ohne versteckte Reiter erscheint keine "Ausgeblendete Reiter"-Sektion', (tester) async {
    await tester.pumpWidget(buildApp(const {}));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('AUSGEBLENDETE REITER'), findsNothing);
  });

  testWidgets('ein versteckter Reiter erscheint in der "Ausgeblendete Reiter"-Sektion', (tester) async {
    await tester.pumpWidget(buildApp({'vermoegen'}));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('AUSGEBLENDETE REITER'), findsOneWidget);
    expect(find.text('Vermögen'), findsOneWidget);
  });
}
