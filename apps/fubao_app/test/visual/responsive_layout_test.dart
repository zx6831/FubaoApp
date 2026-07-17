import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/app/fubao_app.dart';

void main() {
  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets(
        'dual-role shells render without overflow at ${width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const FubaoApp());
      await tester.tap(find.text('我是子女'));
      await tester.pumpAndSettle();
      for (final label in ['计划', '话题', '我的', '首页']) {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
      }

      // Start a fresh app instance so the width test does not depend on a
      // scrollable control sitting above the persistent bottom navigation.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(const FubaoApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('我是长辈'));
      await tester.pumpAndSettle();
      for (final label in ['计划', '话题', '我的', '首页']) {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
      }
    });
  }
}
