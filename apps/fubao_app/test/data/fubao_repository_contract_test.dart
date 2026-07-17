import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/demo_fubao_repository.dart';
import 'package:fubao_app/data/fubao_repository.dart';

void main() {
  test('demo repository satisfies the asynchronous app data boundary',
      () async {
    final FubaoRepository repository = DemoFubaoRepository();

    expect(repository, isA<Listenable>());
    await repository.refresh();
    await repository.setTaskCompleted(
      'medicine',
      true,
      idempotencyKey: 'contract-test',
    );

    expect(
      repository.tasks.singleWhere((task) => task.id == 'medicine').isCompleted,
      isTrue,
    );
    repository.dispose();
  });
}
