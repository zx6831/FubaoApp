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
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static let keychainService = "cn.fubao.app.auth"
  private static let keychainAccount = "active-session"

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
}
