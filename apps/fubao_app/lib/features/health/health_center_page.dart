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
    await showHealthRecordDialog(context, repository, metric);
  }
}

Future<bool> showHealthRecordDialog(
  BuildContext context,
  FubaoRepository repository,
  HealthMetric metric,
) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _RecordHealthDialog(metric: metric),
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
