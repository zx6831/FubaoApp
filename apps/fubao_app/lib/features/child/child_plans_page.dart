import 'package:flutter/material.dart';

import '../../data/demo_fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../widgets/fubao_widgets.dart';
import 'create_plan_page.dart';

class ChildPlansPage extends StatelessWidget {
  const ChildPlansPage({required this.repository, super.key});

  final DemoFubaoRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 80),
              Text('计划',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
              SparkBadge(compact: true),
            ],
          ),
          const EmptySpacer(height: 22),
          const _WeeklyProgress(),
          const EmptySpacer(height: 14),
          const _MonthlyProgress(),
          const EmptySpacer(height: 28),
          const SectionTitle('正在进行的计划'),
          const EmptySpacer(height: 14),
          for (final plan in repository.plans) ...[
            FubaoCard(
              child: Row(
                children: [
                  FubaoIconBubble(
                      icon: plan.icon, color: FubaoColors.mintStrong, size: 62),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.title,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 5),
                        Text('进行中 · 今日 ${plan.completed}/${plan.total} 已完成'),
                        const SizedBox(height: 4),
                        Text(plan.description,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 30),
                ],
              ),
            ),
            const EmptySpacer(height: 12),
          ],
          const EmptySpacer(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              side: const BorderSide(color: FubaoColors.mintStrong),
              foregroundColor: FubaoColors.mintStrong,
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CreatePlanPage()),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('添加计划'),
          ),
        ],
      ),
    );
  }
}

class _WeeklyProgress extends StatelessWidget {
  const _WeeklyProgress();

  @override
  Widget build(BuildContext context) {
    const days = ['一', '二', '三', '四', '五', '六', '日'];
    return FubaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本周完成情况', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var index = 0; index < days.length; index++)
                Column(
                  children: [
                    Text(index == 5 ? '今' : days[index],
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: index < 5
                          ? FubaoColors.mintStrong
                          : index == 5
                              ? FubaoColors.orangeStrong
                              : FubaoColors.divider,
                      child: index <= 5
                          ? const Icon(Icons.check_rounded,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 22),
          const Text.rich(TextSpan(children: [
            TextSpan(text: '本周已完成 '),
            TextSpan(
                text: '9',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: FubaoColors.mintStrong)),
            TextSpan(text: '/12 项')
          ])),
        ],
      ),
    );
  }
}

class _MonthlyProgress extends StatelessWidget {
  const _MonthlyProgress();

  @override
  Widget build(BuildContext context) {
    return FubaoCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('本月进度', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                const Text('本月已完成 27/36 项'),
                const SizedBox(height: 5),
                const Text('继续保持，轻松达成目标！'),
              ],
            ),
          ),
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(
                    value: 0.75,
                    strokeWidth: 9,
                    color: FubaoColors.mintStrong,
                    backgroundColor: FubaoColors.mintSoft),
                Text('75%',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: FubaoColors.mintStrong)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
