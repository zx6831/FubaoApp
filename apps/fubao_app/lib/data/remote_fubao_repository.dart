import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'fubao_repository.dart';
import 'remote_api_client.dart';

class RemoteFubaoRepository extends ChangeNotifier implements FubaoRepository {
  RemoteFubaoRepository(this._api);

  final RemoteApiClient _api;
  final List<HealthTask> _tasks = [];
  final List<HealthPlan> _plans = [];
  final List<CareTopic> _topics = const [];
  final List<HealthReading> _healthReadings = [];
  final List<CareAlert> _alerts = [];
  FamilySpark _spark = const FamilySpark(
    lit: false,
    streakDays: 0,
    childActive: false,
    elderActive: false,
  );
  Timer? _poller;
  bool _refreshing = false;
  String? lastError;

  @override
  List<HealthTask> get tasks => List.unmodifiable(_tasks);

  @override
  List<HealthPlan> get plans => List.unmodifiable(_plans);

  @override
  List<CareTopic> get topics => List.unmodifiable(_topics);

  @override
  List<HealthReading> get healthReadings => List.unmodifiable(_healthReadings);

  @override
  List<CareAlert> get alerts => List.unmodifiable(_alerts);

  @override
  FamilySpark get spark => _spark;

  @override
  int get completedTaskCount => _tasks.where((task) => task.isCompleted).length;

  @override
  bool get allTasksCompleted =>
      _tasks.isNotEmpty && _tasks.every((task) => task.isCompleted);

  void start() {
    if (_poller != null) return;
    unawaited(refresh());
    _poller = Timer.periodic(
        const Duration(seconds: 10), (_) => unawaited(refresh()));
  }

  void clear() {
    _poller?.cancel();
    _poller = null;
    _tasks.clear();
    _plans.clear();
    _healthReadings.clear();
    _alerts.clear();
    _spark = const FamilySpark(
      lit: false,
      streakDays: 0,
      childActive: false,
      elderActive: false,
    );
    lastError = null;
    notifyListeners();
  }

  @override
  Future<void> refresh() async {
    if (_refreshing || _api.session == null) return;
    _refreshing = true;
    try {
      final planData = await _api.get('plans');
      final taskData = await _api.get('tasks/today');
      final healthData = await _api.get('health-data');
      final alertData = await _api.get('alerts');
      final sparkData = await _api.get('sparks/current');
      final taskItems = (taskData['items'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => _taskFromJson(item.cast<String, dynamic>()))
          .toList();
      final planItems = (planData['items'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => _planFromJson(item.cast<String, dynamic>(), taskItems))
          .toList();
      _tasks
        ..clear()
        ..addAll(taskItems);
      _plans
        ..clear()
        ..addAll(planItems);
      _healthReadings
        ..clear()
        ..addAll((healthData['items'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => _healthFromJson(item.cast<String, dynamic>())));
      _alerts
        ..clear()
        ..addAll((alertData['items'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => _alertFromJson(item.cast<String, dynamic>())));
      _spark = FamilySpark(
        lit: sparkData['lit'] == true,
        streakDays: (sparkData['streakDays'] as num?)?.toInt() ?? 0,
        childActive: sparkData['childActive'] == true,
        elderActive: sparkData['elderActive'] == true,
      );
      lastError = null;
      notifyListeners();
    } on ApiException catch (error) {
      lastError = error.message;
      notifyListeners();
    } finally {
      _refreshing = false;
    }
  }

  @override
  Future<List<HealthTask>> tasksForDate(DateTime date) async {
    final data = await _api.get('tasks?date=${_date(date)}');
    return (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _taskFromJson(item.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<HealthTask>> taskHistory(DateTime from, DateTime to) async {
    final data = await _api.get(
      'tasks/history?from=${_date(from)}&to=${_date(to)}',
    );
    return (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _taskFromJson(item.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<HealthPlan> createPlan(PlanDraft draft) async {
    final data = await _api.post('plans', body: {
      'kind': draft.kind.name,
      'title': draft.title,
      'subtitle': draft.subtitle,
      'startsOn': _date(draft.startsOn),
      'timezone': 'Asia/Shanghai',
      'schedule': {'time': draft.reminderTime, 'daysOfWeek': draft.daysOfWeek},
      'enrollmentData': draft.enrollmentData,
    });
    await refresh();
    return _plans.firstWhere(
      (plan) => plan.id == data['id'],
      orElse: () => _planFromJson(data, _tasks),
    );
  }

  @override
  Future<void> setTaskCompleted(
    String id,
    bool value, {
    String? idempotencyKey,
  }) async {
    if (!value) return;
    await _api.post(
      'tasks/$id/complete',
      body: const {},
      headers: {'Idempotency-Key': idempotencyKey ?? _idempotencyKey(id)},
    );
    await refresh();
  }

  @override
  Future<void> setTaskSkipped(String id, {String? idempotencyKey}) async {
    await _api.post(
      'tasks/$id/skip',
      body: const {},
      headers: {'Idempotency-Key': idempotencyKey ?? _idempotencyKey(id)},
    );
    await refresh();
  }

  @override
  Future<void> updatePlanStatus(String id, String status) async {
    await _api.patch('plans/$id/status', body: {'status': status});
    await refresh();
  }

  @override
  Future<bool> remindTask(String id) async {
    final data = await _api.post('tasks/$id/remind');
    return data['accepted'] == true;
  }

  @override
  Future<void> recordHealth(
    HealthMetric metric,
    Map<String, dynamic> value,
  ) async {
    await _api.post('health-data', body: {
      'type': metric.name,
      if (metric == HealthMetric.bloodPressure) ...{
        'systolic': value['systolic'],
        'diastolic': value['diastolic'],
      } else if (metric == HealthMetric.mood)
        'textValue': value['text']
      else
        'value': value['value'],
      'confirmedByUser': true,
    });
    await refresh();
  }

  @override
  Future<void> updateAlert(
    String id,
    String status, {
    String? closeReason,
  }) async {
    await _api.patch('alerts/$id', body: {
      'status': status,
      if (closeReason != null) 'closeReason': closeReason,
    });
    await refresh();
  }

  HealthTask _taskFromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString();
    final record = (json['record'] as Map?)?.cast<String, dynamic>();
    final reminder = json['reminderAt'] == null
        ? null
        : DateTime.tryParse(json['reminderAt'].toString());
    return HealthTask(
      id: json['id'].toString(),
      planId: json['planId']?.toString(),
      title: json['title']?.toString() ?? '健康任务',
      subtitle: json['subtitle']?.toString() ?? '按计划完成今天的任务',
      timeLabel: _timeLabel(reminder),
      kind: _kind(json['kind']?.toString()),
      isCompleted: status == 'completed',
      isSkipped: status == 'skipped',
      recordedAt: record?['completedAt'] == null
          ? null
          : DateTime.tryParse(record!['completedAt'].toString()),
      recordData: (record?['data'] as Map?)?.cast<String, dynamic>(),
    );
  }

  HealthPlan _planFromJson(Map<String, dynamic> json, List<HealthTask> tasks) {
    final id = json['id'].toString();
    final schedule =
        (json['schedule'] as Map?)?.cast<String, dynamic>() ?? const {};
    final planTasks = tasks.where((task) => task.planId == id).toList();
    final kind = _kind(json['kind']?.toString());
    return HealthPlan(
      id: id,
      title: json['title']?.toString() ?? '健康计划',
      description: json['subtitle']?.toString() ?? '每天坚持一点，健康更安心',
      completed: planTasks.where((task) => task.isCompleted).length,
      total: planTasks.length,
      icon: _icon(kind),
      kind: kind,
      status: json['status']?.toString() ?? 'active',
      reminderTime: schedule['time']?.toString() ?? '08:30',
      daysOfWeek:
          (schedule['daysOfWeek'] as List? ?? const [1, 2, 3, 4, 5, 6, 7])
              .whereType<num>()
              .map((day) => day.toInt())
              .toList(),
    );
  }

  HealthReading _healthFromJson(Map<String, dynamic> json) => HealthReading(
        id: json['id'].toString(),
        metric: _metric(json['metric']?.toString()),
        value: (json['value'] as Map?)?.cast<String, dynamic>() ?? const {},
        recordedAt: DateTime.parse(json['recordedAt'].toString()),
      );

  CareAlert _alertFromJson(Map<String, dynamic> json) => CareAlert(
        id: json['id'].toString(),
        level: json['level']?.toString() ?? 'L1',
        metric: _metric(json['metric']?.toString()),
        message: json['message']?.toString() ?? '有一条健康记录需要关注',
        status: json['status']?.toString() ?? 'pending',
        createdAt: DateTime.parse(json['createdAt'].toString()),
      );

  HealthMetric _metric(String? value) => HealthMetric.values.firstWhere(
        (metric) => metric.name == value,
        orElse: () => HealthMetric.mood,
      );

  TaskKind _kind(String? value) => TaskKind.values.firstWhere(
        (kind) => kind.name == value,
        orElse: () => TaskKind.custom,
      );

  IconData _icon(TaskKind kind) => switch (kind) {
        TaskKind.bloodPressure => Icons.monitor_heart_outlined,
        TaskKind.bloodGlucose => Icons.bloodtype_outlined,
        TaskKind.medicine => Icons.medication_outlined,
        TaskKind.walk => Icons.directions_walk_rounded,
        TaskKind.mood => Icons.mood_rounded,
        TaskKind.weight => Icons.monitor_weight_outlined,
        TaskKind.custom => Icons.fact_check_outlined,
      };

  String _timeLabel(DateTime? value) {
    if (value == null) return '按计划完成';
    final local = value.toLocal();
    final period = local.hour < 12
        ? '上午'
        : local.hour < 18
            ? '下午'
            : '晚上';
    final hour = local.hour > 12 ? local.hour - 12 : local.hour;
    return '$period $hour:${local.minute.toString().padLeft(2, '0')}';
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _idempotencyKey(String taskId) =>
      'app-$taskId-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }
}
