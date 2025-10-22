// ios/Runner/AppDelegate.swift

import UIKit
import Flutter
import GoogleMaps   // <-- add this

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Google Maps SDK for iOS key (restricted to iOS + your bundle ID)
    GMSServices.provideAPIKey("AIzaSyBk5TUsxlsYpfzM16ljacudFH4NNx76Sks")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
