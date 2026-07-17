import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/demo_fubao_repository.dart';
import 'package:fubao_app/features/plans/task_history_page.dart';

void main() {
  testWidgets('shows date tasks and month progress for both roles',
      (tester) async {
    final repository = DemoFubaoRepository();
    await tester.pumpWidget(MaterialApp(
      home: TaskHistoryPage(repository: repository),
    ));
    await tester.pumpAndSettle();

    expect(find.text('健康任务记录'), findsOneWidget);
    expect(find.text('当天完成'), findsOneWidget);
    expect(find.text('本月完成'), findsOneWidget);
    expect(find.text('降压药 1 片'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: TaskHistoryPage(repository: repository, elder: true),
    ));
    await tester.pumpAndSettle();
    expect(find.text('任务记录'), findsOneWidget);

    final largeTapTarget = tester.getSize(find.text('打开月历').first);
    expect(largeTapTarget.height, greaterThan(16));
    repository.dispose();
  });
}
