import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/demo_fubao_repository.dart';
import 'package:fubao_app/design/fubao_theme.dart';
import 'package:fubao_app/domain/models.dart';
import 'package:fubao_app/features/auth/family_binding_page.dart';
import 'package:fubao_app/features/child/child_topics_page.dart';
import 'package:fubao_app/features/child/child_plans_page.dart';
import 'package:fubao_app/features/child/create_plan_page.dart';
import 'package:fubao_app/features/elder/elder_home_page.dart';
import 'package:fubao_app/features/elder/elder_plans_page.dart';
import 'package:fubao_app/features/elder/elder_topics_page.dart';
import 'package:fubao_app/features/health/health_center_page.dart';
import 'package:fubao_app/features/profile/profile_settings_page.dart';

void main() {
  Future<void> pumpPhone(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: buildFubaoTheme(), home: page));
    await tester.pumpAndSettle();
  }

  testWidgets('invitation actions have explicit vertical spacing',
      (tester) async {
    await pumpPhone(
      tester,
      FamilyBindingPage(
        role: AppRole.child,
        invitationCode: '5215',
        onCreateInvitation: () async => true,
        onJoin: (_) async => true,
        onRefresh: () async => true,
        onLogout: () async {},
      ),
    );

    final regenerate = tester.getRect(find.text('重新生成邀请码'));
    final refresh = tester.getRect(find.text('长辈已加入，刷新状态'));
    expect(refresh.top - regenerate.bottom, greaterThanOrEqualTo(8));
  });

  testWidgets('a new family plan page has no invented progress or spark',
      (tester) async {
    final repository = _EmptyRepository();
    await pumpPhone(
      tester,
      Scaffold(body: ChildPlansPage(repository: repository)),
    );

    expect(find.text('今日火花未点亮'), findsOneWidget);
    expect(find.text('本周还没有任务'), findsOneWidget);
    expect(find.text('本月还没有任务'), findsOneWidget);
    expect(find.text('还没有正在进行的计划'), findsOneWidget);
    expect(find.text('添加第一个健康计划后，任务会从执行日期开始生成'),
        findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('blood pressure task uses measurement-specific actions',
      (tester) async {
    final repository = _TaskRepository([
      HealthTask(
        id: 'pressure-today',
        title: '血压管理',
        subtitle: '坐下休息后测量',
        timeLabel: '下午 4:22',
        kind: TaskKind.bloodPressure,
        scheduledDate: DateTime(2026, 7, 18),
      ),
    ]);
    await pumpPhone(
        tester, Scaffold(body: ElderHomePage(repository: repository)));

    expect(find.text('去记录血压'), findsOneWidget);
    expect(find.text('稍后再测'), findsOneWidget);
    expect(find.text('我已经吃了'), findsNothing);
  });

  testWidgets('elder empty-state refresh visibly rotates while reloading',
      (tester) async {
    await pumpPhone(
      tester,
      Scaffold(body: ElderHomePage(repository: _EmptyRepository())),
    );
    await tester.tap(find.text('刷新看看'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('elder-refresh-spinner')), findsOneWidget);
    expect(find.text('正在刷新'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  });

  testWidgets('elder plan puts next pending task before the ordered overview',
      (tester) async {
    final repository = _TaskRepository([
      HealthTask(
        id: 'completed-early',
        title: '已完成任务',
        subtitle: '已经完成',
        timeLabel: '上午 7:00',
        kind: TaskKind.medicine,
        isCompleted: true,
        scheduledDate: DateTime(2026, 7, 18),
      ),
      HealthTask(
        id: 'pending-late',
        title: '稍后任务',
        subtitle: '稍后完成',
        timeLabel: '上午 10:00',
        kind: TaskKind.walk,
        scheduledDate: DateTime(2026, 7, 18),
      ),
      HealthTask(
        id: 'pending-early',
        title: '早间任务',
        subtitle: '优先完成',
        timeLabel: '上午 8:00',
        kind: TaskKind.bloodPressure,
        scheduledDate: DateTime(2026, 7, 18),
      ),
    ]);
    await pumpPhone(
      tester,
      Scaffold(
        body: ElderPlansPage(
          repository: repository,
          today: DateTime(2026, 7, 18),
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('接下来的事')).dy,
        lessThan(tester.getTopLeft(find.text('今天的任务')).dy));
    expect(find.text('早间任务'), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.text('已完成任务'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.getTopLeft(find.text('早间任务').last).dy,
        lessThan(tester.getTopLeft(find.text('稍后任务')).dy));
    expect(tester.getTopLeft(find.text('稍后任务')).dy,
        lessThan(tester.getTopLeft(find.text('已完成任务')).dy));
  });

  testWidgets('elder plan hides next section when nothing is pending',
      (tester) async {
    await pumpPhone(
      tester,
      Scaffold(
        body: ElderPlansPage(
          repository: _EmptyRepository(),
          today: DateTime(2026, 7, 18),
        ),
      ),
    );
    expect(find.text('接下来的事'), findsNothing);
    expect(find.text('今天还没有任务'), findsOneWidget);
  });

  testWidgets('blood pressure dialog reaches confirmation without assertion',
      (tester) async {
    final repository = DemoFubaoRepository();
    await pumpPhone(
      tester,
      HealthCenterPage(repository: repository, elder: true),
    );

    await tester.tap(find.text('血压').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('elder-primary-120')));
    await tester.tap(find.byKey(const Key('elder-secondary-80')));
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('确认本次记录'), findsOneWidget);
    expect(find.text('120 / 80 mmHg'), findsOneWidget);
  });

  testWidgets('elder week strip uses real weekday and only actual task history',
      (tester) async {
    final repository = _TaskRepository([
      HealthTask(
        id: 'today-complete',
        title: '血压管理',
        subtitle: '规律记录',
        timeLabel: '上午 8:30',
        kind: TaskKind.bloodPressure,
        isCompleted: true,
        scheduledDate: DateTime(2026, 7, 18),
      ),
    ]);
    await pumpPhone(
      tester,
      Scaffold(
        body: ElderPlansPage(
          repository: repository,
          today: DateTime(2026, 7, 18),
        ),
      ),
    );

    final todayIndicator = find.byKey(const Key('elder-week-day-6'));
    expect(todayIndicator, findsOneWidget);
    expect(
      find.descendant(of: todayIndicator, matching: find.text('今')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: todayIndicator,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('elder topics stay locked then open a topic detail',
      (tester) async {
    final pending = DemoFubaoRepository();
    await pumpPhone(
      tester,
      Scaffold(body: ElderTopicsPage(repository: pending)),
    );
    expect(find.text('完成任务后，暖心话题会出现在这里'), findsOneWidget);
    expect(find.text('今天有什么开心的事？'), findsNothing);

    final completed = DemoFubaoRepository();
    for (final task in completed.tasks) {
      await completed.setTaskCompleted(task.id, true);
    }
    await pumpPhone(
      tester,
      Scaffold(body: ElderTopicsPage(repository: completed)),
    );
    await tester.tap(find.text('今天有什么开心的事？'));
    await tester.pumpAndSettle();
    expect(find.text('话题详情'), findsOneWidget);
  });

  testWidgets('topic history and message center cards open detail pages',
      (tester) async {
    final repository = DemoFubaoRepository();
    await pumpPhone(
      tester,
      Scaffold(body: ChildTopicsPage(repository: repository)),
    );
    await tester.tap(find.text('本周健康周报已生成'));
    await tester.pumpAndSettle();
    expect(find.text('消息详情'), findsOneWidget);

    Navigator.of(tester.element(find.text('消息详情'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看全部 ›'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('本周健康周报已生成'));
    await tester.pumpAndSettle();
    expect(find.text('消息详情'), findsOneWidget);
    expect(find.text('本周健康周报已生成'), findsOneWidget);
  });

  testWidgets('plan indicators align with their labels', (tester) async {
    await pumpPhone(tester, const CreatePlanPage());
    for (var index = 0; index < 3; index++) {
      final indicator = find.byKey(Key('plan-step-indicator-$index'));
      final label = find.byKey(Key('plan-step-label-$index'));
      expect(
        (tester.getCenter(indicator).dx - tester.getCenter(label).dx).abs(),
        lessThanOrEqualTo(1),
      );
    }
  });

  testWidgets('health profile is grouped like a personal dossier',
      (tester) async {
    await pumpPhone(
      tester,
      ProfileSettingsPage(
        kind: ProfileSettingKind.health,
        repository: DemoFubaoRepository(),
      ),
    );

    expect(find.text('基本信息'), findsOneWidget);
    expect(find.text('健康状况'), findsOneWidget);
    expect(find.text('安全与授权'), findsOneWidget);
    expect(find.text('编辑健康档案'), findsOneWidget);
  });
}

class _TaskRepository extends DemoFubaoRepository {
  _TaskRepository(this.items);

  final List<HealthTask> items;

  @override
  List<HealthTask> get tasks => List.unmodifiable(items);

  @override
  int get completedTaskCount => items.where((task) => task.isCompleted).length;

  @override
  bool get allTasksCompleted =>
      items.isNotEmpty && items.every((task) => task.isCompleted);

  @override
  Future<List<HealthTask>> taskHistory(DateTime from, DateTime to) async => [];
}

class _EmptyRepository extends DemoFubaoRepository {
  @override
  List<HealthTask> get tasks => const [];

  @override
  List<HealthPlan> get plans => const [];

  @override
  int get completedTaskCount => 0;

  @override
  bool get allTasksCompleted => false;

  @override
  FamilySpark get spark => const FamilySpark(
        lit: false,
        streakDays: 0,
        childActive: true,
        elderActive: false,
      );

  @override
  Future<List<HealthTask>> taskHistory(DateTime from, DateTime to) async => [];
}
