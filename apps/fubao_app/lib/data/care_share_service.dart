import 'package:flutter/services.dart';

enum CareShareTarget { wechat, system, clipboard }

class CareShareService {
  static const MethodChannel _channel =
      MethodChannel('cn.fubao.app/secure-session');

  Future<CareShareTarget> share(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    try {
      final target = await _channel.invokeMethod<String>(
        'shareCareText',
        {'text': text},
      );
      return target == 'wechat'
          ? CareShareTarget.wechat
          : CareShareTarget.system;
    } on MissingPluginException {
      return CareShareTarget.clipboard;
    } on PlatformException {
      return CareShareTarget.clipboard;
    }
  }
}
