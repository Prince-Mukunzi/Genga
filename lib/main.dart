import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// sentry_flutter 8.14.2 has a Swift compiler incompatibility with Xcode 16+.
// Stubbed out until upgraded to ^9.0.0 and a real DSN is configured.
// To re-enable: uncomment the import and SentryFlutter.init block below,
// remove the plain runApp call, and update pubspec to sentry_flutter: ^9.0.0.
// import 'package:sentry_flutter/sentry_flutter.dart';
import 'app/app.dart';
import 'core/services/analytics_service.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final startTime = DateTime.now();

  final notificationService = NotificationService();
  final analyticsService = AnalyticsService();

  try {
    await notificationService.init();
  } catch (_) {}

  await analyticsService.init();

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
        analyticsServiceProvider.overrideWithValue(analyticsService),
      ],
      child: const GengaApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    analyticsService.trackEvent('app_startup_time', {'duration_ms': duration});
  });

  // await SentryFlutter.init(
  //   (options) {
  //     options.dsn = 'https://YOUR_SENTRY_DSN@sentry.io/YOUR_PROJECT_ID';
  //     options.tracesSampleRate = 0.2;
  //     options.environment = 'production';
  //   },
  //   appRunner: () {
  //     runApp(
  //       ProviderScope(
  //         overrides: [
  //           notificationServiceProvider.overrideWithValue(notificationService),
  //           analyticsServiceProvider.overrideWithValue(analyticsService),
  //         ],
  //         child: const GengaApp(),
  //       ),
  //     );
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       final duration = DateTime.now().difference(startTime).inMilliseconds;
  //       analyticsService.trackEvent('app_startup_time', {'duration_ms': duration});
  //     });
  //   },
  // );
}
