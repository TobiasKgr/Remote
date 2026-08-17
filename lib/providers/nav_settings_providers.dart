import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/nav_tab.dart';
import 'settings_providers.dart';

const _navOrderKey = 'navTabOrder';
const _navHiddenKey = 'navTabHidden';

/// Order of the configurable tabs (see [kConfigurableNavTabs]) in the main
/// navigation bar/rail - "Übersicht" and "Mehr" have fixed roles (home,
/// overflow) but even "Übersicht" can still be moved within this order.
class NavOrderNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final box = ref.watch(settingsBoxProvider);
    final stored = (box.get(_navOrderKey) as List?)?.cast<String>();
    if (stored == null) return kDefaultNavOrder;

    // Drop keys that no longer exist (a tab was removed in a later app
    // version) and append any that aren't in the stored order yet (a tab
    // added later) at the end, so nothing silently disappears either way.
    final valid = kNavTabRegistry.keys.toSet();
    final order = stored.where(valid.contains).toList();
    for (final key in kDefaultNavOrder) {
      if (!order.contains(key)) order.add(key);
    }
    return order;
  }

  Future<void> _persist(List<String> order) async {
    await ref.read(settingsBoxProvider).put(_navOrderKey, order);
    ref.invalidateSelf();
  }

  Future<void> moveUp(String key) async {
    final order = List<String>.from(state);
    final i = order.indexOf(key);
    if (i <= 0) return;
    order
      ..removeAt(i)
      ..insert(i - 1, key);
    await _persist(order);
  }

  Future<void> moveDown(String key) async {
    final order = List<String>.from(state);
    final i = order.indexOf(key);
    if (i == -1 || i >= order.length - 1) return;
    order
      ..removeAt(i)
      ..insert(i + 1, key);
    await _persist(order);
  }
}

final navOrderProvider = NotifierProvider<NavOrderNotifier, List<String>>(NavOrderNotifier.new);

/// Tabs the user chose to tuck under "Mehr" instead of showing directly in
/// the bar - a subset of the hideable keys in [kConfigurableNavTabs].
class NavHiddenNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final box = ref.watch(settingsBoxProvider);
    final stored = (box.get(_navHiddenKey) as List?)?.cast<String>() ?? const <String>[];
    final hideable = kConfigurableNavTabs.where((t) => t.canHide).map((t) => t.key).toSet();
    return stored.where(hideable.contains).toSet();
  }

  Future<void> setHidden(String key, bool hidden) async {
    final tab = kNavTabRegistry[key];
    if (tab == null || !tab.canHide) return;

    final next = Set<String>.from(state);
    if (hidden) {
      next.add(key);
    } else {
      next.remove(key);
    }
    await ref.read(settingsBoxProvider).put(_navHiddenKey, next.toList());
    ref.invalidateSelf();
  }
}

final navHiddenProvider = NotifierProvider<NavHiddenNotifier, Set<String>>(NavHiddenNotifier.new);
