import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/app/fubao_app.dart';
import 'package:fubao_app/data/demo_fubao_repository.dart';
import 'package:fubao_app/features/elder/elder_topics_page.dart';
import 'package:fubao_app/widgets/fubao_widgets.dart';

void main() {
  void setPhoneView(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> openElderApp(WidgetTester tester) async {
    setPhoneView(tester);
    await tester.pumpWidget(const FubaoApp());
    await tester.tap(find.text('我是长辈'));
    await tester.pumpAndSettle();
  }

  testWidgets('elder home matches the large task reference', (tester) async {
    await openElderApp(tester);
    expect(find.text('早上好，王阿姨'), findsOneWidget);
    expect(find.text('今天要做的事'), findsOneWidget);
    expect(find.text('我还没吃'), findsOneWidget);
    expect(find.byType(FubaoIllustrationAsset), findsAtLeastNWidgets(2));
    expect(
        tester.getSize(find.byKey(const Key('fubao-bottom-navigation'))).height,
        92);
  });

  testWidgets('elder plans and profile expose approved hierarchy',
      (tester) async {
    await openElderApp(tester);
    await tester.tap(find.text('计划').last);
    await tester.pumpAndSettle();
    expect(find.text('我的计划'), findsOneWidget);
    expect(find.text('今天的任务'), findsOneWidget);
    expect(find.text('接下来的事'), findsOneWidget);

    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();
    expect(find.text('今天也要照顾好自己'), findsOneWidget);
    expect(find.text('我的健康档案'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('退出家庭组'), 300);
    expect(find.text('退出家庭组'), findsOneWidget);
  });

  testWidgets('elder topics switch when all shared tasks are completed',
      (tester) async {
    setPhoneView(tester);
    final repository = DemoFubaoRepository();
    await tester.pumpWidget(
      MaterialApp(
          home: Scaffold(body: ElderTopicsPage(repository: repository))),
    );
    expect(find.text('先完成今天的任务'), findsOneWidget);

    for (final task in repository.tasks) {
      repository.setTaskCompleted(task.id, true);
    }
    await tester.pump();
    expect(find.text('今天的任务都完成啦！'), findsOneWidget);
    expect(find.text('今天有什么开心的事？'), findsOneWidget);
  });
}
