import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/app/fubao_app.dart';
import 'package:fubao_app/data/accessibility_settings.dart';
import 'package:fubao_app/data/local_data_store.dart';

void main() {
  test('text scale and speech rate persist through the secure store boundary',
      () async {
    final store = MemoryLocalDataStore();
    final first = AccessibilitySettings(store: store);
    await first.setTextScale(1.3);
    await first.setSpeechRate(0.7);

    final restored = AccessibilitySettings(store: store);
    await restored.load();
    expect(restored.textScale, 1.3);
    expect(restored.speechRate, 0.7);
  });

  testWidgets('FubaoApp applies accessibility text scale to the whole app',
      (tester) async {
    final settings = AccessibilitySettings(store: MemoryLocalDataStore());
    await tester.pumpWidget(FubaoApp(accessibilitySettings: settings));
    await tester.pump();

    BuildContext context = tester.element(find.text('欢迎回家'));
    expect(MediaQuery.of(context).textScaler.scale(10), 10);
    await settings.setTextScale(1.3);
    await tester.pump();
    context = tester.element(find.text('欢迎回家'));
    expect(MediaQuery.of(context).textScaler.scale(10), 13);
  });
}
