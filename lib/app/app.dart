import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/core/providers/preferences_provider.dart';
import 'package:genga/core/services/analytics_service.dart';
import 'package:genga/core/services/invite_link_service.dart';
import 'package:genga/core/services/notification_service.dart';
import 'package:genga/core/services/widget_data_service.dart';
import 'package:genga/features/settings/join_space_sheet.dart';
import 'package:genga/shared/widgets/genga_toast.dart';

import 'router.dart';

class GengaApp extends ConsumerStatefulWidget {
  const GengaApp({super.key});

  @override
  ConsumerState<GengaApp> createState() => _GengaAppState();
}

class _GengaAppState extends ConsumerState<GengaApp>
    with WidgetsBindingObserver {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLinks = AppLinks();
    _linkSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
    _appLinks.getInitialLink().then((uri) async {
      if (uri == null) return;
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _handleDeepLink(uri);
    });

    // Sync widget data on cold start.
    Future.microtask(
      () => ref.read(widgetDataServiceProvider).updateWidgetData(),
    );

    ref.read(analyticsServiceProvider).startSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final analytics = ref.read(analyticsServiceProvider);

    if (state == AppLifecycleState.resumed) {
      ref.read(widgetDataServiceProvider).updateWidgetData();
      ref.read(preferencesProvider.notifier).reschedule();
      analytics.startSession();
    } else if (state == AppLifecycleState.paused) {
      analytics.endSession();
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final db = ref.read(databaseProvider);

    final joinRequest = InviteLinkService.parseJoinRequest(uri);
    if (joinRequest != null) {
      await _handleJoinRequest(db, joinRequest);
      return;
    }

    final isJoinLink =
        (uri.scheme == 'genga' && uri.host.toLowerCase() == 'join') ||
        (uri.pathSegments.isNotEmpty &&
            uri.pathSegments[0].toLowerCase() == 'join');

    if (!isJoinLink) return;

    final payload = InviteLinkService.parseLink(uri);
    if (payload != null) {
      await _handleInvitePayload(db, payload);
      return;
    }

    final legacyCode = InviteLinkService.parseLegacyCode(uri);
    if (legacyCode != null) {
      await _handleLegacyCode(db, legacyCode);
    }
  }

  Future<void> _handleInvitePayload(
    AppDatabase db,
    SpaceInvitePayload payload,
  ) async {
    final existing = await db.getSpaceByInviteCode(payload.code);

    if (existing != null) {
      final member = await db.getCurrentUserMember(existing.id);
      if (!mounted) return;
      if (member != null) {
        _showToast('Already a member of ${existing.name}');
        return;
      }
      _showJoinSheet(existing);
      return;
    }

    if (!mounted) return;

    final spaceId = await db.insertSpaceFromInvite(
      SpacesCompanion.insert(
        name: payload.name,
        color: payload.color,
        iconKey: payload.iconKey,
        type: Value(payload.type),
        inviteCode: Value(payload.code),
      ),
    );

    final space = await db.getSpaceById(spaceId);
    if (!mounted || space == null) return;

    _showJoinSheet(space);
  }

  Future<void> _handleJoinRequest(
    AppDatabase db,
    JoinRequestPayload request,
  ) async {
    final space = await db.getSpaceByInviteCode(request.inviteCode);
    if (!mounted) return;

    if (space == null) {
      _showToast('Unknown space');
      return;
    }

    final currentUser = await db.getCurrentUserMember(space.id);
    if (currentUser == null || currentUser.role != 'admin') {
      _showToast('Only admins can approve requests');
      return;
    }

    await db.addPendingMember(
      space.id,
      displayName: request.memberName,
      phone: request.memberPhone,
    );

    await db.insertNotification(
      SpaceNotificationsCompanion.insert(
        spaceId: space.id,
        type: 'join_request',
        title: 'Join Request',
        body: '${request.memberName} wants to join ${space.name}',
        payload: Value('${request.memberName}|${request.memberPhone}'),
      ),
    );

    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.showJoinRequest(
      memberName: request.memberName,
      spaceName: space.name,
    );

    if (!mounted) return;
    _showToast('${request.memberName} wants to join ${space.name}');
  }

  Future<void> _handleLegacyCode(AppDatabase db, String code) async {
    final space = await db.getSpaceByInviteCode(code);
    if (!mounted) return;

    if (space == null) {
      _showToast('Invalid invite code');
      return;
    }

    final member = await db.getCurrentUserMember(space.id);
    if (member != null) {
      _showToast('Already a member of ${space.name}');
      return;
    }

    _showJoinSheet(space);
  }

  void _showToast(String message) {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext != null) {
      showGengaToast(navContext, message);
    }
  }

  void _showJoinSheet(Space space) {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    showJoinSpaceSheet(context: navContext, ref: ref, space: space);
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(routerProvider);

    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Genga',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: GengaColors.offWhite,
        scaffoldBackgroundColor: GengaColors.background,
        barBackgroundColor: GengaColors.background,
        textTheme: const CupertinoTextThemeData(
          textStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            color: GengaColors.textPrimary,
          ),
        ),
      ),
      routerConfig: goRouter,
    );
  }
}
