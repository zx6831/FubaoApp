import 'package:flutter/material.dart';

import '../../data/fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../design/fubao_illustrations.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';
import '../health/health_center_page.dart';
import '../plans/task_history_page.dart';

class ElderPlansPage extends StatefulWidget {
  const ElderPlansPage({required this.repository, this.today, super.key});
  final FubaoRepository repository;
  final DateTime? today;

  @override
  State<ElderPlansPage> createState() => _ElderPlansPageState();
}

class _ElderPlansPageState extends State<ElderPlansPage> {
  List<HealthTask> history = const [];

  DateTime get today {
    final value = widget.today ?? DateTime.now();
    return DateTime(value.year, value.month, value.day);
  }

  @override
  void initState() {
    super.initState();
    _loadWeek();
  }

  Future<void> _loadWeek() async {
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final result = await widget.repository.taskHistory(
      monday,
      monday.add(const Duration(days: 6)),
    );
    if (mounted) setState(() => history = result);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: widget.repository,
          builder: (context, _) {
            final ordered = [...widget.repository.tasks]..sort((a, b) {
                if (a.isCompleted != b.isCompleted) {
                  return a.isCompleted ? 1 : -1;
                }
                return _taskMinutes(a).compareTo(_taskMinutes(b));
              });
            HealthTask? nextTask;
            for (final task in ordered) {
              if (!task.isCompleted && !task.isSkipped) {
                nextTask = task;
                break;
              }
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Expanded(
                      child: Text('我的计划',
                          style: TextStyle(
                              fontSize: 39, fontWeight: FontWeight.w900))),
                  ReadAloudButton(
                    text: ordered.isEmpty
                        ? '我的计划。今天还没有任务。'
                        : '我的计划。今天共有${ordered.length}项任务。',
                  ),
                ]),
                const SizedBox(height: 22),
                _ElderWeekStrip(
                  today: today,
                  history: history,
                  currentTasks: widget.repository.tasks,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TaskHistoryPage(
                        repository: widget.repository,
                        elder: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                if (nextTask != null) ...[
                  const Text('接下来的事',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  _ElderTaskCard(
                    task: nextTask,
                    illustration: _illustrationFor(nextTask.kind),
                    onTap: () => _completePlanTask(
                      context,
                      widget.repository,
                      nextTask!,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                const Text('今天的任务',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                if (ordered.isEmpty)
                  FubaoCard(
                    padding: const EdgeInsets.all(26),
                    child: const Center(
                        child: Text('今天还没有任务',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800))),
                  )
                else
                  for (var i = 0; i < ordered.length; i++) ...[
                    _ElderTaskCard(
                      task: ordered[i],
                      illustration: _illustrationFor(ordered[i].kind),
                      completed: ordered[i].isCompleted,
                      onTap: () => _completePlanTask(
                        context,
                        widget.repository,
                        ordered[i],
                      ),
                    ),
                    if (i != ordered.length - 1) const SizedBox(height: 12),
                  ],
              ],
            );
          },
        ),
      );
}

int _taskMinutes(HealthTask task) {
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(task.timeLabel);
  if (match == null) return 24 * 60;
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (task.timeLabel.contains('下午') && hour < 12) hour += 12;
  if (task.timeLabel.contains('晚上') && hour < 12) hour += 12;
  return hour * 60 + minute;
}

FubaoIllustration _illustrationFor(TaskKind kind) => switch (kind) {
      TaskKind.medicine => FubaoIllustration.pill,
      TaskKind.bloodPressure => FubaoIllustration.elderBloodPressureDevice,
      TaskKind.walk => FubaoIllustration.elderPark,
      TaskKind.mood => FubaoIllustration.elderMood,
      _ => FubaoIllustration.planClipboard,
    };

class _ElderWeekStrip extends StatelessWidget {
  const _ElderWeekStrip({
    required this.today,
    required this.history,
    required this.currentTasks,
    required this.onTap,
  });
  final DateTime today;
  final List<HealthTask> history;
  final List<HealthTask> currentTasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final days = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
    return FubaoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (final date in days)
          Builder(builder: (context) {
            final isToday = _sameDay(date, today);
            final dayTasks = isToday
                ? currentTasks
                : history
                    .where((task) =>
                        task.scheduledDate != null &&
                        _sameDay(task.scheduledDate!, date))
                    .toList();
            final completed = dayTasks.isNotEmpty &&
                dayTasks.every((task) => task.isCompleted);
            final hasTasks = dayTasks.isNotEmpty;
            return KeyedSubtree(
              key: Key('elder-week-day-${date.weekday}'),
              child: _WeekDay(
                label: isToday ? '今' : _weekdayLabel(date.weekday),
                isToday: isToday,
                hasTasks: hasTasks,
                completed: completed,
              ),
            );
          }),
      ]),
    );
  }
}

class _WeekDay extends StatelessWidget {
  const _WeekDay({
    required this.label,
    required this.isToday,
    required this.hasTasks,
    required this.completed,
  });
  final String label;
  final bool isToday;
  final bool hasTasks;
  final bool completed;

  @override
  Widget build(BuildContext context) => Container(
        padding: isToday
            ? const EdgeInsets.symmetric(horizontal: 9, vertical: 7)
            : EdgeInsets.zero,
        decoration: isToday
            ? BoxDecoration(
                color: const Color(0xFFF0FAF6),
                border: Border.all(color: FubaoColors.mint),
                borderRadius: BorderRadius.circular(22),
              )
            : null,
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  color: isToday ? FubaoColors.mintStrong : FubaoColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: completed
                  ? FubaoColors.mintStrong
                  : isToday && hasTasks
                      ? FubaoColors.mint
                      : Colors.transparent,
              shape: BoxShape.circle,
              border: !completed && !(isToday && hasTasks)
                  ? Border.all(color: const Color(0xFFBBBBBB), width: 1.5)
                  : null,
            ),
            child: completed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
        ]),
      );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _weekdayLabel(int weekday) =>
    const ['一', '二', '三', '四', '五', '六', '日'][weekday - 1];

Future<void> _completePlanTask(
  BuildContext context,
  FubaoRepository repository,
  HealthTask task,
) async {
  final metric = switch (task.kind) {
    TaskKind.bloodPressure => HealthMetric.bloodPressure,
    TaskKind.bloodGlucose => HealthMetric.bloodGlucose,
    TaskKind.mood => HealthMetric.mood,
    TaskKind.weight => HealthMetric.weight,
    _ => null,
  };
  if (metric != null) {
    await showHealthRecordDialog(context, repository, metric, elder: true);
  } else {
    await repository.setTaskCompleted(task.id, true);
  }
}

class _ElderTaskCard extends StatelessWidget {
  const _ElderTaskCard(
      {required this.task,
      required this.illustration,
      required this.onTap,
      this.completed = false});
  final HealthTask task;
  final FubaoIllustration illustration;
  final VoidCallback onTap;
  final bool completed;
  @override
  Widget build(BuildContext context) => FubaoCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          FubaoIllustrationBubble(
            illustration: illustration,
            size: 120,
          ),
          const SizedBox(width: 18),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(task.title,
                    style: const TextStyle(
                        fontSize: 27, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      completed
                          ? Icons.check_circle_rounded
                          : Icons.access_time_rounded,
                      size: 24,
                      color: FubaoColors.mintStrong,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        completed ? '已完成' : task.timeLabel,
                        style: const TextStyle(
                          color: FubaoColors.mintStrong,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ])),
          if (!completed)
            const Icon(Icons.chevron_right_rounded,
                color: FubaoColors.inkMuted, size: 38),
        ]),
      );
}
