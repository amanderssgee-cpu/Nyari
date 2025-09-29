import UIKit
import Flutter
import FirebaseCore
import GoogleMaps

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Firebase (needed by firebase_core/auth/firestore/storage)
    FirebaseApp.configure()

    // Google Maps (required by google_maps_flutter on iOS)
    GMSServices.provideAPIKey("YOUR_IOS_GOOGLE_MAPS_API_KEY_HERE")

    // Register all generated plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
