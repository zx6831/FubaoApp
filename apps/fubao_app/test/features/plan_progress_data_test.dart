import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/demo_fubao_repository.dart';
import 'package:fubao_app/domain/models.dart';
import 'package:fubao_app/features/child/child_plans_page.dart';

class _DatedRepository extends DemoFubaoRepository {
  @override
  Future<List<HealthTask>> taskHistory(DateTime from, DateTime to) async {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return [
      HealthTask(
        id: 'week-complete',
        title: '本周已完成',
        subtitle: '',
        timeLabel: '08:00',
        kind: TaskKind.medicine,
        isCompleted: true,
        scheduledDate: weekStart,
      ),
      HealthTask(
        id: 'week-pending',
        title: '本周待完成',
        subtitle: '',
        timeLabel: '09:00',
        kind: TaskKind.walk,
        scheduledDate: now,
      ),
      HealthTask(
        id: 'month-complete',
        title: '本月已完成',
        subtitle: '',
        timeLabel: '10:00',
        kind: TaskKind.mood,
        isCompleted: true,
        scheduledDate: DateTime(now.year, now.month, 1),
      ),
    ];
  }
}

void main() {
  testWidgets('plan overview derives week and month totals from dated tasks',
      (tester) async {
    final repository = _DatedRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ChildPlansPage(repository: repository)),
    ));
    await tester.pumpAndSettle();

    expect(
      find.text('本周已完成  1/2 项', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('本月已完成  2/3 项', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('67%'), findsOneWidget);
  });
}
