import 'package:flutter/services.dart';

const _channel = MethodChannel('genga/haptics');

Future<void> playLaunchHaptic() async {
  try {
    final played = await _channel.invokeMethod<bool>('launch');
    if (played == true) return;
  } on Exception {
    // Android has no native pattern yet, so it gets the single tap below.
  }
  await HapticFeedback.mediumImpact();
}
