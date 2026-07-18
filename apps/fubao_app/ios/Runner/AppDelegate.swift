import Flutter
import AVFoundation
import Security
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FubaoSecureSession")
    let channel = FlutterMethodChannel(
      name: "cn.fubao.app/secure-session",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "read":
        result(Self.readSession())
      case "write":
        guard let value = call.arguments as? String else {
          result(FlutterError(code: "INVALID_VALUE", message: "Session must be a string", details: nil))
          return
        }
        let status = Self.writeSession(value)
        status == errSecSuccess
          ? result(nil)
          : result(FlutterError(code: "KEYCHAIN_WRITE", message: "Unable to save session", details: status))
      case "delete":
        let status = Self.deleteSession()
        (status == errSecSuccess || status == errSecItemNotFound)
          ? result(nil)
          : result(FlutterError(code: "KEYCHAIN_DELETE", message: "Unable to delete session", details: status))
      case "readValue":
        guard let arguments = call.arguments as? [String: Any],
          let key = arguments["key"] as? String else {
          result(FlutterError(code: "INVALID_KEY", message: "Key must be a string", details: nil))
          return
        }
        result(Self.readValue(account: key))
      case "writeValue":
        guard let arguments = call.arguments as? [String: Any],
          let key = arguments["key"] as? String,
          let value = arguments["value"] as? String else {
          result(FlutterError(code: "INVALID_VALUE", message: "Key and value must be strings", details: nil))
          return
        }
        let status = Self.writeValue(value, account: key)
        status == errSecSuccess
          ? result(nil)
          : result(FlutterError(code: "KEYCHAIN_WRITE", message: "Unable to save secure value", details: status))
      case "deleteValue":
        guard let arguments = call.arguments as? [String: Any],
          let key = arguments["key"] as? String else {
          result(FlutterError(code: "INVALID_KEY", message: "Key must be a string", details: nil))
          return
        }
        let status = Self.deleteValue(account: key)
        (status == errSecSuccess || status == errSecItemNotFound)
          ? result(nil)
          : result(FlutterError(code: "KEYCHAIN_DELETE", message: "Unable to delete secure value", details: status))
      case "requestNotifications":
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
          granted, error in
          DispatchQueue.main.async {
            if let error = error {
              result(FlutterError(code: "NOTIFICATION_PERMISSION", message: error.localizedDescription, details: nil))
              return
            }
            if granted { UIApplication.shared.registerForRemoteNotifications() }
            result(granted)
          }
        }
      case "readPushToken":
        result(Self.readValue(account: "apns-device-token"))
      case "shareCareText":
        guard let arguments = call.arguments as? [String: Any],
          let text = arguments["text"] as? String else {
          result(FlutterError(code: "INVALID_TEXT", message: "Share text must be a string", details: nil))
          return
        }
        UIPasteboard.general.string = text
        if let wechat = URL(string: "weixin://"), UIApplication.shared.canOpenURL(wechat) {
          UIApplication.shared.open(wechat)
          result("wechat")
          return
        }
        guard let presenter = Self.topViewController() else {
          result(FlutterError(code: "NO_PRESENTER", message: "Unable to present system share", details: nil))
          return
        }
        presenter.present(UIActivityViewController(activityItems: [text], applicationActivities: nil), animated: true)
        result("system")
      case "speak":
        guard let arguments = call.arguments as? [String: Any],
          let text = arguments["text"] as? String else {
          result(FlutterError(code: "INVALID_TEXT", message: "Speech text must be a string", details: nil))
          return
        }
        let normalizedRate = (arguments["rate"] as? NSNumber)?.floatValue ?? 0.5
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.38 + min(max(normalizedRate, 0), 1) * 0.18
        Self.speechSynthesizer.stopSpeaking(at: .immediate)
        Self.speechSynthesizer.speak(utterance)
        result(true)
      case "stopSpeaking":
        Self.speechSynthesizer.stopSpeaking(at: .immediate)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static let keychainService = "cn.fubao.app.auth"
  private static let keychainAccount = "active-session"
  private static let cacheService = "cn.fubao.app.secure-cache"
  private static let speechSynthesizer = AVSpeechSynthesizer()

  private static func baseQuery() -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: keychainAccount,
    ]
  }

  private static func readSession() -> String? {
    var query = baseQuery()
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
      let data = item as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private static func writeSession(_ value: String) -> OSStatus {
    _ = deleteSession()
    var query = baseQuery()
    query[kSecValueData as String] = Data(value.utf8)
    query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    return SecItemAdd(query as CFDictionary, nil)
  }

  private static func deleteSession() -> OSStatus {
    SecItemDelete(baseQuery() as CFDictionary)
  }

  private static func valueQuery(account: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: cacheService,
      kSecAttrAccount as String: account,
    ]
  }

  private static func readValue(account: String) -> String? {
    var query = valueQuery(account: account)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
      let data = item as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private static func writeValue(_ value: String, account: String) -> OSStatus {
    _ = deleteValue(account: account)
    var query = valueQuery(account: account)
    query[kSecValueData as String] = Data(value.utf8)
    query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    return SecItemAdd(query as CFDictionary, nil)
  }

  private static func deleteValue(account: String) -> OSStatus {
    SecItemDelete(valueQuery(account: account) as CFDictionary)
  }

  private static func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    _ = Self.writeValue(token, account: "apns-device-token")
  }
}
