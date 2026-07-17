import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'auth_session.dart';

abstract interface class SessionStore {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}

class MemorySessionStore implements SessionStore {
  AuthSession? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<AuthSession?> read() async => value;

  @override
  Future<void> write(AuthSession session) async => value = session;
}

class PlatformSessionStore implements SessionStore {
  static const _channel = MethodChannel('cn.fubao.app/secure-session');
  static AuthSession? _fallback;

  bool get _usesKeychain =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<AuthSession?> read() async {
    if (!_usesKeychain) return _fallback;
    final raw = await _channel.invokeMethod<String>('read');
    if (raw == null || raw.isEmpty) return null;
    return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> write(AuthSession session) async {
    if (!_usesKeychain) {
      _fallback = session;
      return;
    }
    await _channel.invokeMethod<void>('write', jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    if (!_usesKeychain) {
      _fallback = null;
      return;
    }
    await _channel.invokeMethod<void>('delete');
  }
}
