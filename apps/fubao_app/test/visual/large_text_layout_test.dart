import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/app/fubao_app.dart';
import 'package:fubao_app/data/accessibility_settings.dart';
import 'package:fubao_app/data/local_data_store.dart';

void main() {
  for (final role in ['我是子女', '我是长辈']) {
    testWidgets('$role renders all main tabs at 360px and 140% text',
        (tester) async {
      tester.view.physicalSize = const Size(360, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AccessibilitySettings(store: MemoryLocalDataStore());
      await settings.setTextScale(1.4);
      await tester.pumpWidget(FubaoApp(accessibilitySettings: settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text(role));
      await tester.pumpAndSettle();
      _expectNoLayoutError(tester, '$role 首页');
      await _scrollCurrentPage(tester, '$role 首页底部');

      for (final tab in ['计划', '话题', '我的']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        _expectNoLayoutError(tester, '$role $tab');
        await _scrollCurrentPage(tester, '$role $tab底部');
      }
    });
  }
}

Future<void> _scrollCurrentPage(WidgetTester tester, String page) async {
  final scrollable = find.byType(Scrollable);
  if (scrollable.evaluate().isEmpty) return;
  await tester.drag(scrollable.first, const Offset(0, -1200));
  await tester.pumpAndSettle();
  _expectNoLayoutError(tester, page);
}

void _expectNoLayoutError(WidgetTester tester, String page) {
  final error = tester.takeException();
  if (error is FlutterError) {
    fail('$page overflowed:\n${error.toStringDeep()}');
  }
  expect(error, isNull, reason: '$page overflowed');
}
