import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationPermissionResult {
  const NotificationPermissionResult({
    required this.authorized,
    this.deviceToken,
  });

  final bool authorized;
  final String? deviceToken;
}

class NotificationPermissionService {
  static const _channel = MethodChannel('cn.fubao.app/secure-session');

  Future<NotificationPermissionResult> request() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return const NotificationPermissionResult(authorized: true);
    }
    final authorized =
        await _channel.invokeMethod<bool>('requestNotifications') ?? false;
    if (!authorized) {
      return const NotificationPermissionResult(authorized: false);
    }
    String? token;
    for (var attempt = 0; attempt < 10 && token == null; attempt++) {
      token = await _channel.invokeMethod<String>('readPushToken');
      if (token == null) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
    return NotificationPermissionResult(
      authorized: true,
      deviceToken: token,
    );
  }
}
