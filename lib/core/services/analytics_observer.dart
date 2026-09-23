import 'package:flutter/widgets.dart';
import 'package:genga/core/services/analytics_service.dart';

class GengaAnalyticsObserver extends NavigatorObserver {
  final AnalyticsService _analytics;

  GengaAnalyticsObserver(this._analytics);

  static const _routeToScreenName = <String, String>{
    '/': 'home',
    '/add': 'add_transaction',
    '/transactions': 'all_transactions',
    '/settings': 'settings',
    '/accounts': 'accounts',
    '/categories': 'categories',
    '/recurring': 'recurring',
    '/analytics': 'analytics',
    '/space-settings': 'space_settings',
    '/onboarding': 'onboarding',
  };

  void _trackRoute(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null) return;

    final screenName = _routeToScreenName[name] ?? name;
    _analytics.trackScreen(screenName);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _trackRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _trackRoute(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _trackRoute(previousRoute);
  }
}
