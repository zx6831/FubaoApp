import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/app/fubao_app.dart';

void main() {
  testWidgets('child role opens child dashboard and navigates plans',
      (tester) async {
    await tester.pumpWidget(const FubaoApp());

    await tester.tap(find.text('我是子女'));
    await tester.pumpAndSettle();
    expect(find.text('今日任务进度'), findsOneWidget);

    await tester.tap(find.text('计划').last);
    await tester.pumpAndSettle();
    expect(find.text('本周完成情况'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('添加计划'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('添加计划'), findsOneWidget);
  });

  testWidgets('elder can complete the medicine task', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FubaoApp());
    await tester.tap(find.text('我是长辈'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('我已经吃了'));
    await tester.pump();
    expect(find.text('已完成'), findsOneWidget);
  });

  testWidgets('child account settings logout returns to role login', (tester) async {
    await tester.pumpWidget(const FubaoApp());
    await tester.tap(find.text('我是子女'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('账号设置'), findsOneWidget);
    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('退出登录').last);
    await tester.pumpAndSettle();
    expect(find.text('我是子女'), findsOneWidget);
  });

  testWidgets('elder profile exposes a separate logout action', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FubaoApp());
    await tester.tap(find.text('我是长辈'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('退出登录'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('退出家庭组'), findsOneWidget);
    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('退出登录').last);
    await tester.pumpAndSettle();
    expect(find.text('我是长辈'), findsOneWidget);
  });
}
