import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/speech_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('cn.fubao.app/secure-session');

  test('sends Chinese speech text and normalized rate to the native bridge',
      () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      received = call;
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    final result = await SpeechService().speak('记得按时吃药', rate: 0.7);
    expect(result, isTrue);
    expect(received?.method, 'speak');
    expect((received?.arguments as Map)['text'], '记得按时吃药');
    expect((received?.arguments as Map)['rate'], 0.7);
  });
}
