import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/demo_fubao_repository.dart';

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
}
