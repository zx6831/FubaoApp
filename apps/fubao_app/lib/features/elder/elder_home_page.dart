import 'package:flutter/material.dart';

import '../../data/fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../design/fubao_illustrations.dart';
import '../../widgets/fubao_widgets.dart';
import '../../domain/models.dart';
import '../health/health_center_page.dart';

class ElderHomePage extends StatelessWidget {
  const ElderHomePage({required this.repository, super.key});
  final FubaoRepository repository;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: repository,
          builder: (context, _) {
            final tasks = _orderedTasks(repository.tasks);
            final task = _firstPendingTask(tasks);
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('早上好，王阿姨',
                            style: TextStyle(
                                fontSize: 35,
                                fontWeight: FontWeight.w900,
                                height: 1.2)),
                        SizedBox(height: 14),
                        SparkBadge(spark: repository.spark, compact: true),
                      ])),
                  ReadAloudButton(
                    text: task == null
                        ? '早上好，王阿姨。今天还没有任务。'
                        : '早上好，王阿姨。今天要做的事是${task.title}。',
                  ),
                ]),
                const SizedBox(height: 20),
                if (tasks.isEmpty)
                  FubaoCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(children: [
                      const Icon(Icons.event_available_rounded,
                          size: 58, color: FubaoColors.mintStrong),
                      const SizedBox(height: 14),
                      const Text('今天还没有任务',
                          style: TextStyle(
                              fontSize: 27, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      const Text('家人创建计划后，会在这里提醒你',
                          style: TextStyle(
                              color: FubaoColors.inkMuted, fontSize: 18)),
                      const SizedBox(height: 18),
                      _AnimatedRefreshButton(onRefresh: repository.refresh),
                    ]),
                  )
                else
                  _TodayTaskPager(repository: repository, tasks: tasks),
                const SizedBox(height: 16),
                FubaoCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          HealthCenterPage(repository: repository, elder: true),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Row(children: [
                    FubaoIllustrationAsset(
                        FubaoIllustration.elderBloodPressureDevice,
                        width: 126,
                        height: 104),
                    SizedBox(width: 14),
                    Expanded(
                        child: Text('健康记录',
                            style: TextStyle(
                                fontSize: 29, fontWeight: FontWeight.w900))),
                    CircleAvatar(
                        radius: 28,
                        backgroundColor: FubaoColors.mintStrong,
                        child: Icon(Icons.chevron_right_rounded,
                            color: Colors.white, size: 40)),
                  ]),
                ),
              ],
            );
          },
        ),
      );
}

typedef _TaskPresentation = ({
  FubaoIllustration illustration,
  String completeLabel,
  String skipLabel,
  IconData completeIcon,
  HealthMetric? metric,
});

class _TodayTaskPager extends StatefulWidget {
  const _TodayTaskPager({required this.repository, required this.tasks});

  final FubaoRepository repository;
  final List<HealthTask> tasks;

  @override
  State<_TodayTaskPager> createState() => _TodayTaskPagerState();
}

class _TodayTaskPagerState extends State<_TodayTaskPager> {
  late final PageController controller;
  late Map<String, bool> completionState;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = _firstPendingIndex(widget.tasks);
    controller = PageController(initialPage: currentIndex);
    completionState = {
      for (final task in widget.tasks) task.id: task.isCompleted,
    };
  }

  @override
  void didUpdateWidget(covariant _TodayTaskPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.tasks.map((task) => task.id).join('|');
    final newIds = widget.tasks.map((task) => task.id).join('|');
    final newlyCompleted = widget.tasks.any(
      (task) => task.isCompleted && completionState[task.id] == false,
    );
    completionState = {
      for (final task in widget.tasks) task.id: task.isCompleted,
    };
    if (newlyCompleted || oldIds != newIds) {
      _showFirstPendingTask();
    }
  }

  void _showFirstPendingTask() {
    final target = _firstPendingIndex(widget.tasks);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FubaoCard(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '今天要做的事',
                    style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '${currentIndex + 1}/${widget.tasks.length}',
                  key: const Key('elder-task-page-label'),
                  style: const TextStyle(
                    color: FubaoColors.inkMuted,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 360,
              child: PageView.builder(
                key: const Key('elder-task-pager'),
                controller: controller,
                itemCount: widget.tasks.length,
                onPageChanged: (index) => setState(() => currentIndex = index),
                itemBuilder: (context, index) => _TodayTaskPage(
                  key: ValueKey(widget.tasks[index].id),
                  repository: widget.repository,
                  task: widget.tasks[index],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < widget.tasks.length; index++)
                  AnimatedContainer(
                    key: Key('elder-task-page-dot-$index'),
                    duration: const Duration(milliseconds: 180),
                    width: index == currentIndex ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == currentIndex
                          ? FubaoColors.mintStrong
                          : FubaoColors.divider,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
}

class _TodayTaskPage extends StatelessWidget {
  const _TodayTaskPage({
    required this.repository,
    required this.task,
    super.key,
  });

  final FubaoRepository repository;
  final HealthTask task;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(task);
    return Column(
      children: [
        Row(
          children: [
            FubaoIllustrationBubble(
              key: Key('elder-task-illustration-${task.kind.name}'),
              illustration: presentation.illustration,
              size: 120,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 25,
                        color: FubaoColors.mintStrong,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.timeLabel,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (!task.isCompleted) ...[
          _LargeTaskButton(
            label: presentation.completeLabel,
            icon: presentation.completeIcon,
            color: FubaoColors.mintStrong,
            onTap: () => _completeTask(
              context,
              repository,
              task,
              presentation,
            ),
          ),
          const SizedBox(height: 12),
          _LargeTaskButton(
            label: presentation.skipLabel,
            icon: Icons.radio_button_unchecked_rounded,
            color: FubaoColors.orangeStrong,
            onTap: () async {
              await repository.setTaskSkipped(task.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '已记录“${presentation.skipLabel}”，家人会看到这个状态',
                  ),
                ),
              );
            },
          ),
        ] else
          _LargeTaskButton(
            label: '已完成',
            icon: Icons.check_circle_rounded,
            color: FubaoColors.mintStrong,
          ),
      ],
    );
  }
}

class _AnimatedRefreshButton extends StatefulWidget {
  const _AnimatedRefreshButton({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  State<_AnimatedRefreshButton> createState() => _AnimatedRefreshButtonState();
}

class _AnimatedRefreshButtonState extends State<_AnimatedRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  bool refreshing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    controller.repeat();
    try {
      await widget.onRefresh();
      await Future<void>.delayed(const Duration(milliseconds: 350));
    } finally {
      controller.stop();
      controller.reset();
      if (mounted) setState(() => refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: refreshing ? null : _refresh,
        icon: RotationTransition(
          key: const Key('elder-refresh-spinner'),
          turns: controller,
          child: const Icon(Icons.refresh_rounded),
        ),
        label: Text(refreshing ? '正在刷新' : '刷新看看'),
      );
}

_TaskPresentation _presentationFor(HealthTask task) => switch (task.kind) {
      TaskKind.medicine => (
          illustration: illustrationForTask(task.kind),
          completeLabel: '我已经吃了',
          skipLabel: '我还没吃',
          completeIcon: Icons.check_rounded,
          metric: null,
        ),
      TaskKind.bloodPressure => (
          illustration: illustrationForTask(task.kind),
          completeLabel: '去记录血压',
          skipLabel: '稍后再测',
          completeIcon: Icons.monitor_heart_outlined,
          metric: HealthMetric.bloodPressure,
        ),
      TaskKind.bloodGlucose => (
          illustration: illustrationForTask(task.kind),
          completeLabel: '去记录血糖',
          skipLabel: '稍后再测',
          completeIcon: Icons.bloodtype_outlined,
          metric: HealthMetric.bloodGlucose,
        ),
      TaskKind.mood => (
          illustration: illustrationForTask(task.kind),
          completeLabel: '去记录心情',
          skipLabel: '稍后记录',
          completeIcon: Icons.mood_rounded,
          metric: HealthMetric.mood,
        ),
      TaskKind.weight => (
          illustration: illustrationForTask(task.kind),
          completeLabel: '去记录体重',
          skipLabel: '稍后再测',
          completeIcon: Icons.monitor_weight_outlined,
          metric: HealthMetric.weight,
        ),
      TaskKind.walk => (
          illustration: illustrationForTask(task.kind),
          completeLabel: '我完成散步了',
          skipLabel: '今天不散步',
          completeIcon: Icons.directions_walk_rounded,
          metric: null,
        ),
      TaskKind.custom => (
          illustration: illustrationForTask(task.kind),
          completeLabel: '我已经完成了',
          skipLabel: '今天先不做',
          completeIcon: Icons.check_rounded,
          metric: null,
        ),
    };

Future<void> _completeTask(
  BuildContext context,
  FubaoRepository repository,
  HealthTask task,
  _TaskPresentation presentation,
) async {
  final metric = presentation.metric;
  if (metric != null) {
    await showHealthRecordDialog(context, repository, metric, elder: true);
    return;
  }
  await repository.setTaskCompleted(task.id, true);
}

List<HealthTask> _orderedTasks(List<HealthTask> tasks) =>
    [...tasks]..sort((a, b) {
        final byTime = _taskMinutes(a).compareTo(_taskMinutes(b));
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });

HealthTask? _firstPendingTask(List<HealthTask> tasks) {
  if (tasks.isEmpty) return null;
  return tasks[_firstPendingIndex(tasks)];
}

int _firstPendingIndex(List<HealthTask> tasks) {
  final index = tasks.indexWhere((task) => !task.isCompleted);
  if (index >= 0) return index;
  return tasks.isEmpty ? 0 : tasks.length - 1;
}

int _taskMinutes(HealthTask task) {
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(task.timeLabel);
  if (match == null) return 24 * 60;
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if ((task.timeLabel.contains('下午') || task.timeLabel.contains('晚上')) &&
      hour < 12) {
    hour += 12;
  }
  if (task.timeLabel.contains('凌晨') && hour == 12) hour = 0;
  return hour * 60 + minute;
}

class _LargeTaskButton extends StatelessWidget {
  const _LargeTaskButton(
      {required this.label,
      required this.icon,
      required this.color,
      this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: color,
        elevation: 4,
        shadowColor: color.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 88,
            child: Row(children: [
              const SizedBox(width: 22),
              CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.white,
                  child: Icon(icon, color: color, size: 36)),
              const SizedBox(width: 20),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w900))),
            ]),
          ),
        ),
      );
}
