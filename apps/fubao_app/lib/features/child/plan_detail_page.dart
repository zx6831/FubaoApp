import 'package:flutter/material.dart';

import '../../data/fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';

class PlanDetailPage extends StatefulWidget {
  const PlanDetailPage({
    required this.repository,
    required this.plan,
    super.key,
  });

  final FubaoRepository repository;
  final HealthPlan plan;

  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage> {
  late String status = widget.plan.status;
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    final task = _todayTask;
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('计划详情', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: FubaoColors.canvas,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            FubaoCard(
              borderColor: FubaoColors.borderMint,
              child: Column(children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: const Color(0xFFEAF8F2),
                  child: Icon(widget.plan.icon,
                      size: 42, color: FubaoColors.mintStrong),
                ),
                const SizedBox(height: 12),
                Text(widget.plan.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(widget.plan.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: FubaoColors.inkMuted)),
                const SizedBox(height: 12),
                _StatusBadge(status: status),
              ]),
            ),
            const SizedBox(height: 14),
            FubaoCard(
              child: Column(children: [
                _DetailRow(
                    icon: Icons.schedule_rounded,
                    title: '提醒时间',
                    value: widget.plan.reminderTime),
                const Divider(),
                _DetailRow(
                    icon: Icons.calendar_month_rounded,
                    title: '每周执行',
                    value: _daysLabel(widget.plan.daysOfWeek)),
                const Divider(),
                _DetailRow(
                    icon: Icons.today_rounded,
                    title: '今日进度',
                    value: task == null
                        ? '今天不执行'
                        : task.isCompleted
                            ? '已完成'
                            : task.isSkipped
                                ? '今天没做'
                                : '待完成'),
              ]),
            ),
            if (task?.isSkipped == true) ...[
              const SizedBox(height: 10),
              const FubaoCard(
                color: FubaoColors.orangeSoft,
                borderColor: FubaoColors.orangeStrong,
                child: Row(children: [
                  Icon(Icons.schedule_rounded, color: FubaoColors.orangeStrong),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          '\u957f\u8f88\u5df2\u9009\u62e9\u7a0d\u540e\u5b8c\u6210\u8fd9\u9879\u4efb\u52a1')),
                ]),
              ),
            ],
            const SizedBox(height: 18),
            if (task != null && !task.isCompleted && status == 'active') ...[
              FilledButton.icon(
                onPressed: busy ? null : () => _remind(task),
                icon: const Icon(Icons.campaign_rounded),
                label: const Text('提醒长辈现在完成'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: FubaoColors.mintStrong,
                  textStyle: const TextStyle(
                      fontFamily: 'NotoSansSC',
                      fontSize: 17,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (status == 'active')
              OutlinedButton.icon(
                onPressed: busy ? null : () => _setStatus('paused'),
                icon: const Icon(Icons.pause_circle_outline_rounded),
                label: const Text('暂停计划'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
              )
            else if (status == 'paused')
              FilledButton.icon(
                onPressed: busy ? null : () => _setStatus('active'),
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('恢复计划'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: FubaoColors.mintStrong),
              ),
            if (status != 'ended') ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: busy ? null : _confirmEnd,
                style: TextButton.styleFrom(
                    foregroundColor: FubaoColors.orangeStrong,
                    minimumSize: const Size.fromHeight(48)),
                child: const Text('结束计划（保留历史记录）'),
              ),
            ],
            if (busy) ...[
              const SizedBox(height: 10),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  HealthTask? get _todayTask {
    for (final task in widget.repository.tasks) {
      if (task.planId == widget.plan.id) return task;
    }
    return null;
  }

  Future<void> _remind(HealthTask task) async {
    setState(() => busy = true);
    try {
      final accepted = await widget.repository.remindTask(task.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(accepted ? '提醒已发送到家庭设备' : '设备当前离线，提醒已记录'),
      ));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('提醒失败：$error')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _setStatus(String value) async {
    setState(() => busy = true);
    try {
      await widget.repository.updatePlanStatus(widget.plan.id, value);
      if (!mounted) return;
      setState(() => status = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(value == 'active'
                ? '计划已恢复'
                : value == 'paused'
                    ? '计划已暂停'
                    : '计划已结束')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('操作失败：$error')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _confirmEnd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('结束这个计划？'),
        content: const Text('结束后不会再生成新任务，已有任务和健康记录会继续保留。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认结束')),
        ],
      ),
    );
    if (confirmed == true) await _setStatus('ended');
  }

  String _daysLabel(List<int> days) {
    if (days.length == 7) return '每天';
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    final sorted = [...days]..sort();
    return '周${sorted.map((day) => labels[day - 1]).join('、')}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: FubaoColors.mintStrong),
        title: Text(title),
        trailing:
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'paused' => ('已暂停', FubaoColors.orangeStrong),
      'ended' => ('已结束', FubaoColors.inkMuted),
      _ => ('进行中', FubaoColors.mintStrong),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(18)),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w800)),
    );
  }
}
