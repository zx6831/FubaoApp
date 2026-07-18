import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/app/fubao_app.dart';
import 'package:fubao_app/widgets/fubao_widgets.dart';

void main() {
  testWidgets('role selection uses the approved mascot language',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FubaoApp());

    expect(find.byType(FubaoIllustrationAsset), findsAtLeastNWidgets(1));
    expect(find.text('我是子女'), findsOneWidget);
    expect(find.text('我是长辈'), findsOneWidget);
  });

  Future<void> openChildApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FubaoApp());
    await tester.tap(find.text('我是子女'));
    await tester.pumpAndSettle();
  }

  testWidgets('child home contains the approved reference sections',
      (tester) async {
    await openChildApp(tester);

    expect(find.text('已连续互动 12 天'), findsOneWidget);
    expect(find.text('聊一聊，会更好'), findsOneWidget);
    expect(find.byType(FubaoIllustrationAsset), findsAtLeastNWidgets(4));
    expect(find.byKey(const Key('mood-icon-happy')), findsOneWidget);
    expect(find.byKey(const Key('fubao-bottom-navigation')), findsOneWidget);
  });

  testWidgets('child plans and create flow match reference hierarchy',
      (tester) async {
    await openChildApp(tester);
    await tester.tap(find.text('计划').last);
    await tester.pumpAndSettle();

    expect(find.text('本月进度'), findsOneWidget);
    expect(find.text('正在进行的计划'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('添加计划'), 250);
    await tester.tap(find.text('添加计划'));
    await tester.pumpAndSettle();

    expect(find.text('选择计划'), findsOneWidget);
    expect(find.text('填写信息'), findsOneWidget);
    expect(find.text('开始执行'), findsOneWidget);
    expect(find.text('自定义计划'), findsOneWidget);
  });

  testWidgets('child topics and profile expose approved content',
      (tester) async {
    await openChildApp(tester);
    await tester.tap(find.text('话题').last);
    await tester.pumpAndSettle();
    expect(find.text('今天适合聊一聊'), findsOneWidget);
    expect(find.text('本周健康周报'), findsOneWidget);
    expect(find.text('消息记录'), findsOneWidget);

    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();
    expect(find.text('我的成就'), findsOneWidget);
    expect(find.text('一起成长的小约定'), findsOneWidget);
  });
}
