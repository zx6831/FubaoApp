import 'package:flutter/material.dart';

import '../../data/fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';

class HealthCenterPage extends StatelessWidget {
  const HealthCenterPage(
      {required this.repository, this.elder = false, super.key});
  final FubaoRepository repository;
  final bool elder;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('健康记录'), centerTitle: true),
        body: AnimatedBuilder(
          animation: repository,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text('记录一项数据',
                  style: TextStyle(
                      fontSize: elder ? 26 : 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: [
                _entry(context, HealthMetric.bloodPressure, '血压',
                    Icons.monitor_heart_outlined),
                _entry(context, HealthMetric.bloodGlucose, '血糖',
                    Icons.bloodtype_outlined),
                _entry(context, HealthMetric.mood, '心情', Icons.mood_rounded),
                _entry(context, HealthMetric.weight, '体重',
                    Icons.monitor_weight_outlined),
              ]),
              const SizedBox(height: 22),
              if (repository.alerts
                  .any((alert) => alert.status == 'pending')) ...[
                const Text('需要关注',
                    style:
                        TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                for (final alert in repository.alerts
                    .where((item) => item.status == 'pending'))
                  Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AlertCard(alert: alert, repository: repository)),
                const SizedBox(height: 10),
              ],
              const Text('最近记录',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              if (repository.healthReadings.isEmpty)
                const FubaoCard(child: Center(child: Text('还没有健康记录')))
              else
                for (final reading in repository.healthReadings)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReadingCard(reading: reading, elder: elder)),
            ],
          ),
        ),
      );

  Widget _entry(BuildContext context, HealthMetric metric, String label,
          IconData icon) =>
      SizedBox(
        width: elder ? 168 : 160,
        height: elder ? 86 : 72,
        child: OutlinedButton.icon(
          onPressed: () => _record(context, metric),
          icon: Icon(icon),
          label: Text(label),
          style:
              OutlinedButton.styleFrom(foregroundColor: FubaoColors.mintStrong),
        ),
      );

  Future<void> _record(BuildContext context, HealthMetric metric) async {
    await showHealthRecordDialog(context, repository, metric, elder: elder);
  }
}

Future<bool> showHealthRecordDialog(
  BuildContext context,
  FubaoRepository repository,
  HealthMetric metric, {
  bool elder = false,
}) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => elder
        ? _ElderRecordHealthDialog(metric: metric)
        : _RecordHealthDialog(metric: metric),
  );
  if (result == null || !context.mounted) return false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('确认本次记录'),
      content: Text(_recordSummary(metric, result)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('返回修改'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('确认保存'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  await repository.recordHealth(metric, result);
  return true;
}

class _ElderRecordHealthDialog extends StatefulWidget {
  const _ElderRecordHealthDialog({required this.metric});
  final HealthMetric metric;

  @override
  State<_ElderRecordHealthDialog> createState() =>
      _ElderRecordHealthDialogState();
}

class _ElderRecordHealthDialogState extends State<_ElderRecordHealthDialog> {
  Object? primary;
  Object? secondary;
  bool custom = false;
  String customPrimary = '';
  String customSecondary = '';
  String? errorText;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('记录${_metricLabel(widget.metric)}'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_elderPrompt(widget.metric),
                    style: const TextStyle(
                        color: FubaoColors.inkMuted,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                if (!custom) ..._selectionFields(),
                if (custom) ..._customFields(),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => setState(() {
                    custom = !custom;
                    errorText = null;
                  }),
                  icon: Icon(
                      custom ? Icons.grid_view_rounded : Icons.edit_outlined),
                  label: Text(custom ? '返回快速选择' : '自定义输入'),
                ),
                if (errorText != null)
                  Text(errorText!,
                      style: const TextStyle(
                          color: FubaoColors.orangeStrong,
                          fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(onPressed: _next, child: const Text('下一步')),
        ],
      );

  List<Widget> _selectionFields() => switch (widget.metric) {
        HealthMetric.bloodPressure => [
            _choiceTitle('收缩压（高压）'),
            _numberChoices([100, 110, 120, 130, 140, 150, 160], true),
            const SizedBox(height: 14),
            _choiceTitle('舒张压（低压）'),
            _numberChoices([60, 70, 80, 90, 100], false),
          ],
        HealthMetric.bloodGlucose => [
            _numberChoices([4.5, 5.5, 6.5, 7.0, 8.0, 10.0], true),
          ],
        HealthMetric.weight => [
            _numberChoices([45, 50, 55, 60, 65, 70, 75], true),
          ],
        HealthMetric.mood => [
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                for (final mood in const [
                  ('开心', Icons.sentiment_very_satisfied_rounded),
                  ('平静', Icons.sentiment_satisfied_alt_rounded),
                  ('一般', Icons.sentiment_neutral_rounded),
                  ('低落', Icons.sentiment_dissatisfied_rounded),
                  ('不舒服', Icons.sick_outlined),
                ])
                  ChoiceChip(
                    key: Key('elder-mood-${mood.$1}'),
                    selected: primary == mood.$1,
                    onSelected: (_) => setState(() => primary = mood.$1),
                    avatar: Icon(mood.$2, color: FubaoColors.mintStrong),
                    label: Text(mood.$1, style: const TextStyle(fontSize: 17)),
                    padding: const EdgeInsets.all(10),
                  ),
              ],
            ),
          ],
      };

  Widget _choiceTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      );

  Widget _numberChoices(List<num> values, bool first) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in values)
            ChoiceChip(
              key: Key(
                  'elder-${first ? 'primary' : 'secondary'}-${_numberLabel(value)}'),
              selected: (first ? primary : secondary) == value,
              onSelected: (_) => setState(() {
                if (first) {
                  primary = value;
                } else {
                  secondary = value;
                }
              }),
              label: Text(_numberLabel(value),
                  style: const TextStyle(fontSize: 18)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
        ],
      );

  List<Widget> _customFields() => [
        TextFormField(
          key: const Key('record-primary-value'),
          autofocus: true,
          keyboardType: widget.metric == HealthMetric.mood
              ? TextInputType.text
              : const TextInputType.numberWithOptions(decimal: true),
          decoration:
              InputDecoration(labelText: _firstFieldLabel(widget.metric)),
          onChanged: (value) => customPrimary = value,
        ),
        if (widget.metric == HealthMetric.bloodPressure) ...[
          const SizedBox(height: 10),
          TextFormField(
            key: const Key('record-secondary-value'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '舒张压（低压）'),
            onChanged: (value) => customSecondary = value,
          ),
        ],
      ];

  void _next() {
    Object? first = primary;
    Object? second = secondary;
    if (custom) {
      first = widget.metric == HealthMetric.mood
          ? customPrimary.trim()
          : double.tryParse(customPrimary.trim());
      second = double.tryParse(customSecondary.trim());
    }
    final data = widget.metric == HealthMetric.bloodPressure
        ? {'systolic': first, 'diastolic': second}
        : widget.metric == HealthMetric.mood
            ? {'text': first}
            : {'value': first};
    if (data.values.any((value) => value == null || value == '')) {
      setState(() => errorText = '请选择一项，或使用自定义输入');
      return;
    }
    Navigator.pop(context, data);
  }
}

String _elderPrompt(HealthMetric metric) => switch (metric) {
      HealthMetric.bloodPressure => '选择最接近血压仪读数的数值',
      HealthMetric.bloodGlucose => '选择最接近血糖仪读数的数值',
      HealthMetric.mood => '今天的心情更接近哪一种？',
      HealthMetric.weight => '选择最接近当前体重的数值',
    };

class _RecordHealthDialog extends StatefulWidget {
  const _RecordHealthDialog({required this.metric});

  final HealthMetric metric;

  @override
  State<_RecordHealthDialog> createState() => _RecordHealthDialogState();
}

class _RecordHealthDialogState extends State<_RecordHealthDialog> {
  String primary = '';
  String secondary = '';
  String? errorText;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('记录${_metricLabel(widget.metric)}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            key: const Key('record-primary-value'),
            initialValue: primary,
            autofocus: true,
            keyboardType: widget.metric == HealthMetric.mood
                ? TextInputType.text
                : const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _firstFieldLabel(widget.metric),
              errorText: errorText,
            ),
            onChanged: (value) => primary = value,
          ),
          if (widget.metric == HealthMetric.bloodPressure) ...[
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('record-secondary-value'),
              initialValue: secondary,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '舒张压（低压）'),
              onChanged: (value) => secondary = value,
            ),
          ],
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(onPressed: _next, child: const Text('下一步')),
        ],
      );

  void _next() {
    final data = widget.metric == HealthMetric.bloodPressure
        ? {
            'systolic': double.tryParse(primary.trim()),
            'diastolic': double.tryParse(secondary.trim()),
          }
        : widget.metric == HealthMetric.mood
            ? {'text': primary.trim()}
            : {'value': double.tryParse(primary.trim())};
    if (data.values.any((value) => value == null || value == '')) {
      setState(() => errorText = '请填写有效的记录数据');
      return;
    }
    Navigator.pop(context, data);
  }
}

String _metricLabel(HealthMetric metric) => const {
      HealthMetric.bloodPressure: '血压',
      HealthMetric.bloodGlucose: '血糖',
      HealthMetric.mood: '心情',
      HealthMetric.weight: '体重',
    }[metric]!;

String _firstFieldLabel(HealthMetric metric) => switch (metric) {
      HealthMetric.bloodPressure => '收缩压（高压）',
      HealthMetric.bloodGlucose => '血糖（mmol/L）',
      HealthMetric.mood => '今天的心情',
      HealthMetric.weight => '体重（kg）',
    };

String _recordSummary(HealthMetric metric, Map<String, dynamic> data) =>
    switch (metric) {
      HealthMetric.bloodPressure =>
        '${_numberLabel(data['systolic'])} / ${_numberLabel(data['diastolic'])} mmHg',
      HealthMetric.bloodGlucose => '${_numberLabel(data['value'])} mmol/L',
      HealthMetric.mood => data['text'].toString(),
      HealthMetric.weight => '${_numberLabel(data['value'])} kg',
    };

String _numberLabel(Object? value) {
  final number = value as num?;
  if (number == null) return '--';
  return number % 1 == 0 ? number.toInt().toString() : number.toString();
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.reading, required this.elder});
  final HealthReading reading;
  final bool elder;
  @override
  Widget build(BuildContext context) => FubaoCard(
          child: Row(children: [
        Icon(_icon(reading.metric),
            color: FubaoColors.mintStrong, size: elder ? 34 : 28),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_name(reading.metric),
              style: TextStyle(
                  fontSize: elder ? 21 : 17, fontWeight: FontWeight.w900)),
          Text(_value(reading),
              style: const TextStyle(
                  color: FubaoColors.mintStrong, fontWeight: FontWeight.w800))
        ])),
        Text('${reading.recordedAt.month}/${reading.recordedAt.day}',
            style: const TextStyle(color: FubaoColors.inkMuted)),
      ]));
  IconData _icon(HealthMetric m) => [
        Icons.monitor_heart_outlined,
        Icons.bloodtype_outlined,
        Icons.mood_rounded,
        Icons.monitor_weight_outlined
      ][m.index];
  String _name(HealthMetric m) => ['血压', '血糖', '心情', '体重'][m.index];
  String _value(HealthReading r) => switch (r.metric) {
        HealthMetric.bloodPressure =>
          '${r.value['systolic']}/${r.value['diastolic']} mmHg',
        HealthMetric.bloodGlucose => '${r.value['value']} mmol/L',
        HealthMetric.mood => '${r.value['text']}',
        HealthMetric.weight => '${r.value['value']} kg'
      };
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.repository});
  final CareAlert alert;
  final FubaoRepository repository;
  @override
  Widget build(BuildContext context) => FubaoCard(
      color: const Color(0xFFFFF5EC),
      borderColor: FubaoColors.orangeStrong,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${alert.level} 关怀提醒',
            style: const TextStyle(
                color: FubaoColors.orangeStrong, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(alert.message),
        Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: () => repository.updateAlert(alert.id, 'handled'),
                child: const Text('我已处理'))),
      ]));
}
