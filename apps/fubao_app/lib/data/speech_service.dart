import 'package:flutter/services.dart';

class SpeechService {
  static const MethodChannel _channel =
      MethodChannel('cn.fubao.app/secure-session');

  Future<bool> speak(String text, {double rate = 0.5}) async {
    try {
      return await _channel.invokeMethod<bool>('speak', {
            'text': text,
            'rate': rate.clamp(0.0, 1.0),
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stopSpeaking');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
