import UIKit
import Flutter
import GoogleMaps    // <-- add this

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GMSServices.provideAPIKey("AIzaSyBk5TUsxlsYpfzM16ljacudFH4NNx76Sks")   // <-- use your iOS key here
    // If you use Places on iOS too:
    // GMSPlacesClient.provideAPIKey("YOUR_IOS_MAPS_KEY")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
