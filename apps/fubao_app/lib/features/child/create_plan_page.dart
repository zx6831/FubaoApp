import 'package:flutter/material.dart';

import '../../design/fubao_colors.dart';
import '../../widgets/fubao_widgets.dart';

class CreatePlanPage extends StatefulWidget {
  const CreatePlanPage({super.key});

  @override
  State<CreatePlanPage> createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends State<CreatePlanPage> {
  int _selected = 0;
  int _step = 0;

  static const _options = [
    ('血压管理', '记录血压，规律监测，稳稳守护', Icons.monitor_heart_outlined),
    ('用药提醒', '按时提醒，不漏服，吃药更安心', Icons.medication_rounded),
    ('健康生活习惯', '规律作息，适度运动，生活更健康', Icons.directions_walk_rounded),
    ('自定义计划', '按长辈情况，灵活设置专属计划', Icons.edit_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建健康计划'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            _StepHeader(step: _step),
            const EmptySpacer(height: 22),
            FubaoCard(
              color: FubaoColors.mintSoft,
              child: Row(
                children: [
                  const FubaoIconBubble(
                      icon: Icons.pets_rounded,
                      color: FubaoColors.mintStrong,
                      size: 66),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_step == 0 ? '先选一个最关心的方向' : '再确认一下计划信息',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 5),
                        Text(_step == 0
                            ? '我们将为长辈定制简单易行的每日计划'
                            : '测试版会使用推荐时间，之后可随时调整'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const EmptySpacer(height: 16),
            if (_step == 0)
              for (var index = 0; index < _options.length; index++) ...[
                _PlanOption(
                  title: _options[index].$1,
                  subtitle: _options[index].$2,
                  icon: _options[index].$3,
                  selected: _selected == index,
                  onTap: () => setState(() => _selected = index),
                ),
                const EmptySpacer(height: 12),
              ]
            else
              _PlanConfirmation(option: _options[_selected]),
            const EmptySpacer(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                backgroundColor: FubaoColors.mintStrong,
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              onPressed: () {
                if (_step == 0) {
                  setState(() => _step = 1);
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${_options[_selected].$1}已创建，今日任务已同步')),
                );
                Navigator.of(context).pop();
              },
              child: Text(_step == 0 ? '下一步' : '开始执行'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['选择计划', '填写信息', '开始执行'];
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: index <= step
                      ? FubaoColors.mintStrong
                      : FubaoColors.divider,
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 7),
                Text(labels[index],
                    style: TextStyle(
                        color: index <= step
                            ? FubaoColors.mintStrong
                            : FubaoColors.inkMuted,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (index < labels.length - 1) const SizedBox(width: 2),
        ],
      ],
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.selected,
      required this.onTap});

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FubaoCard(
      onTap: onTap,
      borderColor: selected ? FubaoColors.mintStrong : FubaoColors.divider,
      color: selected ? FubaoColors.mintSoft : FubaoColors.card,
      child: Row(
        children: [
          FubaoIconBubble(
              icon: icon,
              color:
                  selected ? FubaoColors.mintStrong : FubaoColors.orangeStrong,
              size: 62),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(subtitle)
              ])),
          Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: selected ? FubaoColors.mintStrong : FubaoColors.inkMuted),
        ],
      ),
    );
  }
}

class _PlanConfirmation extends StatelessWidget {
  const _PlanConfirmation({required this.option});

  final (String, String, IconData) option;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FubaoCard(
          child: Row(children: [
            FubaoIconBubble(
                icon: option.$3, color: FubaoColors.mintStrong, size: 68),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(option.$1,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 5),
                  Text(option.$2)
                ]))
          ]),
        ),
        const EmptySpacer(height: 12),
        const FubaoCard(
          child: Column(
            children: [
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.schedule_rounded),
                  title: Text('每日提醒时间'),
                  trailing: Text('上午 8:30')),
              Divider(),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.notifications_active_outlined),
                  title: Text('未完成时提醒'),
                  trailing: Text('开启')),
            ],
          ),
        ),
      ],
    );
  }
}
