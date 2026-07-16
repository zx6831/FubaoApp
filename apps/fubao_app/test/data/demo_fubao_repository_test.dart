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
}
