import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kShortcutAdded = 'momo_setup_shortcut_added';
const _kAutomationDone = 'momo_setup_automation_done';
const _kCaptured = 'momo_setup_captured';

class MomoSetup {
  final bool shortcutAdded;
  final bool automationDone;
  final bool captured;

  const MomoSetup({
    this.shortcutAdded = false,
    this.automationDone = false,
    this.captured = false,
  });
}

class MomoSetupNotifier extends StateNotifier<MomoSetup> {
  MomoSetupNotifier() : super(const MomoSetup()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = MomoSetup(
      shortcutAdded: prefs.getBool(_kShortcutAdded) ?? false,
      automationDone: prefs.getBool(_kAutomationDone) ?? false,
      captured: prefs.getBool(_kCaptured) ?? false,
    );
  }

  Future<void> markShortcutAdded() => _set(_kShortcutAdded);

  Future<void> markAutomationDone() => _set(_kAutomationDone);

  // A link from the shortcut proves every earlier step worked.
  Future<void> markCaptured() async {
    await _set(_kShortcutAdded);
    await _set(_kAutomationDone);
    await _set(_kCaptured);
  }

  Future<void> _set(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
    state = MomoSetup(
      shortcutAdded: prefs.getBool(_kShortcutAdded) ?? false,
      automationDone: prefs.getBool(_kAutomationDone) ?? false,
      captured: prefs.getBool(_kCaptured) ?? false,
    );
  }
}

final momoSetupProvider = StateNotifierProvider<MomoSetupNotifier, MomoSetup>(
  (ref) => MomoSetupNotifier(),
);
