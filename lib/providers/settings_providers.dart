import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../data/hive_setup.dart';

final settingsBoxProvider = Provider<Box>((ref) => Hive.box(settingsBoxName));

const _notificationsEnabledKey = 'notificationsEnabled';

/// Whether local reminder notifications (budget overruns, spending spikes)
/// are enabled. Defaults to off - the user has to opt in explicitly.
class NotificationsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(settingsBoxProvider).get(_notificationsEnabledKey, defaultValue: false) as bool;
  }

  Future<void> setEnabled(bool value) async {
    await ref.read(settingsBoxProvider).put(_notificationsEnabledKey, value);
    ref.invalidateSelf();
  }
}

final notificationsEnabledProvider = NotifierProvider<NotificationsEnabledNotifier, bool>(NotificationsEnabledNotifier.new);
