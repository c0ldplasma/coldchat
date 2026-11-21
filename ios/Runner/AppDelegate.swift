import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    excludeLoginsFromBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  /// Creates Documents/Logins, where the Twitch logins (access tokens) are stored, and keeps it out of iCloud and
  /// computer backups. Must match AccountRepository.iosLoginsFolder in lib/data/repositories/account_repository.dart.
  /// Runs at every launch, before Dart opens the box there; the flag on the folder covers every file in it.
  private func excludeLoginsFromBackup() {
    guard
      var folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
        .appendingPathComponent("Logins", isDirectory: true)
    else { return }
    do {
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try folder.setResourceValues(values)
    } catch {
      NSLog("Could not exclude the logins from backups: \(error)")
    }
  }
}
