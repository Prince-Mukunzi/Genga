import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/core/database/database.dart';

import 'package:genga/shared/constants/space_constants.dart';

import 'database_provider.dart';

final spacesProvider = StreamProvider<List<Space>>((ref) {
  return ref.watch(databaseProvider).watchAllSpaces();
});

final activeSpaceProvider = StreamProvider<Space?>((ref) {
  return ref.watch(databaseProvider).watchActiveSpace();
});

final spaceColorProvider = Provider<Color>((ref) {
  final space = ref.watch(activeSpaceProvider).valueOrNull;
  if (space != null) return kSpaceColor;
  return const Color(0xFF6366F1);
});

final spaceMembersProvider = StreamProvider.family<List<SpaceMember>, int>((
  ref,
  spaceId,
) {
  return ref.watch(databaseProvider).watchSpaceMembers(spaceId);
});

final activeSpaceMembersProvider = StreamProvider<List<SpaceMember>>((ref) {
  final space = ref.watch(activeSpaceProvider).valueOrNull;
  if (space == null) return const Stream.empty();
  return ref.watch(databaseProvider).watchSpaceMembers(space.id);
});

final currentUserRoleProvider = Provider<String>((ref) {
  final members = ref.watch(activeSpaceMembersProvider).valueOrNull ?? [];
  for (final m in members) {
    if (m.isCurrentUser) return m.role;
  }
  return 'admin';
});

final isSpaceAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserRoleProvider) == 'admin';
});

final isSharedSpaceProvider = Provider<bool>((ref) {
  final space = ref.watch(activeSpaceProvider).valueOrNull;
  if (space == null) return false;
  return space.type != 'personal';
});

final currentUserNameProvider = Provider<String>((ref) {
  final members = ref.watch(activeSpaceMembersProvider).valueOrNull ?? [];
  for (final m in members) {
    if (m.isCurrentUser) return m.displayName;
  }
  return 'Me';
});

final pendingMembersProvider = StreamProvider.family<List<SpaceMember>, int>((
  ref,
  spaceId,
) {
  return ref.watch(databaseProvider).watchPendingMembers(spaceId);
});

final pendingMemberCountProvider = StreamProvider.family<int, int>((
  ref,
  spaceId,
) {
  return ref.watch(databaseProvider).watchPendingMemberCount(spaceId);
});

final spaceNotificationsProvider =
    StreamProvider.family<List<SpaceNotification>, int>((ref, spaceId) {
      return ref.watch(databaseProvider).watchAllNotifications(spaceId);
    });

final unreadNotificationCountProvider = StreamProvider.family<int, int>((
  ref,
  spaceId,
) {
  return ref.watch(databaseProvider).watchUnreadNotificationCount(spaceId);
});
