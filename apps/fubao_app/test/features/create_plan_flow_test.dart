import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/demo_fubao_repository.dart';
import 'package:fubao_app/features/child/create_plan_page.dart';
import 'package:fubao_app/domain/models.dart';

void main() {
  testWidgets('creates a plan through selection, enrollment, and confirmation',
      (tester) async {
    final repository = DemoFubaoRepository();
    await tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => CreatePlanPage(repository: repository),
                    )),
                    child: const Text('打开创建计划'),
                  ),
                ),
              )),
    ));
    await tester.tap(find.text('打开创建计划'));
    await tester.pumpAndSettle();

    var next = find.text('下一步', skipOffstage: false);
    await tester.scrollUntilVisible(
      next,
      350,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('计划类型'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<TaskKind>));
    await tester.pumpAndSettle();
    expect(find.text('血糖管理'), findsOneWidget);
    await tester.tap(find.text('血糖管理').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '晨起血压');
    next = find.text('下一步', skipOffstage: false);
    await tester.scrollUntilVisible(
      next,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('开始执行'), findsWidgets);
    expect(find.text('任务会同步到长辈端'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(FilledButton, '开始执行'));
    await tester.tap(find.widgetWithText(FilledButton, '开始执行'));
    await tester.pumpAndSettle();

    expect(repository.plans.last.title, '晨起血压');
    expect(repository.plans.last.kind, TaskKind.bloodGlucose);
    expect(repository.plans.length, 3);
    repository.dispose();
  });
}
