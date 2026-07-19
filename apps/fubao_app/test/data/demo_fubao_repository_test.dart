import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/demo_fubao_repository.dart';
import 'package:fubao_app/domain/models.dart';

void main() {
  test('completing medicine task updates progress', () {
    final repository = DemoFubaoRepository();

    repository.setTaskCompleted('medicine', true);

    expect(
      repository.tasks.singleWhere((task) => task.id == 'medicine').isCompleted,
      isTrue,
    );
  });

  test('demo content exposes two active plans and care topics', () {
    final repository = DemoFubaoRepository();

    expect(repository.plans, hasLength(2));
    expect(repository.topics, hasLength(2));
  });

  test('all tasks completed is derived from the shared task list', () {
    final repository = DemoFubaoRepository();

    expect(repository.allTasksCompleted, isFalse);
    for (final task in repository.tasks) {
      repository.setTaskCompleted(task.id, true);
    }

    expect(repository.allTasksCompleted, isTrue);
    expect(repository.completedTaskCount, repository.tasks.length);
  });

  test('profile pages use mutable demo device data instead of placeholders',
      () async {
    final repository = DemoFubaoRepository();

    final family = await repository.familyDetails();
    final profile = await repository.elderHealthProfile();
    expect((family['members'] as List), hasLength(2));
    expect(profile['relativeName'], '妈妈');
    await repository.updateElderHealthProfile({
      'relativeName': '母亲',
      'heightCm': 163,
      'weightKg': 59,
      'chronicConditions': const ['高血压'],
      'consentConfirmed': true,
    });
    expect((await repository.elderHealthProfile())['relativeName'], '母亲');

    await repository.updateDeviceSettings({
      'volume': 72,
      'speechRate': 45,
      'dndEnabled': false,
      'dndStart': '22:00',
      'dndEnd': '07:00',
    });
    expect(
      ((await repository.currentDevice())['settings'] as Map)['volume'],
      72,
    );
    await repository.setDeviceOnline(false);
    expect((await repository.currentDevice())['status'], 'offline');
    await repository.unbindDevice();
    expect((await repository.currentDevice())['status'], 'unbound');
  });

  test('demo plan status changes are shared with plan detail and overview',
      () async {
    final repository = DemoFubaoRepository();
    await repository.updatePlanStatus('blood-pressure', 'paused');
    expect(
      repository.plans
          .singleWhere((plan) => plan.id == 'blood-pressure')
          .status,
      'paused',
    );
  });

  test('health recording completes the matching task', () async {
    final repository = DemoFubaoRepository();

    await repository.recordHealth(
      HealthMetric.bloodPressure,
      const {'systolic': 120, 'diastolic': 80},
    );

    final task = repository.tasks
        .singleWhere((item) => item.kind == TaskKind.bloodPressure);
    expect(task.isCompleted, isTrue);
    expect(task.recordData, const {'systolic': 120, 'diastolic': 80});
  });

  test('demo history never invents tasks on earlier dates', () async {
    final repository = DemoFubaoRepository();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    expect(await repository.tasksForDate(yesterday), isEmpty);
    final today = await repository.tasksForDate(DateTime.now());
    expect(today, isNotEmpty);
    expect(today.every((task) => task.scheduledDate != null), isTrue);
  });

  test('health recording completes only the selected same-kind task', () async {
    final repository = DemoFubaoRepository();
    final now = DateTime.now();
    final firstPlan = await repository.createPlan(PlanDraft(
      kind: TaskKind.bloodPressure,
      title: 'Morning pressure',
      subtitle: 'First reading',
      startsOn: now,
      reminderTime: '08:00',
      daysOfWeek: [now.weekday],
    ));
    final secondPlan = await repository.createPlan(PlanDraft(
      kind: TaskKind.bloodPressure,
      title: 'Evening pressure',
      subtitle: 'Second reading',
      startsOn: now,
      reminderTime: '20:00',
      daysOfWeek: [now.weekday],
    ));
    final firstTask = repository.tasks.singleWhere(
      (task) => task.planId == firstPlan.id,
    );
    final secondTask = repository.tasks.singleWhere(
      (task) => task.planId == secondPlan.id,
    );

    await repository.recordHealth(
      HealthMetric.bloodPressure,
      const {'systolic': 126, 'diastolic': 78},
      taskId: secondTask.id,
    );

    expect(
      repository.tasks
          .singleWhere((task) => task.id == firstTask.id)
          .isCompleted,
      isFalse,
    );
    expect(
      repository.tasks
          .singleWhere((task) => task.id == secondTask.id)
          .isCompleted,
      isTrue,
    );
  });

  test('reminder is cleared on completion and paused plans leave the queue',
      () async {
    final repository = DemoFubaoRepository();
    final now = DateTime.now();
    final plan = await repository.createPlan(PlanDraft(
      kind: TaskKind.custom,
      title: 'Custom task',
      subtitle: 'Do it today',
      startsOn: now,
      reminderTime: '12:00',
      daysOfWeek: [now.weekday],
    ));
    final task = repository.tasks.singleWhere((item) => item.planId == plan.id);

    await repository.remindTask(task.id);
    expect(
        repository.tasks.singleWhere((item) => item.id == task.id).remindedAt,
        isNotNull);
    await repository.updatePlanStatus(plan.id, 'paused');
    expect(repository.tasks.where((item) => item.id == task.id), isEmpty);
    await repository.updatePlanStatus(plan.id, 'active');
    expect(
        repository.tasks.singleWhere((item) => item.id == task.id).remindedAt,
        isNull);
    await repository.remindTask(task.id);
    await repository.setTaskCompleted(task.id, true);
    expect(
        repository.tasks.singleWhere((item) => item.id == task.id).remindedAt,
        isNull);
  });
}
