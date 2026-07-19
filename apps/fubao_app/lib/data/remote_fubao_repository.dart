import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../domain/models.dart';
import 'fubao_repository.dart';
import 'local_data_store.dart';
import 'remote_api_client.dart';

class RemoteFubaoRepository extends ChangeNotifier implements FubaoRepository {
  RemoteFubaoRepository(
    this._api, {
    LocalDataStore? localStore,
    Duration pollInterval = const Duration(seconds: 5),
  })  : _localStore = localStore ?? MemoryLocalDataStore(),
        _pollInterval = pollInterval;

  final RemoteApiClient _api;
  final LocalDataStore _localStore;
  final Duration _pollInterval;
  final List<HealthTask> _tasks = [];
  final List<HealthPlan> _plans = [];
  final List<CareTopic> _topics = [];
  final List<HealthReading> _healthReadings = [];
  final List<CareAlert> _alerts = [];
  final List<AppMessage> _messages = [];
  WeeklyHealthReport? _weeklyReport;
  FamilySpark _spark = const FamilySpark(
    lit: false,
    streakDays: 0,
    childActive: false,
    elderActive: false,
  );
  Timer? _poller;
  bool _refreshing = false;
  String? lastError;
  final List<Map<String, dynamic>> _pendingOperations = [];

  static const _snapshotKey = 'fubao-home-snapshot-v1';
  static const _queueKey = 'fubao-offline-queue-v1';

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
  List<AppMessage> get messages => List.unmodifiable(_messages);

  @override
  WeeklyHealthReport? get weeklyReport => _weeklyReport;

  @override
  String? get syncError => lastError;

  @override
  int get pendingSyncCount => _pendingOperations.length;

  @override
  int get completedTaskCount => _tasks.where((task) => task.isCompleted).length;

  @override
  bool get allTasksCompleted =>
      _tasks.isNotEmpty && _tasks.every((task) => task.isCompleted);

  void start() {
    if (_poller != null) return;
    unawaited(_startWithCache());
    _poller = Timer.periodic(_pollInterval, (_) => unawaited(refresh()));
  }

  Future<void> _startWithCache() async {
    await _restoreOfflineState();
    await refresh();
  }

  void clear() {
    _poller?.cancel();
    _poller = null;
    _tasks.clear();
    _plans.clear();
    _healthReadings.clear();
    _alerts.clear();
    _topics.clear();
    _messages.clear();
    _weeklyReport = null;
    _pendingOperations.clear();
    unawaited(_localStore.delete(_snapshotKey));
    unawaited(_localStore.delete(_queueKey));
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
      await _flushPendingOperations();
      final planData = await _api.get('plans');
      final taskData = await _api.get('tasks/today');
      final healthData = await _api.get('health-data');
      final alertData = await _api.get('alerts');
      final sparkData = await _api.get('sparks/current');
      final topicData = await _api.get('topics/today');
      final messageData = await _api.get('messages');
      final reportData = await _api.get('reports/weekly');
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
      _topics
        ..clear()
        ..addAll((topicData['items'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => _topicFromJson(item.cast<String, dynamic>())));
      _messages
        ..clear()
        ..addAll((messageData['items'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => _messageFromJson(item.cast<String, dynamic>())));
      final reportTasks =
          (reportData['tasks'] as Map?)?.cast<String, dynamic>() ?? const {};
      _weeklyReport = WeeklyHealthReport(
        from: DateTime.tryParse(reportData['from']?.toString() ?? '') ??
            DateTime.now().subtract(const Duration(days: 6)),
        to: DateTime.tryParse(reportData['to']?.toString() ?? '') ??
            DateTime.now(),
        completed: (reportTasks['completed'] as num?)?.toInt() ?? 0,
        total: (reportTasks['total'] as num?)?.toInt() ?? 0,
        completionRate: (reportData['completionRate'] as num?)?.toDouble() ?? 0,
      );
      _spark = FamilySpark(
        lit: sparkData['lit'] == true,
        streakDays: (sparkData['streakDays'] as num?)?.toInt() ?? 0,
        childActive: sparkData['childActive'] == true,
        elderActive: sparkData['elderActive'] == true,
      );
      lastError = null;
      await _saveSnapshot();
      notifyListeners();
    } on ApiException catch (error) {
      lastError = error.message;
      notifyListeners();
    } on http.ClientException {
      lastError = '网络不可用，正在显示最近一次数据';
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
    final key = idempotencyKey ?? _idempotencyKey(id);
    try {
      await _api.post(
        'tasks/$id/complete',
        body: const {},
        headers: {'Idempotency-Key': key},
      );
      await refresh();
    } catch (error) {
      if (!_canRetryOffline(error)) rethrow;
      await _queueTaskOperation(id, 'complete', key);
      _setLocalTaskState(id, completed: true, skipped: false);
    }
  }

  @override
  Future<void> setTaskSkipped(String id, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? _idempotencyKey(id);
    try {
      await _api.post(
        'tasks/$id/skip',
        body: const {},
        headers: {'Idempotency-Key': key},
      );
      await refresh();
    } catch (error) {
      if (!_canRetryOffline(error)) rethrow;
      await _queueTaskOperation(id, 'skip', key);
      _setLocalTaskState(id, completed: false, skipped: true);
    }
  }

  @override
  Future<void> updatePlanStatus(String id, String status) async {
    await _api.patch('plans/$id/status', body: {'status': status});
    await refresh();
  }

  @override
  Future<bool> remindTask(String id) async {
    final data = await _api.post('tasks/$id/remind');
    await refresh();
    return data['accepted'] == true;
  }

  @override
  Future<void> recordHealth(
    HealthMetric metric,
    Map<String, dynamic> value, {
    String? taskId,
  }) async {
    HealthTask? matchingTask;
    if (_api.session?.role == AppRole.elder) {
      for (final task in _tasks) {
        if (!task.isCompleted &&
            task.kind == _taskKindForMetric(metric) &&
            (taskId == null || task.id == taskId)) {
          matchingTask = task;
          break;
        }
      }
    }
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
    if (matchingTask != null) {
      await setTaskCompleted(matchingTask.id, true);
    } else {
      await refresh();
    }
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

  @override
  Future<void> markTopicCopied(String id) async {
    await _api.post('topics/$id/copied');
    await refresh();
  }

  @override
  Future<void> markMessageRead(String id) async {
    final data = await _api.patch('messages/$id/read');
    final index = _messages.indexWhere((message) => message.id == id);
    if (index != -1) _messages[index] = _messageFromJson(data);
    notifyListeners();
  }

  @override
  Future<Map<String, dynamic>> exportData() => _api.get('privacy/export');

  @override
  Future<DateTime> scheduleAccountDeletion() async {
    final data = await _api.delete('privacy/account');
    return DateTime.parse(data['deleteAfter'].toString());
  }

  @override
  Future<void> submitFeedback(String content) async {
    await _api.post('feedback', body: {'content': content});
  }

  @override
  Future<void> registerPushToken(String token) async {
    await _api.post('notifications/device-token', body: {
      'token': token,
      'platform': 'ios',
      'environment': const String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'dev',
      ),
    });
  }

  @override
  Future<Map<String, dynamic>> familyDetails() => _api.get('families/current');

  @override
  Future<Map<String, dynamic>> elderHealthProfile() =>
      _api.get('profiles/elder');

  @override
  Future<Map<String, dynamic>> updateElderHealthProfile(
    Map<String, dynamic> profile,
  ) =>
      _api.put('profiles/elder', body: profile);

  @override
  Future<Map<String, dynamic>> currentDevice() => _api.get('devices/current');

  @override
  Future<Map<String, dynamic>> discoverDevice() async {
    final data = await _api.post('devices/discover');
    final devices = data['devices'] as List? ?? const [];
    if (devices.isEmpty) return const {};
    return (devices.first as Map).cast<String, dynamic>();
  }

  @override
  Future<Map<String, dynamic>> activateDevice(
    String serialNumber,
    String networkName,
  ) =>
      _api.post('devices/activate', body: {
        'serialNumber': serialNumber,
        'networkName': networkName,
      });

  @override
  Future<Map<String, dynamic>> updateDeviceSettings(
    Map<String, dynamic> settings,
  ) =>
      _api.patch('devices/settings', body: settings);

  @override
  Future<Map<String, dynamic>> setDeviceOnline(bool online) => _api.patch(
        'devices/status',
        body: {'status': online ? 'online' : 'offline'},
      );

  @override
  Future<Map<String, dynamic>> unbindDevice() => _api.delete('devices/current');

  @override
  Future<Map<String, dynamic>> factoryResetDevice() =>
      _api.post('devices/factory-reset');

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
      scheduledDate: DateTime.tryParse(json['date']?.toString() ?? ''),
      remindedAt: DateTime.tryParse(json['remindedAt']?.toString() ?? ''),
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

  CareTopic _topicFromJson(Map<String, dynamic> json) => CareTopic(
        id: json['id'].toString(),
        title: json['title']?.toString() ?? '暖心话题',
        description: json['description']?.toString() ?? '',
        suggestedWords: json['suggestedWords']?.toString() ?? '',
        icon: Icons.chat_bubble_rounded,
      );

  AppMessage _messageFromJson(Map<String, dynamic> json) => AppMessage(
        id: json['id'].toString(),
        type: AppMessageType.values.firstWhere(
          (type) => type.name == json['type']?.toString(),
          orElse: () => AppMessageType.system,
        ),
        title: json['title']?.toString() ?? '福豹消息',
        body: json['body']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        readAt: DateTime.tryParse(json['readAt']?.toString() ?? ''),
      );

  HealthMetric _metric(String? value) => HealthMetric.values.firstWhere(
        (metric) => metric.name == value,
        orElse: () => HealthMetric.mood,
      );

  TaskKind _kind(String? value) => TaskKind.values.firstWhere(
        (kind) => kind.name == value,
        orElse: () => TaskKind.custom,
      );

  TaskKind _taskKindForMetric(HealthMetric metric) => switch (metric) {
        HealthMetric.bloodPressure => TaskKind.bloodPressure,
        HealthMetric.bloodGlucose => TaskKind.bloodGlucose,
        HealthMetric.mood => TaskKind.mood,
        HealthMetric.weight => TaskKind.weight,
      };

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

  bool _canRetryOffline(Object error) =>
      error is http.ClientException ||
      error is ApiException &&
          (error.statusCode == 408 || error.statusCode >= 500);

  Future<void> _queueTaskOperation(
    String taskId,
    String action,
    String idempotencyKey,
  ) async {
    if (_pendingOperations
        .any((operation) => operation['idempotencyKey'] == idempotencyKey)) {
      return;
    }
    _pendingOperations.add({
      'taskId': taskId,
      'action': action,
      'idempotencyKey': idempotencyKey,
      'createdAt': DateTime.now().toIso8601String(),
    });
    lastError = '网络不可用，操作已保存，将在联网后自动同步';
    await _saveQueue();
  }

  void _setLocalTaskState(
    String id, {
    required bool completed,
    required bool skipped,
  }) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        isCompleted: completed,
        isSkipped: skipped,
        recordedAt: DateTime.now(),
        clearReminder: completed,
      );
    }
    unawaited(_saveSnapshot());
    notifyListeners();
  }

  Future<void> _flushPendingOperations() async {
    while (_pendingOperations.isNotEmpty) {
      final operation = _pendingOperations.first;
      await _api.post(
        'tasks/${operation['taskId']}/${operation['action']}',
        body: const {},
        headers: {
          'Idempotency-Key': operation['idempotencyKey'].toString(),
        },
      );
      _pendingOperations.removeAt(0);
      await _saveQueue();
    }
  }

  Future<void> _restoreOfflineState() async {
    try {
      final queueRaw = await _localStore.read(_queueKey);
      if (queueRaw != null) {
        _pendingOperations
          ..clear()
          ..addAll((jsonDecode(queueRaw) as List)
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>()));
      }
      final raw = await _localStore.read(_snapshotKey);
      if (raw == null || _tasks.isNotEmpty) return;
      final data = (jsonDecode(raw) as Map).cast<String, dynamic>();
      _tasks.addAll((data['tasks'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => _taskFromCache(item.cast<String, dynamic>())));
      _plans.addAll((data['plans'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => _planFromCache(item.cast<String, dynamic>())));
      final spark = (data['spark'] as Map?)?.cast<String, dynamic>();
      if (spark != null) {
        _spark = FamilySpark(
          lit: spark['lit'] == true,
          streakDays: (spark['streakDays'] as num?)?.toInt() ?? 0,
          childActive: spark['childActive'] == true,
          elderActive: spark['elderActive'] == true,
        );
      }
      lastError = '当前显示最近一次数据，正在尝试同步';
      notifyListeners();
    } catch (_) {
      await _localStore.delete(_snapshotKey);
      await _localStore.delete(_queueKey);
    }
  }

  Future<void> _saveSnapshot() => _localStore.write(
        _snapshotKey,
        jsonEncode({
          'savedAt': DateTime.now().toIso8601String(),
          'tasks': _tasks.map(_taskToCache).toList(),
          'plans': _plans.map(_planToCache).toList(),
          'spark': {
            'lit': _spark.lit,
            'streakDays': _spark.streakDays,
            'childActive': _spark.childActive,
            'elderActive': _spark.elderActive,
          },
        }),
      );

  Future<void> _saveQueue() =>
      _localStore.write(_queueKey, jsonEncode(_pendingOperations));

  Map<String, dynamic> _taskToCache(HealthTask task) => {
        'id': task.id,
        'planId': task.planId,
        'title': task.title,
        'subtitle': task.subtitle,
        'timeLabel': task.timeLabel,
        'kind': task.kind.name,
        'isCompleted': task.isCompleted,
        'isSkipped': task.isSkipped,
        'recordedAt': task.recordedAt?.toIso8601String(),
        'recordData': task.recordData,
        'scheduledDate': task.scheduledDate?.toIso8601String(),
        'remindedAt': task.remindedAt?.toIso8601String(),
      };

  HealthTask _taskFromCache(Map<String, dynamic> json) => HealthTask(
        id: json['id'].toString(),
        planId: json['planId']?.toString(),
        title: json['title']?.toString() ?? '健康任务',
        subtitle: json['subtitle']?.toString() ?? '',
        timeLabel: json['timeLabel']?.toString() ?? '按计划完成',
        kind: _kind(json['kind']?.toString()),
        isCompleted: json['isCompleted'] == true,
        isSkipped: json['isSkipped'] == true,
        recordedAt: DateTime.tryParse(json['recordedAt']?.toString() ?? ''),
        recordData: (json['recordData'] as Map?)?.cast<String, dynamic>(),
        scheduledDate:
            DateTime.tryParse(json['scheduledDate']?.toString() ?? ''),
        remindedAt: DateTime.tryParse(json['remindedAt']?.toString() ?? ''),
      );

  Map<String, dynamic> _planToCache(HealthPlan plan) => {
        'id': plan.id,
        'title': plan.title,
        'description': plan.description,
        'completed': plan.completed,
        'total': plan.total,
        'kind': plan.kind.name,
        'status': plan.status,
        'reminderTime': plan.reminderTime,
        'daysOfWeek': plan.daysOfWeek,
      };

  HealthPlan _planFromCache(Map<String, dynamic> json) {
    final kind = _kind(json['kind']?.toString());
    return HealthPlan(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '健康计划',
      description: json['description']?.toString() ?? '',
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      icon: _icon(kind),
      kind: kind,
      status: json['status']?.toString() ?? 'active',
      reminderTime: json['reminderTime']?.toString() ?? '08:30',
      daysOfWeek: (json['daysOfWeek'] as List? ?? const [])
          .whereType<num>()
          .map((day) => day.toInt())
          .toList(),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }
}
