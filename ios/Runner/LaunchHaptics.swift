import CoreHaptics
import Flutter

final class LaunchHaptics: NSObject, FlutterPlugin {
  private var engine: CHHapticEngine?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "genga/haptics", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(LaunchHaptics(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "launch" else {
      result(FlutterMethodNotImplemented)
      return
    }
    result(play())
  }

  private func play() -> Bool {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return false }
    do {
      if engine == nil {
        let created = try CHHapticEngine()
        created.isAutoShutdownEnabled = true
        engine = created
      }
      try engine?.start()
      let player = try engine?.makePlayer(with: Self.pattern())
      try player?.start(atTime: CHHapticTimeImmediate)
      return true
    } catch {
      return false
    }
  }

  // A low swell that builds, lands on one firm tap, then a faint echo.
  private static func pattern() throws -> CHHapticPattern {
    let swell = CHHapticEvent(
      eventType: .hapticContinuous,
      parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
      ],
      relativeTime: 0,
      duration: 0.34
    )
    let land = CHHapticEvent(
      eventType: .hapticTransient,
      parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.55),
      ],
      relativeTime: 0.34
    )
    let echo = CHHapticEvent(
      eventType: .hapticTransient,
      parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3),
      ],
      relativeTime: 0.5
    )
    let rise = CHHapticParameterCurve(
      parameterID: .hapticIntensityControl,
      controlPoints: [
        .init(relativeTime: 0, value: 0.05),
        .init(relativeTime: 0.22, value: 0.45),
        .init(relativeTime: 0.34, value: 1.0),
      ],
      relativeTime: 0
    )
    return try CHHapticPattern(events: [swell, land, echo], parameterCurves: [rise])
  }
}
