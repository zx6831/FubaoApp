import 'package:flutter/material.dart';

enum AppRole { child, elder }

enum TaskKind {
  medicine,
  bloodPressure,
  bloodGlucose,
  walk,
  mood,
  weight,
  custom,
}

@immutable
class HealthTask {
  const HealthTask({
    required this.id,
    this.planId,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.kind,
    this.isCompleted = false,
    this.isSkipped = false,
    this.recordedAt,
    this.recordData,
  });

  final String id;
  final String? planId;
  final String title;
  final String subtitle;
  final String timeLabel;
  final TaskKind kind;
  final bool isCompleted;
  final bool isSkipped;
  final DateTime? recordedAt;
  final Map<String, dynamic>? recordData;

  HealthTask copyWith({
    bool? isCompleted,
    bool? isSkipped,
    DateTime? recordedAt,
    Map<String, dynamic>? recordData,
  }) =>
      HealthTask(
        id: id,
        planId: planId,
        title: title,
        subtitle: subtitle,
        timeLabel: timeLabel,
        kind: kind,
        isCompleted: isCompleted ?? this.isCompleted,
        isSkipped: isSkipped ?? this.isSkipped,
        recordedAt: recordedAt ?? this.recordedAt,
        recordData: recordData ?? this.recordData,
      );
}

@immutable
class HealthPlan {
  const HealthPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.total,
    required this.icon,
    this.kind = TaskKind.custom,
    this.status = 'active',
    this.reminderTime = '08:30',
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
  });

  final String id;
  final String title;
  final String description;
  final int completed;
  final int total;
  final IconData icon;
  final TaskKind kind;
  final String status;
  final String reminderTime;
  final List<int> daysOfWeek;
}

@immutable
class PlanDraft {
  const PlanDraft({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.startsOn,
    required this.reminderTime,
    required this.daysOfWeek,
    this.enrollmentData = const {},
  });

  final TaskKind kind;
  final String title;
  final String subtitle;
  final DateTime startsOn;
  final String reminderTime;
  final List<int> daysOfWeek;
  final Map<String, dynamic> enrollmentData;
}

@immutable
class CareTopic {
  const CareTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.suggestedWords,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final String suggestedWords;
  final IconData icon;
}
