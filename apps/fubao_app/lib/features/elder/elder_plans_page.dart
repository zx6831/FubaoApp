import 'package:flutter/material.dart';

import '../../data/demo_fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';

class ElderPlansPage extends StatelessWidget {
  const ElderPlansPage({required this.repository, super.key});

  final DemoFubaoRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: repository,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
          children: [
            const Row(
              children: [
                Expanded(
                    child: Text('我的计划',
                        style: TextStyle(
                            fontSize: 39, fontWeight: FontWeight.w900))),
                ReadAloudButton(text: '我的计划。今天有吃药、散步和记录心情。'),
              ],
            ),
            const EmptySpacer(height: 28),
            const _ElderWeekStrip(),
            const EmptySpacer(height: 26),
            SectionTitle('今天的任务', elder: true),
            const EmptySpacer(height: 14),
            for (final task in repository.tasks) ...[
              _ElderTaskRow(
                  task: task,
                  onTap: () =>
                      repository.setTaskCompleted(task.id, !task.isCompleted)),
              const EmptySpacer(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _ElderWeekStrip extends StatelessWidget {
  const _ElderWeekStrip();

  @override
  Widget build(BuildContext context) {
    const days = ['一', '二', '今', '四', '五', '六', '日'];
    return FubaoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var index = 0; index < days.length; index++)
            Column(
              children: [
                Text(days[index],
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: index == 2
                            ? FubaoColors.mintStrong
                            : FubaoColors.ink)),
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 17,
                  backgroundColor: index < 2
                      ? FubaoColors.mintStrong
                      : index == 2
                          ? FubaoColors.mintSoft
                          : FubaoColors.divider,
                  child: index < 2
                      ? const Icon(Icons.check_rounded, color: Colors.white)
                      : index == 2
                          ? const Icon(Icons.circle,
                              size: 18, color: FubaoColors.mintStrong)
                          : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ElderTaskRow extends StatelessWidget {
  const _ElderTaskRow({required this.task, required this.onTap});
  final HealthTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FubaoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          FubaoIconBubble(
              icon: iconForTask(task.kind),
              color: task.isCompleted
                  ? FubaoColors.mintStrong
                  : FubaoColors.orangeStrong,
              size: 74),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: const TextStyle(
                        fontSize: 27, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(task.isCompleted ? '已完成' : task.timeLabel,
                    style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: task.isCompleted
                            ? FubaoColors.mintStrong
                            : FubaoColors.inkMuted)),
              ],
            ),
          ),
          Icon(
              task.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              size: 36,
              color: task.isCompleted
                  ? FubaoColors.mintStrong
                  : FubaoColors.inkMuted),
        ],
      ),
    );
  }
}
