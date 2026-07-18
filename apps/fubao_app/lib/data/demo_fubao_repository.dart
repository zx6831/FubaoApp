import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'fubao_repository.dart';

class DemoFubaoRepository extends ChangeNotifier implements FubaoRepository {
  DemoFubaoRepository()
      : _tasks = [
          const HealthTask(
            id: 'medicine',
            title: '降压药 1 片',
            subtitle: '饭后温水服用',
            timeLabel: '上午 8:30',
            kind: TaskKind.medicine,
          ),
          const HealthTask(
            id: 'pressure',
            title: '记录血压',
            subtitle: '坐下休息 5 分钟后测量',
            timeLabel: '上午 9:00',
            kind: TaskKind.bloodPressure,
            isCompleted: true,
          ),
          const HealthTask(
            id: 'walk',
            title: '下午散步 20 分钟',
            subtitle: '按自己的节奏慢慢走',
            timeLabel: '下午 3:30',
            kind: TaskKind.walk,
          ),
          const HealthTask(
            id: 'mood',
            title: '记录今天心情',
            subtitle: '选一个最接近的心情',
            timeLabel: '晚上 8:30',
            kind: TaskKind.mood,
            isCompleted: true,
          ),
        ];

  List<HealthTask> _tasks;
  final Map<String, dynamic> _device = {
    'id': 'demo-device',
    'serialNumber': 'FB-DEMO-001',
    'firmware': '1.0.0',
    'status': 'online',
    'lastOnlineAt': '2026-07-18T08:30:00.000Z',
    'activatedAt': '2026-07-18T08:00:00.000Z',
    'settings': {
      'volume': 60,
      'speechRate': 50,
      'dndEnabled': true,
      'dndStart': '22:00',
      'dndEnd': '07:00',
    },
  };
  final Map<String, dynamic> _healthProfile = {
    'userId': 'demo-elder',
    'relativeName': '妈妈',
    'heightCm': 162,
    'weightKg': 58.5,
    'chronicConditions': const ['高血压'],
    'medicationHistory': const <String, dynamic>{},
    'medicalHistory': const <String, dynamic>{},
    'emergencyContact': '138****0000',
    'consentAt': '2026-07-18T08:00:00.000Z',
  };

  @override
  List<HealthTask> get tasks => List.unmodifiable(_tasks);

  @override
  final List<HealthPlan> plans = [
    HealthPlan(
      id: 'blood-pressure',
      title: '血压管理',
      description: '记录血压，关注变化，保持规律',
      completed: 3,
      total: 4,
      icon: Icons.monitor_heart_outlined,
    ),
    HealthPlan(
      id: 'healthy-life',
      title: '健康生活习惯',
      description: '规律作息，适度运动，轻松坚持',
      completed: 1,
      total: 2,
      icon: Icons.directions_walk_rounded,
    ),
  ];

  @override
  final topics = const [
    CareTopic(
      id: 'task-done',
      title: '妈妈今天按时完成了任务',
      description: '肯定她的坚持和努力，让她感受到你的理解与支持。',
      suggestedWords: '妈，今天的任务完成得很棒，辛苦啦！晚上好好休息。',
      icon: Icons.fact_check_rounded,
    ),
    CareTopic(
      id: 'walk-chat',
      title: '从散步聊起',
      description: '聊聊路边的风景，也聊聊彼此今天的心情。',
      suggestedWords: '妈，下午散步时看到什么有意思的事了吗？',
      icon: Icons.park_rounded,
    ),
  ];

  @override
  int get completedTaskCount => _tasks.where((task) => task.isCompleted).length;
  @override
  bool get allTasksCompleted => _tasks.every((task) => task.isCompleted);

  @override
  final List<HealthReading> healthReadings = [
    HealthReading(
      id: 'pressure-demo',
      metric: HealthMetric.bloodPressure,
      value: const {'systolic': 128, 'diastolic': 82, 'unit': 'mmHg'},
      recordedAt: DateTime(2026, 7, 18, 8, 30),
    ),
    HealthReading(
      id: 'mood-demo',
      metric: HealthMetric.mood,
      value: const {'text': '愉快'},
      recordedAt: DateTime(2026, 7, 18, 20, 30),
    ),
  ];

  @override
  final List<CareAlert> alerts = [];

  @override
  FamilySpark get spark => const FamilySpark(
        lit: true,
        streakDays: 12,
        childActive: true,
        elderActive: true,
      );

  @override
  List<AppMessage> messages = [
    AppMessage(
      id: 'weekly-report-demo',
      type: AppMessageType.weeklyReport,
      title: '本周健康周报已生成',
      body: '看看本周任务完成与健康记录变化。',
      createdAt: DateTime(2026, 7, 18, 8, 30),
    ),
    AppMessage(
      id: 'insight-demo',
      type: AppMessageType.insight,
      title: '健康小知识',
      body: '规律记录比单次数字更有参考价值。',
      createdAt: DateTime(2026, 7, 17, 21, 10),
    ),
  ];

  @override
  WeeklyHealthReport get weeklyReport => WeeklyHealthReport(
        from: DateTime(2026, 3, 31),
        to: DateTime(2026, 4, 6),
        completed: completedTaskCount,
        total: tasks.length,
        completionRate: tasks.isEmpty ? 0 : completedTaskCount / tasks.length,
      );

  @override
  String? get syncError => null;

  @override
  int get pendingSyncCount => 0;

  @override
  Future<void> refresh() async {}

  @override
  Future<List<HealthTask>> tasksForDate(DateTime date) async => tasks;

  @override
  Future<List<HealthTask>> taskHistory(DateTime from, DateTime to) async =>
      tasks;

  @override
  Future<HealthPlan> createPlan(PlanDraft draft) async {
    final plan = HealthPlan(
      id: 'demo-${DateTime.now().microsecondsSinceEpoch}',
      title: draft.title,
      description: draft.subtitle,
      completed: 0,
      total: 1,
      icon: Icons.fact_check_outlined,
      kind: draft.kind,
      reminderTime: draft.reminderTime,
      daysOfWeek: draft.daysOfWeek,
    );
    plans.add(plan);
    notifyListeners();
    return plan;
  }

  @override
  Future<void> setTaskCompleted(
    String id,
    bool value, {
    String? idempotencyKey,
  }) async {
    _tasks = [
      for (final task in _tasks)
        if (task.id == id) task.copyWith(isCompleted: value) else task,
    ];
    notifyListeners();
  }

  @override
  Future<void> setTaskSkipped(String id, {String? idempotencyKey}) async {
    _tasks = [
      for (final task in _tasks)
        if (task.id == id)
          task.copyWith(isCompleted: false, isSkipped: true)
        else
          task,
    ];
    notifyListeners();
  }

  @override
  Future<void> updatePlanStatus(String id, String status) async {
    final index = plans.indexWhere((plan) => plan.id == id);
    if (index == -1) return;
    final plan = plans[index];
    plans[index] = HealthPlan(
      id: plan.id,
      title: plan.title,
      description: plan.description,
      completed: plan.completed,
      total: plan.total,
      icon: plan.icon,
      kind: plan.kind,
      status: status,
      reminderTime: plan.reminderTime,
      daysOfWeek: plan.daysOfWeek,
    );
    notifyListeners();
  }

  @override
  Future<bool> remindTask(String id) async => true;

  @override
  Future<void> recordHealth(
    HealthMetric metric,
    Map<String, dynamic> value,
  ) async {
    healthReadings.insert(
        0,
        HealthReading(
          id: 'demo-health-${DateTime.now().microsecondsSinceEpoch}',
          metric: metric,
          value: value,
          recordedAt: DateTime.now(),
        ));
    notifyListeners();
  }

  @override
  Future<void> updateAlert(
    String id,
    String status, {
    String? closeReason,
  }) async {
    final index = alerts.indexWhere((alert) => alert.id == id);
    if (index == -1) return;
    final alert = alerts[index];
    alerts[index] = CareAlert(
      id: alert.id,
      level: alert.level,
      metric: alert.metric,
      message: alert.message,
      status: status,
      createdAt: alert.createdAt,
    );
    notifyListeners();
  }

  @override
  Future<void> markTopicCopied(String id) async {}

  @override
  Future<void> markMessageRead(String id) async {
    messages = [
      for (final message in messages)
        if (message.id == id)
          message.copyWith(readAt: DateTime.now())
        else
          message,
    ];
    notifyListeners();
  }

  @override
  Future<Map<String, dynamic>> exportData() async => {
        'generatedAt': DateTime.now().toIso8601String(),
        'mode': 'demo',
        'tasks': [
          for (final task in tasks)
            {
              'id': task.id,
              'title': task.title,
              'completed': task.isCompleted,
            },
        ],
        'healthReadings': healthReadings.length,
      };

  @override
  Future<DateTime> scheduleAccountDeletion() async =>
      DateTime.now().add(const Duration(days: 30));

  @override
  Future<void> submitFeedback(String content) async {}

  @override
  Future<void> registerPushToken(String token) async {}

  @override
  Future<Map<String, dynamic>> familyDetails() async => {
        'id': 'demo-family',
        'ownerId': 'demo-child',
        'members': const [
          {'userId': 'demo-child', 'role': 'child', 'nickname': '小雨'},
          {'userId': 'demo-elder', 'role': 'elder', 'nickname': '王阿姨'},
        ],
      };

  @override
  Future<Map<String, dynamic>> elderHealthProfile() async =>
      Map<String, dynamic>.from(_healthProfile);

  @override
  Future<Map<String, dynamic>> updateElderHealthProfile(
    Map<String, dynamic> profile,
  ) async {
    _healthProfile.addAll(profile);
    _healthProfile['consentAt'] = DateTime.now().toIso8601String();
    notifyListeners();
    return Map<String, dynamic>.from(_healthProfile);
  }

  @override
  Future<Map<String, dynamic>> currentDevice() async =>
      Map<String, dynamic>.from(_device);

  @override
  Future<Map<String, dynamic>> updateDeviceSettings(
    Map<String, dynamic> settings,
  ) async {
    _device['settings'] = Map<String, dynamic>.from(settings);
    notifyListeners();
    return Map<String, dynamic>.from(settings);
  }

  @override
  Future<Map<String, dynamic>> setDeviceOnline(bool online) async {
    _device['status'] = online ? 'online' : 'offline';
    notifyListeners();
    return Map<String, dynamic>.from(_device);
  }

  @override
  Future<Map<String, dynamic>> unbindDevice() async {
    _device['status'] = 'unbound';
    notifyListeners();
    return {
      'unbound': true,
      'dataRetainedUntil':
          DateTime.now().add(const Duration(days: 90)).toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>> factoryResetDevice() async {
    _device
      ..['status'] = 'discovered'
      ..['activatedAt'] = null
      ..['lastOnlineAt'] = null
      ..['settings'] = {
        'volume': 60,
        'speechRate': 50,
        'dndEnabled': true,
        'dndStart': '22:00',
        'dndEnd': '07:00',
      };
    notifyListeners();
    return Map<String, dynamic>.from(_device);
  }
}
