import 'package:flutter/material.dart';

import '../../data/demo_fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../widgets/fubao_widgets.dart';

class ElderTopicsPage extends StatelessWidget {
  const ElderTopicsPage({required this.repository, super.key});

  final DemoFubaoRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: repository,
        builder: (context, _) {
          final allDone = repository.tasks.every((task) => task.isCompleted);
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Text('今天聊什么',
                          style: TextStyle(
                              fontSize: 39, fontWeight: FontWeight.w900))),
                  ReadAloudButton(text: '今天聊什么。说说今天开心的事，或者散步时看到的风景。'),
                ],
              ),
              const EmptySpacer(height: 28),
              if (allDone) ...[
                const _UnlockedHero(),
                const EmptySpacer(height: 16),
                for (final topic in repository.topics) ...[
                  FubaoCard(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        FubaoIconBubble(
                            icon: topic.icon,
                            color: FubaoColors.orangeStrong,
                            size: 82),
                        const SizedBox(width: 18),
                        Expanded(
                            child: Text(
                                topic.id == 'task-done'
                                    ? '今天有什么开心的事？'
                                    : '下午散步时看到什么？',
                                style: const TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w900))),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 36, color: FubaoColors.mintStrong),
                      ],
                    ),
                  ),
                  const EmptySpacer(height: 14),
                ],
              ] else
                _LockedTopics(
                    completed: repository.completedTaskCount,
                    total: repository.tasks.length),
            ],
          );
        },
      ),
    );
  }
}

class _UnlockedHero extends StatelessWidget {
  const _UnlockedHero();
  @override
  Widget build(BuildContext context) => FubaoCard(
        color: FubaoColors.mintSoft,
        padding: const EdgeInsets.all(26),
        child: Row(
          children: [
            const FubaoIconBubble(
                icon: Icons.celebration_rounded,
                color: FubaoColors.mintStrong,
                size: 86),
            const SizedBox(width: 18),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('今天的任务都完成啦！',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: FubaoColors.mintStrong)),
                  const SizedBox(height: 8),
                  const Text('看看家人给你的暖心话题', style: TextStyle(fontSize: 20))
                ])),
          ],
        ),
      );
}

class _LockedTopics extends StatelessWidget {
  const _LockedTopics({required this.completed, required this.total});
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) => FubaoCard(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 38),
        child: Column(
          children: [
            const FubaoIconBubble(
                icon: Icons.lock_rounded,
                color: FubaoColors.orangeStrong,
                size: 92),
            const SizedBox(height: 22),
            const Text('完成今天的任务后查看',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text('已经完成 $completed / $total 项',
                style:
                    const TextStyle(fontSize: 22, color: FubaoColors.inkMuted)),
            const SizedBox(height: 20),
            LinearProgressIndicator(
                value: total == 0 ? 0 : completed / total,
                minHeight: 12,
                borderRadius: BorderRadius.circular(999),
                color: FubaoColors.mintStrong,
                backgroundColor: FubaoColors.divider),
          ],
        ),
      );
}
