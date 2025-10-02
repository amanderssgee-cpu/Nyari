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

    // Firebase
    FirebaseApp.configure()

    // Google Maps (iOS key)
    GMSServices.provideAPIKey("AIzaSyBk5TUsxlsYpfzM16ljacudFH4NNx76Sks")

    // Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
