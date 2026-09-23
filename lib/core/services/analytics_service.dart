import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// PostHog is commented out until a real API key is configured.
// To re-enable: uncomment the posthog_flutter import, uncomment
// _initPostHog body, and replace the API key placeholder.
// import 'package:posthog_flutter/posthog_flutter.dart';

const _kAnalyticsEnabled = 'pref_analytics_enabled';
const _kAnonymousId = 'pref_anonymous_id';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

class AnalyticsService {
  bool _enabled = false;
  bool _initialized = false;
  String? _anonymousId;
  DateTime? _sessionStart;
  int _transactionsThisSession = 0;

  bool get isEnabled => _enabled;

  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kAnalyticsEnabled) ?? false;

    var id = prefs.getString(_kAnonymousId);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_kAnonymousId, id);
    }
    _anonymousId = id;

    // PostHog init is disabled until a real API key is set.
    // if (_enabled) {
    //   await _initPostHog();
    // }

    _initialized = true;
  }

  // Future<void> _initPostHog() async {
  //   try {
  //     final config = PostHogConfig(
  //       'phc_YOUR_POSTHOG_API_KEY', // TODO: replace
  //     );
  //     config.host = 'https://eu.i.posthog.com';
  //     config.captureApplicationLifecycleEvents = false;
  //     config.debug = kDebugMode;
  //     await Posthog().setup(config);
  //     if (_anonymousId != null) {
  //       await Posthog().identify(userId: _anonymousId!);
  //     }
  //   } catch (e) {
  //     debugPrint('PostHog init failed: $e');
  //   }
  // }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAnalyticsEnabled, enabled);

    // PostHog enable/disable is stubbed out.
    // if (enabled) await _initPostHog();

    trackEvent('consent_changed', {'analytics_enabled': enabled});

    // if (!enabled) {
    //   try { await Posthog().disable(); } catch (_) {}
    // }
  }

  void trackEvent(String eventName, [Map<String, dynamic>? properties]) {
    if (!_enabled) return;

    // PostHog capture is stubbed out — events are logged in debug mode only.
    final props = {
      ...?properties,
      if (_anonymousId != null) 'device_id': _anonymousId!,
    };
    debugPrint('[Analytics] $eventName $props');

    // try {
    //   Posthog().capture(
    //     eventName: eventName,
    //     properties: {
    //       ...?properties,
    //       if (_anonymousId != null) 'device_id': _anonymousId!,
    //     },
    //   );
    // } catch (e) {
    //   debugPrint('Analytics trackEvent failed: $e');
    // }
  }

  void trackScreen(String screenName) {
    if (!_enabled) return;

    debugPrint('[Analytics] screen: $screenName');

    // try {
    //   Posthog().screen(screenName: screenName);
    // } catch (e) {
    //   debugPrint('Analytics trackScreen failed: $e');
    // }
  }

  void startSession() {
    _sessionStart = DateTime.now();
    _transactionsThisSession = 0;

    final now = DateTime.now();
    trackEvent('app_opened', {
      'hour_of_day': now.hour,
      'day_of_week': now.weekday,
      'platform': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
    });
  }

  void endSession() {
    if (_sessionStart == null) return;

    final duration = DateTime.now().difference(_sessionStart!).inSeconds;
    trackEvent('app_backgrounded', {
      'session_duration_seconds': duration,
      'transactions_this_session': _transactionsThisSession,
    });

    _sessionStart = null;
  }

  void incrementTransactionCount() {
    _transactionsThisSession++;
  }

  Future<void> flush() async {
    if (!_enabled) return;
    // try { await Posthog().flush(); } catch (_) {}
  }
}
