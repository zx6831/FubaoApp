import Flutter
import Security
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
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static let keychainService = "cn.fubao.app.auth"
  private static let keychainAccount = "active-session"
  private static let cacheService = "cn.fubao.app.secure-cache"

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
}
