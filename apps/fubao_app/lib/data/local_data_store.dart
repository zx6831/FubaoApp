import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class LocalDataStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class MemoryLocalDataStore implements LocalDataStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// iOS values are stored as ThisDeviceOnly Keychain items. Keychain encrypts
/// them at rest; Web/desktop debug sessions intentionally use memory only.
class PlatformLocalDataStore implements LocalDataStore {
  static const _channel = MethodChannel('cn.fubao.app/secure-session');
  static final Map<String, String> _fallback = {};

  bool get _usesKeychain =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<String?> read(String key) async {
    if (!_usesKeychain) return _fallback[key];
    return _channel.invokeMethod<String>('readValue', {'key': key});
  }

  @override
  Future<void> write(String key, String value) async {
    if (!_usesKeychain) {
      _fallback[key] = value;
      return;
    }
    await _channel.invokeMethod<void>(
      'writeValue',
      {'key': key, 'value': value},
    );
  }

  @override
  Future<void> delete(String key) async {
    if (!_usesKeychain) {
      _fallback.remove(key);
      return;
    }
    await _channel.invokeMethod<void>('deleteValue', {'key': key});
  }
}
