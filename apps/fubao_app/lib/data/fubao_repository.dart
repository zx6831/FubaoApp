import 'package:flutter/foundation.dart';

import '../domain/models.dart';

abstract interface class FubaoRepository implements Listenable {
  List<HealthTask> get tasks;
  List<HealthPlan> get plans;
  List<CareTopic> get topics;
  int get completedTaskCount;
  bool get allTasksCompleted;

  Future<void> refresh();

  Future<void> setTaskCompleted(
    String id,
    bool value, {
    String? idempotencyKey,
  });

  void dispose();
}
