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
  Future<void> refresh() async {}

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
  Future<void> updatePlanStatus(String id, String status) async {}

  @override
  Future<bool> remindTask(String id) async => true;
}
