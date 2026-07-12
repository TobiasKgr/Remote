import 'notification_backend.dart' as backend;

/// Thin wrapper around the platform-specific local-notification backend
/// (see notification_backend.dart) that turns a stable String key into the
/// numeric id the underlying plugin expects.
///
/// These are local, in-app reminders shown while the app is open - not true
/// OS-level background push (see [notification_backend.dart] for why).
class NotificationService {
  const NotificationService();

  Future<void> initialize() => backend.initializeNotifications();

  Future<void> show({required String key, required String title, required String body}) {
    return backend.showNotification(id: key.hashCode & 0x7fffffff, title: title, body: body);
  }
}
