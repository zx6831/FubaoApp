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
            final task = _primaryTask(repository.tasks);
            final presentation = task == null ? null : _presentationFor(task);
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
                if (task == null)
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
                  FubaoCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('今天要做的事',
                              style: TextStyle(
                                  fontSize: 29, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 18),
                          Row(children: [
                            FubaoIllustrationBubble(
                              illustration: presentation!.illustration,
                              size: 120,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(task.title,
                                      style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900)),
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
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            task.timeLabel,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              fontSize: 23,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ])),
                          ]),
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
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '已记录“${presentation.skipLabel}”，家人会看到这个状态',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ] else
                            _LargeTaskButton(
                              label: '已完成',
                              icon: Icons.check_circle_rounded,
                              color: FubaoColors.mintStrong,
                            ),
                        ]),
                  ),
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
          illustration: FubaoIllustration.pill,
          completeLabel: '我已经吃了',
          skipLabel: '我还没吃',
          completeIcon: Icons.check_rounded,
          metric: null,
        ),
      TaskKind.bloodPressure => (
          illustration: FubaoIllustration.elderBloodPressureDevice,
          completeLabel: '去记录血压',
          skipLabel: '稍后再测',
          completeIcon: Icons.monitor_heart_outlined,
          metric: HealthMetric.bloodPressure,
        ),
      TaskKind.bloodGlucose => (
          illustration: FubaoIllustration.planClipboard,
          completeLabel: '去记录血糖',
          skipLabel: '稍后再测',
          completeIcon: Icons.bloodtype_outlined,
          metric: HealthMetric.bloodGlucose,
        ),
      TaskKind.mood => (
          illustration: FubaoIllustration.elderMood,
          completeLabel: '去记录心情',
          skipLabel: '稍后记录',
          completeIcon: Icons.mood_rounded,
          metric: HealthMetric.mood,
        ),
      TaskKind.weight => (
          illustration: FubaoIllustration.planClipboard,
          completeLabel: '去记录体重',
          skipLabel: '稍后再测',
          completeIcon: Icons.monitor_weight_outlined,
          metric: HealthMetric.weight,
        ),
      TaskKind.walk => (
          illustration: FubaoIllustration.elderPark,
          completeLabel: '我完成散步了',
          skipLabel: '今天不散步',
          completeIcon: Icons.directions_walk_rounded,
          metric: null,
        ),
      TaskKind.custom => (
          illustration: FubaoIllustration.planClipboard,
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

HealthTask? _primaryTask(List<HealthTask> tasks) {
  if (tasks.isEmpty) return null;
  for (final task in tasks) {
    if (task.kind == TaskKind.medicine) return task;
  }
  return tasks.first;
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
