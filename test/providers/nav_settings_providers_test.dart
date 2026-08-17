import 'dart:io';

import 'package:finance_analyzer/models/nav_tab.dart';
import 'package:finance_analyzer/providers/nav_settings_providers.dart';
import 'package:finance_analyzer/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box box;
  var boxCounter = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('finance_analyzer_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('settings_test_${boxCounter++}');
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(overrides: [settingsBoxProvider.overrideWithValue(box)]);
    addTearDown(container.dispose);
    return container;
  }

  group('navOrderProvider', () {
    test('liefert die Standard-Reihenfolge, wenn noch nichts gespeichert wurde', () {
      final container = buildContainer();
      expect(container.read(navOrderProvider), kDefaultNavOrder);
    });

    test('moveDown verschiebt einen Reiter nach hinten und persistiert das Ergebnis', () async {
      final container = buildContainer();
      await container.read(navOrderProvider.notifier).moveDown('vermoegen');
      final order = container.read(navOrderProvider);
      expect(order[0], 'budgets');
      expect(order[1], 'vermoegen');

      // Über eine neue Provider-Instanz auf derselben Box gelesen bleibt
      // die Änderung erhalten (persistiert, nicht nur In-Memory-State).
      final reopened = ProviderContainer(overrides: [settingsBoxProvider.overrideWithValue(box)]);
      addTearDown(reopened.dispose);
      expect(reopened.read(navOrderProvider)[0], 'budgets');
    });

    test('moveUp verschiebt einen Reiter nach vorne', () async {
      final container = buildContainer();
      await container.read(navOrderProvider.notifier).moveUp('budgets');
      final order = container.read(navOrderProvider);
      expect(order[0], 'budgets');
      expect(order[1], 'vermoegen');
    });

    test('moveUp am Anfang der Liste ist ein No-Op', () async {
      final container = buildContainer();
      await container.read(navOrderProvider.notifier).moveUp(kDefaultNavOrder.first);
      expect(container.read(navOrderProvider), kDefaultNavOrder);
    });

    test('moveDown am Ende der Liste ist ein No-Op', () async {
      final container = buildContainer();
      await container.read(navOrderProvider.notifier).moveDown(kDefaultNavOrder.last);
      expect(container.read(navOrderProvider), kDefaultNavOrder);
    });

    test('unbekannte gespeicherte Schlüssel werden verworfen, fehlende ergänzt', () async {
      await box.put('navTabOrder', ['nicht_mehr_existent', 'budgets']);
      final container = buildContainer();
      final order = container.read(navOrderProvider);

      expect(order.contains('nicht_mehr_existent'), isFalse);
      expect(order.first, 'budgets');
      expect(order.toSet(), kNavTabRegistry.keys.toSet());
    });
  });

  group('navHiddenProvider', () {
    test('ist standardmäßig leer', () {
      final container = buildContainer();
      expect(container.read(navHiddenProvider), isEmpty);
    });

    test('setHidden versteckt einen Reiter und persistiert das Ergebnis', () async {
      final container = buildContainer();
      await container.read(navHiddenProvider.notifier).setHidden('vermoegen', true);
      expect(container.read(navHiddenProvider), {'vermoegen'});

      await container.read(navHiddenProvider.notifier).setHidden('vermoegen', false);
      expect(container.read(navHiddenProvider), isEmpty);
    });

    test('"Übersicht" lässt sich nicht verstecken', () async {
      final container = buildContainer();
      await container.read(navHiddenProvider.notifier).setHidden('uebersicht', true);
      expect(container.read(navHiddenProvider), isEmpty);
    });
  });
}
