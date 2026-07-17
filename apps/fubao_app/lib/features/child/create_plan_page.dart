import 'package:flutter/material.dart';

import '../../design/fubao_colors.dart';
import '../../design/fubao_illustrations.dart';
import '../../widgets/fubao_widgets.dart';

class CreatePlanPage extends StatefulWidget {
  const CreatePlanPage({super.key});
  @override
  State<CreatePlanPage> createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends State<CreatePlanPage> {
  int selected = 0;
  int step = 0;

  static const options = [
    ('血压管理', '记录血压，规律监测，稳稳守护', FubaoIllustration.bloodPressureDevice),
    ('用药提醒', '按时提醒，不漏服，吃药更安心', FubaoIllustration.medicineBox),
    ('健康生活习惯', '规律作息，适度运动，生活更健康', FubaoIllustration.walkingShoe),
    ('自定义计划', '按长辈情况，灵活设置专属计划', FubaoIllustration.pencil),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('创建健康计划',
              style: TextStyle(fontWeight: FontWeight.w900)),
          centerTitle: true,
          backgroundColor: FubaoColors.canvas,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            children: [
              _StepHeader(step: step),
              const SizedBox(height: 18),
              Container(
                height: 110,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFF1FAF6), Color(0xFFFCFDFB)]),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(children: [
                  const FubaoIllustrationAsset(FubaoIllustration.mascotBanner,
                      width: 130, height: 110, fit: BoxFit.cover),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step == 0 ? '先选一个最关心的方向' : '再确认一下计划信息',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(step == 0 ? '我们将为长辈定制简单易行的每日计划' : '确认提醒时间后即可开始执行',
                          style: const TextStyle(
                              color: FubaoColors.inkMuted, fontSize: 12)),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 18),
              if (step == 0)
                for (var i = 0; i < options.length; i++) ...[
                  _OptionCard(
                    option: options[i],
                    selected: selected == i,
                    onTap: () => setState(() => selected = i),
                  ),
                  const SizedBox(height: 12),
                ]
              else
                _Confirmation(option: options[selected]),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [FubaoColors.mint, FubaoColors.mintStrong]),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: FilledButton(
                  onPressed: () {
                    if (step == 0) {
                      setState(() => step = 1);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${options[selected].$1}已创建，今日任务已同步')));
                      Navigator.of(context).pop();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(58),
                    textStyle: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  child: Text(step == 0 ? '下一步' : '开始执行'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) {
    const labels = ['选择计划', '填写信息', '开始执行'];
    return Row(children: [
      for (var i = 0; i < labels.length; i++) ...[
        Expanded(
            child: Column(children: [
          Row(children: [
            if (i > 0)
              Expanded(
                  child: Container(
                      height: 2,
                      color: i <= step
                          ? FubaoColors.mintStrong
                          : FubaoColors.divider)),
            CircleAvatar(
              radius: 15,
              backgroundColor:
                  i <= step ? FubaoColors.mintStrong : const Color(0xFFEDECE9),
              child: Text('${i + 1}',
                  style: TextStyle(
                      color: i <= step ? Colors.white : FubaoColors.inkMuted,
                      fontWeight: FontWeight.w800)),
            ),
            if (i < labels.length - 1)
              Expanded(
                  child: Container(
                      height: 2,
                      color: i < step
                          ? FubaoColors.mintStrong
                          : FubaoColors.divider)),
          ]),
          const SizedBox(height: 6),
          Text(labels[i],
              style: TextStyle(
                  color:
                      i <= step ? FubaoColors.mintStrong : FubaoColors.inkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ])),
      ],
    ]);
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard(
      {required this.option, required this.selected, required this.onTap});
  final (String, String, FubaoIllustration) option;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FubaoCard(
        onTap: onTap,
        color: selected ? const Color(0xFFF4FCF8) : Colors.white,
        borderColor: selected ? FubaoColors.mintStrong : FubaoColors.divider,
        padding: const EdgeInsets.all(14),
        child: SizedBox(
            height: 78,
            child: Row(children: [
              FubaoIllustrationAsset(option.$3,
                  width: 92, height: 78, fit: BoxFit.cover),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.$1,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(option.$2,
                      style: const TextStyle(
                          color: FubaoColors.inkMuted, fontSize: 12)),
                ],
              )),
              Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color:
                      selected ? FubaoColors.mintStrong : FubaoColors.inkMuted),
            ])),
      );
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.option});
  final (String, String, FubaoIllustration) option;
  @override
  Widget build(BuildContext context) => Column(children: [
        _OptionCard(option: option, selected: true, onTap: () {}),
        const SizedBox(height: 12),
        const FubaoCard(
            child: Column(children: [
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
        ])),
      ]);
}
