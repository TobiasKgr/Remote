/// Local (in-app) reminder notifications. These are shown while the app is
/// open/foregrounded when a budget overrun or spending spike is newly
/// detected - there is no OS-level background scheduling here, since that
/// would require substantial platform-specific setup (WorkManager on
/// Android, BGTaskScheduler on iOS, a service worker + push backend on web)
/// that is out of scope. See [NotificationWatcher].
library;

export 'notification_backend_io.dart' if (dart.library.html) 'notification_backend_web.dart';
