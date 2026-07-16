import 'package:flutter/material.dart';

import '../../data/demo_fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../widgets/fubao_widgets.dart';

class ChildHomePage extends StatelessWidget {
  const ChildHomePage({required this.repository, super.key});

  final DemoFubaoRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: repository,
        builder: (context, _) {
          final completed = repository.completedTaskCount;
          final total = repository.tasks.length;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                sliver: SliverList.list(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BrandMark(),
                        _AlertButton(),
                      ],
                    ),
                    const EmptySpacer(height: 24),
                    const _SparkHero(),
                    const EmptySpacer(height: 16),
                    _TaskProgress(completed: completed, total: total),
                    const EmptySpacer(height: 16),
                    const Row(
                      children: [
                        Expanded(child: _HealthMetricCard()),
                        SizedBox(width: 12),
                        Expanded(child: _MoodCard()),
                      ],
                    ),
                    const EmptySpacer(height: 28),
                    const SectionTitle('聊一聊，会更好'),
                    const EmptySpacer(height: 14),
                    for (final topic in repository.topics) ...[
                      FubaoCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            FubaoIconBubble(
                              icon: topic.icon,
                              color: FubaoColors.orangeStrong,
                              size: 56,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(topic.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 4),
                                  Text(topic.suggestedWords,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                      const EmptySpacer(height: 12),
                    ],
                    const SafetyNote(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AlertButton extends StatelessWidget {
  const _AlertButton();

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目前没有需要处理的提醒')),
      ),
      icon:
          const Badge(smallSize: 8, child: Icon(Icons.favorite_border_rounded)),
    );
  }
}

class _SparkHero extends StatelessWidget {
  const _SparkHero();

  @override
  Widget build(BuildContext context) {
    return FubaoCard(
      color: FubaoColors.mintSoft,
      borderColor: FubaoColors.mint.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white,
                  FubaoColors.mint.withValues(alpha: 0.22)
                ],
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 44, color: FubaoColors.mintStrong),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('12',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: FubaoColors.mintStrong, fontSize: 50)),
                Text('已连续互动 12 天',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('每天一点点，一起更健康',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskProgress extends StatelessWidget {
  const _TaskProgress({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return FubaoCard(
      child: Row(
        children: [
          const FubaoIconBubble(
              icon: Icons.fact_check_rounded,
              color: FubaoColors.mintStrong,
              size: 66),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日任务进度', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('$completed / $total 已完成'),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  color: FubaoColors.mintStrong,
                  backgroundColor: FubaoColors.divider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthMetricCard extends StatelessWidget {
  const _HealthMetricCard();

  @override
  Widget build(BuildContext context) {
    return const FubaoCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('血压', style: TextStyle(fontWeight: FontWeight.w800)),
            Chip(label: Text('稳定'))
          ]),
          SizedBox(height: 14),
          Text('128/82',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: FubaoColors.mintStrong)),
          Text('mmHg · 今天 08:30'),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard();

  @override
  Widget build(BuildContext context) {
    return const FubaoCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今日心情', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Icon(Icons.sentiment_very_satisfied_rounded,
              size: 48, color: FubaoColors.orangeStrong),
          SizedBox(height: 4),
          Text('愉快 · 谢谢分享'),
        ],
      ),
    );
  }
}
