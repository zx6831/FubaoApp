import 'package:flutter/foundation.dart';

import '../domain/models.dart';

abstract interface class FubaoRepository implements Listenable {
  List<HealthTask> get tasks;
  List<HealthPlan> get plans;
  List<CareTopic> get topics;
  int get completedTaskCount;
  bool get allTasksCompleted;
  List<HealthReading> get healthReadings;
  List<CareAlert> get alerts;
  FamilySpark get spark;

  Future<void> refresh();

  Future<List<HealthTask>> tasksForDate(DateTime date);

  Future<List<HealthTask>> taskHistory(DateTime from, DateTime to);

  Future<HealthPlan> createPlan(PlanDraft draft);

  Future<void> setTaskCompleted(
    String id,
    bool value, {
    String? idempotencyKey,
  });

  Future<void> setTaskSkipped(String id, {String? idempotencyKey});

  Future<void> updatePlanStatus(String id, String status);

  Future<bool> remindTask(String id);

  Future<void> recordHealth(
    HealthMetric metric,
    Map<String, dynamic> value,
  );

  Future<void> updateAlert(
    String id,
    String status, {
    String? closeReason,
  });

  void dispose();
}
