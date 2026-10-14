import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerOfflineStorageChannel(engineBridge.pluginRegistry)
    registerFocusLockChannel(engineBridge.pluginRegistry)
  }

  /// Parental focus mode (lib/features/focus/data/focus_lock_platform.dart).
  /// iOS won't let an app pin itself outside MDM-supervised devices, so
  /// this only reports whether the student has started Guided Access.
  private func registerFocusLockChannel(_ registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "DirasstyFocusLock") else { return }
    let channel = FlutterMethodChannel(
      name: "ai.dirassty/focus_lock",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isLocked":
        result(UIAccessibility.isGuidedAccessEnabled)
      case "pin", "unpin":
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// `excludeFromBackup(path)` — called by OfflineVideoStore (Dart) when it
  /// creates its downloads folder, so downloaded course videos never end
  /// up in iCloud/Finder backups where they could be extracted.
  private func registerOfflineStorageChannel(_ registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "DirasstyOfflineStorage") else { return }
    let channel = FlutterMethodChannel(
      name: "ai.dirassty/offline_storage",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup", let path = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      var url = URL(fileURLWithPath: path)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      do {
        try url.setResourceValues(values)
        result(nil)
      } catch {
        result(FlutterError(code: "exclude_failed", message: error.localizedDescription, details: nil))
      }
    }
  }
}
