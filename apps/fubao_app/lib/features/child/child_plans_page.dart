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
  int weekCompleted = 0;
  int weekTotal = 0;
  int monthCompleted = 0;
  int monthTotal = 0;
  Set<int> completedWeekdays = {};
  bool loadingProgress = false;

  FubaoRepository get repository => widget.repository;

  @override
  void initState() {
    super.initState();
    repository.addListener(_handleRepositoryChanged);
    _loadProgress();
  }

  @override
  void dispose() {
    repository.removeListener(_handleRepositoryChanged);
    super.dispose();
  }

  void _handleRepositoryChanged() => _loadProgress();

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            CenteredPageHeader(
              title: '计划',
              trailing: SparkBadge(spark: repository.spark, compact: true),
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
            if (repository.plans.isEmpty)
              const FubaoCard(
                padding: EdgeInsets.all(22),
                child: Column(children: [
                  Icon(Icons.playlist_add_rounded,
                      size: 42, color: FubaoColors.mintStrong),
                  SizedBox(height: 10),
                  Text('还没有正在进行的计划',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  SizedBox(height: 6),
                  Text('添加第一个健康计划后，任务会从执行日期开始生成',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: FubaoColors.inkMuted)),
                ]),
              )
            else
              for (var i = 0; i < repository.plans.length; i++) ...[
                _PlanCard(plan: repository.plans[i], repository: repository),
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
    if (loadingProgress) return;
    loadingProgress = true;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    try {
      final tasks = await repository.taskHistory(monthStart, now);
      final dated = tasks.where((task) => task.scheduledDate != null).toList();
      if (!mounted) return;
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final weekly =
          dated.where((task) => !task.scheduledDate!.isBefore(weekStart));
      final completedDays = <int>{};
      for (var weekday = 1; weekday <= 7; weekday++) {
        final dayTasks = weekly
            .where((task) => task.scheduledDate!.weekday == weekday)
            .toList();
        if (dayTasks.isNotEmpty && dayTasks.every((task) => task.isCompleted)) {
          completedDays.add(weekday);
        }
      }
      setState(() {
        monthTotal = dated.length;
        monthCompleted = dated.where((task) => task.isCompleted).length;
        weekTotal = weekly.length;
        weekCompleted = weekly.where((task) => task.isCompleted).length;
        completedWeekdays = completedDays;
      });
    } catch (_) {
      // Keep the last known summary; task history remains available on retry.
    } finally {
      loadingProgress = false;
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
                  child: total == 0
                      ? const Text(
                          '本周还没有任务',
                          style: TextStyle(
                            color: FubaoColors.inkMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Text.rich(
                          TextSpan(children: [
                            const TextSpan(
                                text: '本周已完成  ',
                                style: TextStyle(fontSize: 14)),
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
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    final today = DateTime.now().weekday;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < labels.length; i++)
          Column(
            children: [
              Text(i + 1 == today ? '今' : labels[i],
                  style: TextStyle(
                      color: i + 1 == today
                          ? FubaoColors.orangeStrong
                          : FubaoColors.ink)),
              const SizedBox(height: 10),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: completedWeekdays.contains(i + 1)
                      ? FubaoColors.mintStrong
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: !completedWeekdays.contains(i + 1)
                      ? Border.all(
                          color: i + 1 == today
                              ? FubaoColors.orangeStrong
                              : const Color(0xFFC9C9C9),
                          width: 1.5)
                      : null,
                ),
                child: completedWeekdays.contains(i + 1)
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
                if (total == 0)
                  const Text('本月还没有任务',
                      style: TextStyle(
                          color: FubaoColors.inkMuted,
                          fontWeight: FontWeight.w700))
                else
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
                        text: '/$total 项',
                        style: const TextStyle(fontSize: 18)),
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
  const _PlanCard({required this.plan, required this.repository});
  final HealthPlan plan;
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
              key: Key('child-plan-illustration-${plan.kind.name}'),
              illustration: illustrationForTask(plan.kind),
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
