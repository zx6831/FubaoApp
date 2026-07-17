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
}
