import 'package:genga/shared/icons/app_icons.dart';

import 'dart:convert';

class JoinRequestPayload {
  final String inviteCode;
  final String spaceName;
  final String memberName;
  final String memberPhone;

  const JoinRequestPayload({
    required this.inviteCode,
    required this.spaceName,
    required this.memberName,
    required this.memberPhone,
  });

  Map<String, dynamic> toJson() => {
    'ic': inviteCode,
    'sn': spaceName,
    'mn': memberName,
    'mp': memberPhone,
  };

  factory JoinRequestPayload.fromJson(Map<String, dynamic> json) {
    return JoinRequestPayload(
      inviteCode: json['ic'] as String,
      spaceName: json['sn'] as String,
      memberName: json['mn'] as String,
      memberPhone: json['mp'] as String,
    );
  }
}

class SpaceInvitePayload {
  final String code;
  final String name;
  final int color;
  final String iconKey;
  final String type;

  const SpaceInvitePayload({
    required this.code,
    required this.name,
    required this.color,
    required this.iconKey,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'c': code,
    'n': name,
    'co': color,
    'i': iconKey,
    't': type,
  };

  factory SpaceInvitePayload.fromJson(Map<String, dynamic> json) {
    return SpaceInvitePayload(
      code: json['c'] as String,
      name: json['n'] as String,
      color: json['co'] as int,
      iconKey: switch (json['i']) {
        final String key => key,
        final int legacy => AppIcons.keyFromLegacy(legacy),
        _ => AppIcons.fallbackKey,
      },
      type: json['t'] as String,
    );
  }
}

class InviteLinkService {
  static String createLink(SpaceInvitePayload payload) {
    final json = jsonEncode(payload.toJson());
    final encoded = base64Url.encode(utf8.encode(json));
    return 'genga://join/$encoded';
  }

  static SpaceInvitePayload? parseLink(Uri uri) {
    String? encoded;

    if (uri.scheme == 'genga' &&
        uri.host.toLowerCase() == 'join' &&
        uri.pathSegments.isNotEmpty) {
      encoded = uri.pathSegments.first;
    } else if (uri.pathSegments.length >= 2 &&
        uri.pathSegments[0].toLowerCase() == 'join') {
      encoded = uri.pathSegments[1];
    }

    if (encoded == null || encoded.isEmpty) return null;

    // Try decoding as base64 payload first (new format).
    try {
      final json = utf8.decode(base64Url.decode(base64Url.normalize(encoded)));
      final map = jsonDecode(json) as Map<String, dynamic>;
      return SpaceInvitePayload.fromJson(map);
    } catch (_) {
      // Not a base64 payload — treat as a raw invite code (legacy format).
      return null;
    }
  }

  static String createJoinRequestLink(JoinRequestPayload payload) {
    final json = jsonEncode(payload.toJson());
    final encoded = base64Url.encode(utf8.encode(json));
    return 'genga://request/$encoded';
  }

  static JoinRequestPayload? parseJoinRequest(Uri uri) {
    final isRequest =
        (uri.scheme == 'genga' && uri.host.toLowerCase() == 'request') ||
        (uri.pathSegments.isNotEmpty &&
            uri.pathSegments[0].toLowerCase() == 'request');
    if (!isRequest) return null;

    String? encoded;
    if (uri.scheme == 'genga' &&
        uri.host.toLowerCase() == 'request' &&
        uri.pathSegments.isNotEmpty) {
      encoded = uri.pathSegments.first;
    } else if (uri.pathSegments.length >= 2) {
      encoded = uri.pathSegments[1];
    }
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final json = utf8.decode(base64Url.decode(base64Url.normalize(encoded)));
      final map = jsonDecode(json) as Map<String, dynamic>;
      return JoinRequestPayload.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static String? parseLegacyCode(Uri uri) {
    String? raw;

    if (uri.scheme == 'genga' &&
        uri.host.toLowerCase() == 'join' &&
        uri.pathSegments.isNotEmpty) {
      raw = uri.pathSegments.first;
    } else if (uri.pathSegments.length >= 2 &&
        uri.pathSegments[0].toLowerCase() == 'join') {
      raw = uri.pathSegments[1];
    }

    if (raw == null || raw.isEmpty) return null;

    // Legacy codes are short uppercase alphanumeric strings (8 chars).
    if (RegExp(r'^[A-Z0-9]{6,12}$').hasMatch(raw.toUpperCase())) {
      return raw.toUpperCase();
    }

    return null;
  }
}
