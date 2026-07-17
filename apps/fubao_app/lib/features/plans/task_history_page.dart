import 'package:flutter/material.dart';

import '../../data/fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';

class TaskHistoryPage extends StatefulWidget {
  const TaskHistoryPage({
    required this.repository,
    this.elder = false,
    super.key,
  });

  final FubaoRepository repository;
  final bool elder;

  @override
  State<TaskHistoryPage> createState() => _TaskHistoryPageState();
}

class _TaskHistoryPageState extends State<TaskHistoryPage> {
  late DateTime selectedDate = _dateOnly(DateTime.now());
  List<HealthTask> tasks = const [];
  List<HealthTask> monthTasks = const [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final weekStart =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final completed = tasks.where((task) => task.isCompleted).length;
    final monthCompleted = monthTasks.where((task) => task.isCompleted).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.elder ? '任务记录' : '健康任务记录',
            style: TextStyle(
                fontSize: widget.elder ? 25 : 21, fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: FubaoColors.canvas,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
                widget.elder ? 20 : 18, 8, widget.elder ? 20 : 18, 28),
            children: [
              FubaoCard(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${selectedDate.year} 年 ${selectedDate.month} 月',
                          style: TextStyle(
                              fontSize: widget.elder ? 21 : 18,
                              fontWeight: FontWeight.w900)),
                      TextButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('打开月历'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var index = 0; index < 7; index++)
                        _DateChip(
                          date: weekStart.add(Duration(days: index)),
                          selectedDate: selectedDate,
                          elder: widget.elder,
                          onTap: _selectDate,
                        ),
                    ],
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              FubaoCard(
                color: const Color(0xFFF1FAF6),
                borderColor: FubaoColors.borderMint,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(children: [
                  Expanded(
                      child: _SummaryValue(
                    label: '当天完成',
                    value: '$completed/${tasks.length}',
                    elder: widget.elder,
                  )),
                  Container(
                      width: 1, height: 46, color: FubaoColors.borderMint),
                  Expanded(
                      child: _SummaryValue(
                    label: '本月完成',
                    value: '$monthCompleted/${monthTasks.length}',
                    elder: widget.elder,
                  )),
                ]),
              ),
              SizedBox(height: widget.elder ? 22 : 16),
              Text(_dateTitle(selectedDate),
                  style: TextStyle(
                      fontSize: widget.elder ? 27 : 21,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error != null)
                _MessageCard(
                  icon: Icons.cloud_off_rounded,
                  text: error!,
                  action: _load,
                  elder: widget.elder,
                )
              else if (tasks.isEmpty)
                _MessageCard(
                  icon: Icons.event_available_rounded,
                  text: '这一天没有安排任务',
                  elder: widget.elder,
                )
              else
                for (var index = 0; index < tasks.length; index++) ...[
                  _HistoryTaskCard(task: tasks[index], elder: widget.elder),
                  if (index != tasks.length - 1) const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final monthStart = DateTime(selectedDate.year, selectedDate.month);
    final monthEnd = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    try {
      final results = await Future.wait([
        widget.repository.tasksForDate(selectedDate),
        widget.repository.taskHistory(monthStart, monthEnd),
      ]);
      if (!mounted) return;
      setState(() {
        tasks = results[0];
        monthTasks = results[1];
        loading = false;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        error = '记录加载失败：$exception';
        loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: '选择要查看的日期',
      cancelText: '取消',
      confirmText: '查看',
    );
    if (date != null) await _selectDate(date);
  }

  Future<void> _selectDate(DateTime date) async {
    selectedDate = _dateOnly(date);
    await _load();
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dateTitle(DateTime value) {
    final today = _dateOnly(DateTime.now());
    if (value == today) return '今天的任务';
    return '${value.month} 月 ${value.day} 日的任务';
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selectedDate,
    required this.elder,
    required this.onTap,
  });
  final DateTime date;
  final DateTime selectedDate;
  final bool elder;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = date == selectedDate;
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return InkWell(
      onTap: () => onTap(date),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: elder ? 42 : 38,
        constraints: BoxConstraints(minHeight: elder ? 64 : 56),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: selected ? FubaoColors.mintStrong : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(weekdays[date.weekday - 1],
              style: TextStyle(
                  color: selected ? Colors.white : FubaoColors.inkMuted,
                  fontSize: elder ? 16 : 13)),
          const SizedBox(height: 4),
          Text('${date.day}',
              style: TextStyle(
                  color: selected ? Colors.white : FubaoColors.ink,
                  fontSize: elder ? 19 : 16,
                  fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue(
      {required this.label, required this.value, required this.elder});
  final String label;
  final String value;
  final bool elder;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label,
            style: TextStyle(
                color: FubaoColors.inkMuted, fontSize: elder ? 17 : 13)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: FubaoColors.mintStrong,
                fontSize: elder ? 27 : 23,
                fontWeight: FontWeight.w900)),
      ]);
}

class _HistoryTaskCard extends StatelessWidget {
  const _HistoryTaskCard({required this.task, required this.elder});
  final HealthTask task;
  final bool elder;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = task.isCompleted
        ? ('已完成', FubaoColors.mintStrong, Icons.check_circle_rounded)
        : task.isSkipped
            ? (
                '今天没做',
                FubaoColors.orangeStrong,
                Icons.remove_circle_outline_rounded
              )
            : ('待完成', FubaoColors.inkMuted, Icons.schedule_rounded);
    return FubaoCard(
      padding: EdgeInsets.all(elder ? 18 : 14),
      child: Row(children: [
        CircleAvatar(
          radius: elder ? 31 : 25,
          backgroundColor: color.withValues(alpha: .12),
          child:
              Icon(iconForTask(task.kind), color: color, size: elder ? 32 : 26),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title,
                style: TextStyle(
                    fontSize: elder ? 22 : 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(task.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: FubaoColors.inkMuted, fontSize: elder ? 16 : 12)),
          ],
        )),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: elder ? 17 : 13)),
          const SizedBox(height: 4),
          Text(task.timeLabel,
              style:
                  const TextStyle(color: FubaoColors.inkMuted, fontSize: 11)),
        ]),
      ]),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard(
      {required this.icon,
      required this.text,
      this.action,
      required this.elder});
  final IconData icon;
  final String text;
  final Future<void> Function()? action;
  final bool elder;

  @override
  Widget build(BuildContext context) => FubaoCard(
        padding: const EdgeInsets.all(28),
        child: Column(children: [
          Icon(icon, size: 52, color: FubaoColors.mintStrong),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: elder ? 21 : 16, fontWeight: FontWeight.w700)),
          if (action != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: action,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重新加载')),
          ],
        ]),
      );
}
