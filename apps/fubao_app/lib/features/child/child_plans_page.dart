import 'package:flutter/material.dart';

import '../../data/fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../design/fubao_illustrations.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';
import '../plans/task_history_page.dart';
import 'create_plan_page.dart';
import 'plan_detail_page.dart';

class ChildPlansPage extends StatefulWidget {
  const ChildPlansPage({required this.repository, super.key});
  final FubaoRepository repository;

  @override
  State<ChildPlansPage> createState() => _ChildPlansPageState();
}

class _ChildPlansPageState extends State<ChildPlansPage> {
  int weekCompleted = 9;
  int weekTotal = 12;
  int monthCompleted = 27;
  int monthTotal = 36;
  Set<int> completedWeekdays = {1, 2, 3, 4, 5};

  FubaoRepository get repository => widget.repository;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            const CenteredPageHeader(
              title: '计划',
              trailing: SparkBadge(compact: true),
            ),
            const SizedBox(height: 18),
            _WeekCard(
              completed: weekCompleted,
              total: weekTotal,
              completedWeekdays: completedWeekdays,
              onTap: () => _openHistory(context),
            ),
            const SizedBox(height: 12),
            _MonthCard(
              completed: monthCompleted,
              total: monthTotal,
              onTap: () => _openHistory(context),
            ),
            const SizedBox(height: 18),
            const Text('正在进行的计划',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            for (var i = 0; i < repository.plans.length; i++) ...[
              _PlanCard(
                  plan: repository.plans[i], index: i, repository: repository),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 2),
            OutlinedButton.icon(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                      builder: (_) => CreatePlanPage(repository: repository)),
                );
                if (created == true) {
                  await repository.refresh();
                  await _loadProgress();
                }
              },
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('添加计划'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: FubaoColors.mintStrong,
                side: const BorderSide(color: FubaoColors.mintStrong),
                textStyle: const TextStyle(
                  fontFamily: 'NotoSansSC',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
              ),
            ),
          ],
        ),
      );

  void _openHistory(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TaskHistoryPage(repository: repository),
        ),
      );

  Future<void> _loadProgress() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    try {
      final tasks = await repository.taskHistory(monthStart, now);
      final dated = tasks.where((task) => task.scheduledDate != null).toList();
      if (dated.isEmpty || !mounted) return;
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final weekly =
          dated.where((task) => !task.scheduledDate!.isBefore(weekStart));
      setState(() {
        monthTotal = dated.length;
        monthCompleted = dated.where((task) => task.isCompleted).length;
        weekTotal = weekly.length;
        weekCompleted = weekly.where((task) => task.isCompleted).length;
        completedWeekdays = weekly
            .where((task) => task.isCompleted)
            .map((task) => task.scheduledDate!.weekday)
            .toSet();
      });
    } catch (_) {
      // Keep the last known summary; task history remains available on retry.
    }
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.completed,
    required this.total,
    required this.completedWeekdays,
    required this.onTap,
  });
  final int completed;
  final int total;
  final Set<int> completedWeekdays;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FubaoCard(
        onTap: onTap,
        borderColor: const Color(0xFFF4E5D8),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本周完成情况',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            _WeekStrip(completedWeekdays: completedWeekdays),
            const Divider(height: 28, color: FubaoColors.borderMint),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(
                          text: '本周已完成  ', style: TextStyle(fontSize: 14)),
                      TextSpan(
                          text: '$completed',
                          style: const TextStyle(
                              color: FubaoColors.mintStrong,
                              fontSize: 25,
                              fontWeight: FontWeight.w900)),
                      TextSpan(
                          text: '/$total 项',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
                const FubaoIllustrationAsset(FubaoIllustration.planClipboard,
                    width: 135, height: 92),
              ],
            ),
          ],
        ),
      );
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.completedWeekdays});
  final Set<int> completedWeekdays;
  @override
  Widget build(BuildContext context) {
    const labels = ['一', '二', '三', '四', '五', '六', '日', '今'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < labels.length; i++)
          Column(
            children: [
              Text(labels[i],
                  style: TextStyle(
                      color:
                          i == 7 ? FubaoColors.orangeStrong : FubaoColors.ink)),
              const SizedBox(height: 10),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: i < 7 && completedWeekdays.contains(i + 1)
                      ? FubaoColors.mintStrong
                      : i == 7
                          ? FubaoColors.orangeStrong
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: i < 7 && !completedWeekdays.contains(i + 1)
                      ? Border.all(color: const Color(0xFFC9C9C9), width: 1.5)
                      : null,
                ),
                child: i < 7 && completedWeekdays.contains(i + 1) || i == 7
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                    : null,
              ),
            ],
          ),
      ],
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.completed,
    required this.total,
    required this.onTap,
  });
  final int completed;
  final int total;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return FubaoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('本月进度',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text.rich(TextSpan(children: [
                  const TextSpan(
                      text: '本月已完成  ', style: TextStyle(fontSize: 15)),
                  TextSpan(
                      text: '$completed',
                      style: const TextStyle(
                          color: FubaoColors.mintStrong,
                          fontSize: 25,
                          fontWeight: FontWeight.w900)),
                  TextSpan(
                      text: '/$total 项', style: const TextStyle(fontSize: 18)),
                ])),
                const SizedBox(height: 8),
                const Text('继续保持，轻松达成目标！',
                    style:
                        TextStyle(color: FubaoColors.inkMuted, fontSize: 13)),
              ],
            ),
          ),
          FubaoProgressRing(
            value: progress.clamp(0, 1),
            label: '${(progress * 100).round()}%',
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard(
      {required this.plan, required this.index, required this.repository});
  final HealthPlan plan;
  final int index;
  final FubaoRepository repository;
  @override
  Widget build(BuildContext context) => FubaoCard(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => PlanDetailPage(repository: repository, plan: plan),
        )),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            FubaoIllustrationBubble(
              illustration: index == 0
                  ? FubaoIllustration.bloodPressureDevice
                  : FubaoIllustration.walkingPerson,
              size: 78,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(
                      '● ${_statusLabel(plan.status)} · 今日 ${plan.completed}/${plan.total} 已完成',
                      style: const TextStyle(
                          color: FubaoColors.inkMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(plan.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: FubaoColors.inkMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: FubaoColors.inkMuted, size: 28),
          ],
        ),
      );
}

String _statusLabel(String status) => switch (status) {
      'paused' => '已暂停',
      'ended' => '已结束',
      _ => '进行中',
    };
