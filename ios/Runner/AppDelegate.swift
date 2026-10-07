import UIKit
import Flutter
import FirebaseCore
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ============================================================
    // FIREBASE
    // ============================================================

    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

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