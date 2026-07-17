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

enum HealthMetric { bloodPressure, bloodGlucose, mood, weight }

@immutable
class HealthReading {
  const HealthReading({
    required this.id,
    required this.metric,
    required this.value,
    required this.recordedAt,
  });
  final String id;
  final HealthMetric metric;
  final Map<String, dynamic> value;
  final DateTime recordedAt;
}

@immutable
class CareAlert {
  const CareAlert({
    required this.id,
    required this.level,
    required this.metric,
    required this.message,
    required this.status,
    required this.createdAt,
  });
  final String id;
  final String level;
  final HealthMetric metric;
  final String message;
  final String status;
  final DateTime createdAt;
}

@immutable
class FamilySpark {
  const FamilySpark({
    required this.lit,
    required this.streakDays,
    required this.childActive,
    required this.elderActive,
  });
  final bool lit;
  final int streakDays;
  final bool childActive;
  final bool elderActive;
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

enum AppMessageType { weeklyReport, alert, system, insight }

@immutable
class AppMessage {
  const AppMessage({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final AppMessageType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  AppMessage copyWith({DateTime? readAt}) => AppMessage(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
      );
}

@immutable
class WeeklyHealthReport {
  const WeeklyHealthReport({
    required this.from,
    required this.to,
    required this.completed,
    required this.total,
    required this.completionRate,
  });

  final DateTime from;
  final DateTime to;
  final int completed;
  final int total;
  final double completionRate;
}
