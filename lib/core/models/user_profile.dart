import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String displayName;
  final String phone;
  final bool isVerified;

  const UserProfile({
    this.displayName = '',
    this.phone = '',
    this.isVerified = false,
  });

  bool get hasProfile => displayName.isNotEmpty;
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
      return UserProfileNotifier();
    });

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(const UserProfile()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = UserProfile(
      displayName: prefs.getString('user_display_name') ?? '',
      phone: prefs.getString('user_phone') ?? '',
      isVerified: prefs.getBool('user_verified') ?? false,
    );
  }

  Future<void> setDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_display_name', name);
    state = UserProfile(
      displayName: name,
      phone: state.phone,
      isVerified: state.isVerified,
    );
  }

  Future<void> setPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_phone', phone);
    state = UserProfile(
      displayName: state.displayName,
      phone: phone,
      isVerified: state.isVerified,
    );
  }

  Future<void> setVerified(bool verified) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_verified', verified);
    state = UserProfile(
      displayName: state.displayName,
      phone: state.phone,
      isVerified: verified,
    );
  }
}
