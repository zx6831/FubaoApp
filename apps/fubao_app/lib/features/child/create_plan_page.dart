import 'package:flutter/material.dart';

import '../../data/fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../design/fubao_illustrations.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';

typedef _PlanOption = ({
  String title,
  String description,
  TaskKind kind,
  FubaoIllustration illustration,
});

class CreatePlanPage extends StatefulWidget {
  const CreatePlanPage({this.repository, super.key});

  final FubaoRepository? repository;

  @override
  State<CreatePlanPage> createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends State<CreatePlanPage> {
  int selected = 0;
  int step = 0;
  TimeOfDay reminderTime = const TimeOfDay(hour: 8, minute: 30);
  TaskKind selectedKind = TaskKind.bloodPressure;
  final selectedDays = <int>{1, 2, 3, 4, 5, 6, 7};
  final titleController = TextEditingController(text: '血压管理');
  final noteController = TextEditingController();
  bool submitting = false;

  static const options = <_PlanOption>[
    (
      title: '血压管理',
      description: '记录血压，规律监测，稳稳守护',
      kind: TaskKind.bloodPressure,
      illustration: FubaoIllustration.bloodPressureDevice
    ),
    (
      title: '用药提醒',
      description: '按时提醒，不漏服，吃药更安心',
      kind: TaskKind.medicine,
      illustration: FubaoIllustration.medicineBox
    ),
    (
      title: '健康生活习惯',
      description: '规律作息，适度运动，生活更健康',
      kind: TaskKind.walk,
      illustration: FubaoIllustration.walkingShoe
    ),
    (
      title: '自定义计划',
      description: '按长辈情况，灵活设置专属计划',
      kind: TaskKind.custom,
      illustration: FubaoIllustration.pencil
    ),
  ];

  @override
  void dispose() {
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

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
                      width: 130, height: 110),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          switch (step) {
                            0 => '先选一个最关心的方向',
                            1 => '设置简单易行的提醒',
                            _ => '最后确认一下计划信息',
                          },
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(
                          switch (step) {
                            0 => '我们将为长辈定制简单易行的每日计划',
                            1 => '选择提醒时间和每周执行日期',
                            _ => '确认无误后，任务会同步到长辈端',
                          },
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
                    onTap: () => setState(() {
                      selected = i;
                      selectedKind = options[i].kind;
                      titleController.text = options[i].title;
                    }),
                  ),
                  const SizedBox(height: 12),
                ]
              else if (step == 1)
                _PlanInformation(
                  titleController: titleController,
                  noteController: noteController,
                  selectedKind: selectedKind,
                  reminderTime: reminderTime,
                  selectedDays: selectedDays,
                  onPickTime: _pickTime,
                  onKindChanged: (kind) => setState(() => selectedKind = kind),
                  onToggleDay: (day) => setState(() {
                    selectedDays.contains(day)
                        ? selectedDays.remove(day)
                        : selectedDays.add(day);
                  }),
                )
              else
                _Confirmation(
                  option: options[selected],
                  selectedKind: selectedKind,
                  title: titleController.text.trim(),
                  reminderTime: reminderTime,
                  selectedDays: selectedDays,
                  note: noteController.text.trim(),
                ),
              const SizedBox(height: 8),
              if (step > 0) ...[
                OutlinedButton(
                  onPressed:
                      submitting ? null : () => setState(() => step -= 1),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: FubaoColors.inkMuted,
                    side: const BorderSide(color: FubaoColors.divider),
                  ),
                  child: const Text('上一步'),
                ),
                const SizedBox(height: 10),
              ],
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [FubaoColors.mint, FubaoColors.mintStrong]),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: FilledButton(
                  onPressed: submitting ? null : _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(58),
                    textStyle: const TextStyle(
                        fontFamily: 'NotoSansSC',
                        fontSize: 19,
                        fontWeight: FontWeight.w900),
                  ),
                  child: submitting
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(step < 2 ? '下一步' : '开始执行'),
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: reminderTime);
    if (picked != null) setState(() => reminderTime = picked);
  }

  Future<void> _next() async {
    if (step == 0) {
      setState(() => step = 1);
      return;
    }
    if (step == 1) {
      if (titleController.text.trim().isEmpty || selectedDays.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('请填写计划名称并至少选择一天')));
        return;
      }
      setState(() => step = 2);
      return;
    }
    setState(() => submitting = true);
    try {
      final option = options[selected];
      await widget.repository?.createPlan(PlanDraft(
        kind: selectedKind,
        title: titleController.text.trim(),
        subtitle: option.description,
        startsOn: DateTime.now(),
        reminderTime: _timeValue(reminderTime),
        daysOfWeek: selectedDays.toList()..sort(),
        enrollmentData: {
          if (noteController.text.trim().isNotEmpty)
            'note': noteController.text.trim(),
          'createdFrom': 'threeStepFlow',
        },
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${titleController.text.trim()}已创建，今日任务已同步')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('创建失败：$error')));
      setState(() => submitting = false);
    }
  }

  String _timeValue(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) {
    const labels = ['选择计划', '填写信息', '开始执行'];
    return Row(children: [
      for (var i = 0; i < labels.length; i++)
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
    ]);
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard(
      {required this.option, required this.selected, required this.onTap});
  final _PlanOption option;
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
              FubaoIllustrationBubble(
                  illustration: option.illustration, size: 82, circular: false),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(option.description,
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

class _PlanInformation extends StatelessWidget {
  const _PlanInformation({
    required this.titleController,
    required this.noteController,
    required this.selectedKind,
    required this.reminderTime,
    required this.selectedDays,
    required this.onPickTime,
    required this.onKindChanged,
    required this.onToggleDay,
  });
  final TextEditingController titleController;
  final TextEditingController noteController;
  final TaskKind selectedKind;
  final TimeOfDay reminderTime;
  final Set<int> selectedDays;
  final VoidCallback onPickTime;
  final ValueChanged<TaskKind> onKindChanged;
  final ValueChanged<int> onToggleDay;

  @override
  Widget build(BuildContext context) => FubaoCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('计划类型',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          DropdownButtonFormField<TaskKind>(
            initialValue: selectedKind,
            items: TaskKind.values
                .map((kind) => DropdownMenuItem(
                      value: kind,
                      child: Text(_kindLabel(kind)),
                    ))
                .toList(),
            onChanged: (kind) {
              if (kind != null) onKindChanged(kind);
            },
          ),
          const SizedBox(height: 16),
          const Text('计划名称',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(
              controller: titleController,
              maxLength: 80,
              decoration:
                  const InputDecoration(hintText: '例如：早晨测血压', counterText: '')),
          const SizedBox(height: 16),
          const Text('提醒时间',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ListTile(
            onTap: onPickTime,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: FubaoColors.divider)),
            leading: const Icon(Icons.schedule_rounded,
                color: FubaoColors.mintStrong),
            title: Text(reminderTime.format(context)),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(height: 16),
          const Text('每周执行',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(spacing: 7, runSpacing: 7, children: [
            for (var day = 1; day <= 7; day++)
              FilterChip(
                selected: selectedDays.contains(day),
                onSelected: (_) => onToggleDay(day),
                label: Text(const ['一', '二', '三', '四', '五', '六', '日'][day - 1]),
                selectedColor: const Color(0xFFE4F7EF),
                checkmarkColor: FubaoColors.mintStrong,
              ),
          ]),
          const SizedBox(height: 16),
          const Text('补充说明（选填）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(
              controller: noteController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(hintText: '例如：饭后休息 5 分钟再测量')),
        ]),
      );
}

class _Confirmation extends StatelessWidget {
  const _Confirmation(
      {required this.option,
      required this.selectedKind,
      required this.title,
      required this.reminderTime,
      required this.selectedDays,
      required this.note});
  final _PlanOption option;
  final TaskKind selectedKind;
  final String title;
  final TimeOfDay reminderTime;
  final Set<int> selectedDays;
  final String note;
  @override
  Widget build(BuildContext context) {
    final days = selectedDays.toList()..sort();
    final dayLabel = selectedDays.length == 7
        ? '每天'
        : '周${days.map((day) => const [
              '一',
              '二',
              '三',
              '四',
              '五',
              '六',
              '日'
            ][day - 1]).join('、')}';
    return Column(children: [
      _OptionCard(option: option, selected: true, onTap: () {}),
      const SizedBox(height: 12),
      FubaoCard(
          child: Column(children: [
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.category_outlined),
            title: const Text('计划类型'),
            trailing: Text(_kindLabel(selectedKind))),
        const Divider(),
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_note_rounded),
            title: const Text('计划名称'),
            trailing: SizedBox(
                width: 140,
                child: Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right))),
        const Divider(),
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_rounded),
            title: const Text('提醒时间'),
            trailing: Text(reminderTime.format(context))),
        const Divider(),
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month_rounded),
            title: const Text('执行日期'),
            trailing: Text(dayLabel)),
        if (note.isNotEmpty) ...[
          const Divider(),
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notes_rounded),
              title: const Text('补充说明'),
              subtitle: Text(note)),
        ],
      ])),
    ]);
  }
}

String _kindLabel(TaskKind kind) => switch (kind) {
      TaskKind.bloodPressure => '血压管理',
      TaskKind.bloodGlucose => '血糖管理',
      TaskKind.medicine => '用药提醒',
      TaskKind.walk => '运动计划',
      TaskKind.mood => '生活习惯',
      TaskKind.weight => '体重管理',
      TaskKind.custom => '自定义计划',
    };
