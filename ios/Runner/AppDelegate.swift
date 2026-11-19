import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var noticeChannel: FlutterMethodChannel?
  private var pendingNotice: [String: String]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    UNUserNotificationCenter.current().delegate = self
    return ok
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "pawmatch/notice",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    noticeChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "ready" {
        let pending = self?.pendingNotice
        self?.pendingNotice = nil
        result(pending)
      } else {
        result(nil)
      }
    }
    UNUserNotificationCenter.current().delegate = self
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    remember(response.notification.request.content.userInfo)
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  private func remember(_ info: [AnyHashable: Any]) {
    var kind = info["kind"] as? String ?? ""
    var peer = info["peer"] as? String ?? ""
    var group = info["group"] as? String ?? ""
    let payload = info["payload"] as? String ?? ""
    if kind.isEmpty {
      let parts = payload.split(separator: "|").map(String.init)
      if !parts.isEmpty { kind = parts[0] }
      if peer.isEmpty, parts.count > 1 { peer = parts[1] }
      if group.isEmpty, parts.count > 2 { group = parts[2] }
    }
    if kind.isEmpty && peer.isEmpty && group.isEmpty { return }
    let data = ["kind": kind, "peer": peer, "group": group, "payload": payload]
    if let channel = noticeChannel {
      channel.invokeMethod("open", arguments: data)
    } else {
      pendingNotice = data
    }
  }
}
