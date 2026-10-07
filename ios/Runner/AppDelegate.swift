import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ============================================================
    // GOOGLE MAPS
    // ============================================================

    GMSServices.provideAPIKey(
      "AIzaSyAsHkvRLLcGhLuVLeFTK0nKP71Uk2CI2oY"
    )

    // ============================================================
    // FLUTTER PLUGINS
    // ============================================================

    GeneratedPluginRegistrant.register(with: self)

    // ============================================================
    // FINISH LAUNCH
    // ============================================================

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }
}
