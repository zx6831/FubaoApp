import 'package:flutter/material.dart';

import '../../data/demo_fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../design/fubao_illustrations.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';

class ElderPlansPage extends StatelessWidget {
  const ElderPlansPage({required this.repository, super.key});
  final DemoFubaoRepository repository;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: repository,
          builder: (context, _) {
            final medicine =
                repository.tasks.firstWhere((task) => task.id == 'medicine');
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
              children: [
                const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Text('我的计划',
                              style: TextStyle(
                                  fontSize: 39, fontWeight: FontWeight.w900))),
                      ReadAloudButton(text: '我的计划。今天有吃药、散步和记录心情。'),
                    ]),
                const SizedBox(height: 22),
                const _ElderWeekStrip(),
                const SizedBox(height: 22),
                const Text('今天的任务',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                _ElderTaskCard(
                  task: medicine,
                  illustration: FubaoIllustration.pill,
                  completed: medicine.isCompleted,
                  onTap: () => repository.setTaskCompleted('medicine', true),
                ),
                const SizedBox(height: 22),
                const Text('接下来的事',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                _ElderTaskCard(
                  task:
                      repository.tasks.firstWhere((task) => task.id == 'walk'),
                  illustration: FubaoIllustration.elderPark,
                  onTap: () => repository.setTaskCompleted('walk', true),
                ),
                const SizedBox(height: 12),
                _ElderTaskCard(
                  task:
                      repository.tasks.firstWhere((task) => task.id == 'mood'),
                  illustration: FubaoIllustration.elderMood,
                  completed: repository.tasks
                      .firstWhere((task) => task.id == 'mood')
                      .isCompleted,
                  onTap: () => repository.setTaskCompleted('mood', true),
                ),
              ],
            );
          },
        ),
      );
}

class _ElderWeekStrip extends StatelessWidget {
  const _ElderWeekStrip();
  @override
  Widget build(BuildContext context) {
    const labels = ['一', '二', '今', '四', '五', '六', '日'];
    return FubaoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (var i = 0; i < labels.length; i++)
          Container(
            padding: i == 2
                ? const EdgeInsets.symmetric(horizontal: 9, vertical: 7)
                : EdgeInsets.zero,
            decoration: i == 2
                ? BoxDecoration(
                    color: const Color(0xFFF0FAF6),
                    border: Border.all(color: FubaoColors.mint),
                    borderRadius: BorderRadius.circular(22))
                : null,
            child: Column(children: [
              Text(labels[i],
                  style: TextStyle(
                      color: i == 2 ? FubaoColors.mintStrong : FubaoColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: i < 2
                        ? FubaoColors.mintStrong
                        : i == 2
                            ? FubaoColors.mint
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: i > 2
                        ? Border.all(color: const Color(0xFFBBBBBB), width: 1.5)
                        : null),
                child: i < 2
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 20)
                    : null,
              ),
            ]),
          ),
      ]),
    );
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
