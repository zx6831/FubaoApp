import 'package:flutter/material.dart';

enum AppRole { child, elder }

enum TaskKind { medicine, bloodPressure, walk, mood }

@immutable
class HealthTask {
  const HealthTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.kind,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String timeLabel;
  final TaskKind kind;
  final bool isCompleted;

  HealthTask copyWith({bool? isCompleted}) => HealthTask(
        id: id,
        title: title,
        subtitle: subtitle,
        timeLabel: timeLabel,
        kind: kind,
        isCompleted: isCompleted ?? this.isCompleted,
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
  });

  final String id;
  final String title;
  final String description;
  final int completed;
  final int total;
  final IconData icon;
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
