import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:genga/app/app_shell.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/models/enums.dart';
import 'package:genga/core/services/analytics_observer.dart';
import 'package:genga/core/services/analytics_service.dart';
import 'package:genga/features/analytics/analytics_screen.dart';
import 'package:genga/features/home/account_detail_screen.dart';
import 'package:genga/features/home/home_screen.dart';
import 'package:genga/features/onboarding/onboarding_screen.dart';
import 'package:genga/features/splash/splash_screen.dart';
import 'package:genga/features/settings/accounts_screen.dart';
import 'package:genga/features/settings/categories_screen.dart';
import 'package:genga/features/settings/recurring_screen.dart';
import 'package:genga/features/settings/settings_screen.dart';
import 'package:genga/features/settings/space_settings_screen.dart';
import 'package:genga/features/transactions/add_transaction_screen.dart';
import 'package:genga/features/transactions/all_transactions_screen.dart';
import 'package:genga/shared/animations/page_route_transitions.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final analytics = ref.read(analyticsServiceProvider);
  return _buildRouter(analytics);
});

GoRouter _buildRouter(AnalyticsService analyticsService) => GoRouter(
  navigatorKey: rootNavigatorKey,
  observers: [GengaAnalyticsObserver(analyticsService)],
  initialLocation: '/splash',
  redirect: (BuildContext context, GoRouterState state) {
    final uri = state.uri;
    if (uri.scheme == 'genga') {
      final host = uri.host.toLowerCase();
      final query = uri.hasQuery ? '?${uri.query}' : '';

      switch (host) {
        case 'add':
          return '/add$query';
        case 'transactions':
          return '/transactions$query';
        case 'home':
          return '/$query';
        case 'settings':
          return '/settings$query';
        case 'accounts':
          return '/accounts$query';
        case 'categories':
          return '/categories$query';
        case 'recurring':
          return '/recurring$query';
        case 'analytics':
          return '/analytics$query';
        case 'onboarding':
          return '/onboarding$query';
        case 'join':
          return '/add';
        default:
          return '/$query';
      }
    }
    return null;
  },
  errorBuilder: (context, state) => addScreenForUri(state.uri),
  routes: [
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/splash',
      pageBuilder: (context, state) => fadeThrough(child: const SplashScreen()),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              tabFade(key: state.pageKey, child: const HomeScreen()),
        ),
        GoRoute(
          path: '/account/:id',
          pageBuilder: (context, state) => heroFade(
            key: state.pageKey,
            child: AccountDetailScreen(
              accountId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/analytics',
          pageBuilder: (context, state) =>
              tabFade(key: state.pageKey, child: const AnalyticsScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              tabFade(key: state.pageKey, child: const SettingsScreen()),
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/onboarding',
      pageBuilder: (context, state) =>
          fadeThrough(child: const OnboardingScreen()),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/add',
      pageBuilder: (context, state) => cupertinoSlide(
        fullscreenDialog: true,
        child: addScreenForUri(state.uri),
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/transactions',
      pageBuilder: (context, state) =>
          cupertinoSlide(child: const AllTransactionsScreen()),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/accounts',
      pageBuilder: (context, state) =>
          cupertinoSlide(child: const AccountsScreen()),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/categories',
      pageBuilder: (context, state) =>
          cupertinoSlide(child: const CategoriesScreen()),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/recurring',
      pageBuilder: (context, state) =>
          cupertinoSlide(child: const RecurringScreen()),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/space-settings',
      pageBuilder: (context, state) => cupertinoSlide(
        child: SpaceSettingsScreen(space: state.extra! as Space),
      ),
    ),
  ],
);

AddTransactionScreen addScreenForUri(Uri uri) {
  final q = uri.queryParameters;
  final type = switch (q['type']?.toLowerCase()) {
    'income' => TransactionType.income,
    'transfer' => TransactionType.transfer,
    'expense' => TransactionType.expense,
    _ => null,
  };
  final rawAmount = q['amount']?.replaceAll(RegExp(r'[^0-9.]'), '');
  final note = q['note']?.trim();
  final rawBalance = q['balance']?.replaceAll(RegExp(r'[^0-9.]'), '');
  return AddTransactionScreen(
    key: ValueKey(uri.query),
    initialType: type,
    initialAmount: rawAmount == null ? null : double.tryParse(rawAmount),
    initialNote: note == null || note.isEmpty ? null : note,
    momoBalance: rawBalance == null ? null : double.tryParse(rawBalance),
    fromShortcut: q['source'] == 'momo',
  );
}
