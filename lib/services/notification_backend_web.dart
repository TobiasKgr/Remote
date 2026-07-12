// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<void> initializeNotifications() async {
  if (!html.Notification.supported) return;
  if (html.Notification.permission == 'default') {
    await html.Notification.requestPermission();
  }
}

Future<void> showNotification({required int id, required String title, required String body}) async {
  if (!html.Notification.supported) return;
  if (html.Notification.permission == 'default') {
    await html.Notification.requestPermission();
  }
  if (html.Notification.permission == 'granted') {
    html.Notification(title, body: body);
  }
}
