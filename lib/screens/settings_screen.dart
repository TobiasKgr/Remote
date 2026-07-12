import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_providers.dart';
import '../services/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Erinnerungen'),
              subtitle: const Text(
                'Benachrichtigt dich, während die App geöffnet ist, wenn ein Budget '
                'überschritten oder eine Ausgabenspitze erkannt wird. Keine '
                'Hintergrund-Benachrichtigungen bei geschlossener App; unter Windows '
                'derzeit nicht unterstützt.',
              ),
              value: notificationsEnabled,
              onChanged: (value) async {
                if (value) {
                  await const NotificationService().initialize();
                }
                await ref.read(notificationsEnabledProvider.notifier).setEnabled(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
