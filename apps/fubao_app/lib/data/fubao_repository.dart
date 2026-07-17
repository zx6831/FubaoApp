import 'package:flutter/foundation.dart';

import '../domain/models.dart';

abstract interface class FubaoRepository implements Listenable {
  List<HealthTask> get tasks;
  List<HealthPlan> get plans;
  List<CareTopic> get topics;
  int get completedTaskCount;
  bool get allTasksCompleted;

  Future<void> refresh();

  Future<HealthPlan> createPlan(PlanDraft draft);

  Future<void> setTaskCompleted(
    String id,
    bool value, {
    String? idempotencyKey,
  });

  Future<void> setTaskSkipped(String id, {String? idempotencyKey});

  Future<void> updatePlanStatus(String id, String status);

  Future<bool> remindTask(String id);

  void dispose();
}
