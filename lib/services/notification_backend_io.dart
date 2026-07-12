import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _plugin = FlutterLocalNotificationsPlugin();
bool _initialized = false;

/// flutter_local_notifications doesn't ship a Windows backend - we no-op
/// there rather than crash.
bool get _isSupported => !Platform.isWindows;

Future<void> initializeNotifications() async {
  if (!_isSupported || _initialized) return;

  const settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
    macOS: DarwinInitializationSettings(),
    linux: LinuxInitializationSettings(defaultActionName: 'Öffnen'),
  );
  await _plugin.initialize(settings);

  if (Platform.isIOS) {
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  } else if (Platform.isMacOS) {
    await _plugin
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  } else if (Platform.isAndroid) {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  _initialized = true;
}

Future<void> showNotification({required int id, required String title, required String body}) async {
  if (!_isSupported) return;
  if (!_initialized) await initializeNotifications();

  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'finance_reminders',
      'Finanzen Erinnerungen',
      channelDescription: 'Hinweise zu Budget-Überschreitungen und Ausgabenspitzen',
      importance: Importance.defaultImportance,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
    linux: LinuxNotificationDetails(),
  );
  await _plugin.show(id, title, body, details);
}
