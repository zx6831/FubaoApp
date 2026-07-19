import 'dart:math' as math;

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
  String? taskId,
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
  await repository.recordHealth(metric, result, taskId: taskId);
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
  void initState() {
    super.initState();
    switch (widget.metric) {
      case HealthMetric.bloodPressure:
        primary = 120.0;
        secondary = 80.0;
      case HealthMetric.bloodGlucose:
        primary = 5.5;
      case HealthMetric.weight:
        primary = 60.0;
      case HealthMetric.mood:
        break;
    }
  }

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
            _numberDial(
              title: '收缩压（高压）',
              unit: 'mmHg',
              min: 80,
              max: 200,
              first: true,
            ),
            const SizedBox(height: 14),
            _numberDial(
              title: '舒张压（低压）',
              unit: 'mmHg',
              min: 40,
              max: 130,
              first: false,
            ),
          ],
        HealthMetric.bloodGlucose => [
            _numberDial(
              title: '血糖',
              unit: 'mmol/L',
              min: 2,
              max: 20,
              step: .1,
              first: true,
            ),
          ],
        HealthMetric.weight => [
            _numberDial(
              title: '体重',
              unit: 'kg',
              min: 30,
              max: 150,
              step: .5,
              first: true,
            ),
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

  Widget _numberDial({
    required String title,
    required String unit,
    required double min,
    required double max,
    required bool first,
    double step = 1,
  }) {
    final value = ((first ? primary : secondary) as num).toDouble();
    return _HealthValueDial(
      key: Key('elder-${first ? 'primary' : 'secondary'}-dial'),
      title: title,
      unit: unit,
      min: min,
      max: max,
      step: step,
      value: value,
      onChanged: (value) => setState(() {
        if (first) {
          primary = value;
        } else {
          secondary = value;
        }
      }),
    );
  }

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

class _HealthValueDial extends StatelessWidget {
  const _HealthValueDial({
    required this.title,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String unit;
  final double min;
  final double max;
  final double step;
  final double value;
  final ValueChanged<double> onChanged;

  void _updateValue(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height - 30);
    var angle = math.atan2(position.dy - center.dy, position.dx - center.dx);
    if (angle < 0) angle += math.pi * 2;
    if (angle < math.pi) {
      angle = position.dx < center.dx ? math.pi : math.pi * 2;
    }
    final progress = ((angle - math.pi) / math.pi).clamp(0.0, 1.0);
    final raw = min + (max - min) * progress;
    final snapped = (raw / step).round() * step;
    final precision = step < 1 ? 1 : 0;
    onChanged(double.parse(snapped.clamp(min, max).toStringAsFixed(precision)));
  }

  @override
  Widget build(BuildContext context) {
    final shownValue = _numberLabel(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: title,
          value: '$shownValue $unit',
          increasedValue: _numberLabel((value + step).clamp(min, max)),
          decreasedValue: _numberLabel((value - step).clamp(min, max)),
          onIncrease: () => onChanged((value + step).clamp(min, max)),
          onDecrease: () => onChanged((value - step).clamp(min, max)),
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              color: const Color(0xFFF2FAF6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFCDEDE0)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      _updateValue(details.localPosition, size),
                  onPanStart: (details) =>
                      _updateValue(details.localPosition, size),
                  onPanUpdate: (details) =>
                      _updateValue(details.localPosition, size),
                  child: CustomPaint(
                    painter: _HealthDialPainter(
                      min: min,
                      max: max,
                      value: value,
                    ),
                    child: Align(
                      alignment: const Alignment(0, .72),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1645C38F),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: shownValue,
                                style: const TextStyle(
                                  color: FubaoColors.mintStrong,
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(
                                text: '  $unit',
                                style: const TextStyle(
                                  color: FubaoColors.inkMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Center(
          child: Text(
            '沿仪表盘滑动指针选择数值',
            style: TextStyle(color: FubaoColors.inkMuted, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _HealthDialPainter extends CustomPainter {
  const _HealthDialPainter({
    required this.min,
    required this.max,
    required this.value,
  });

  final double min;
  final double max;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 30);
    final radius = math.min(size.width * .39, size.height - 54);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi;
    const sweep = math.pi;
    final progress = ((value - min) / (max - min)).clamp(0.0, 1.0);

    final track = Paint()
      ..color = const Color(0xFFDCE7E2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, track);

    final active = Paint()
      ..shader = const LinearGradient(
        colors: [FubaoColors.mint, FubaoColors.mintStrong],
      ).createShader(Rect.fromLTWH(
          center.dx - radius, center.dy - radius, radius * 2, radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep * progress, false, active);

    final tickPaint = Paint()
      ..color = FubaoColors.inkMuted.withValues(alpha: .55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index <= 10; index++) {
      final angle = start + sweep * index / 10;
      final outer =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 15);
      final inner = center +
          Offset(math.cos(angle), math.sin(angle)) *
              (radius - (index % 5 == 0 ? 27 : 22));
      canvas.drawLine(inner, outer, tickPaint);
    }

    final angle = start + sweep * progress;
    final needleEnd =
        center + Offset(math.cos(angle), math.sin(angle)) * (radius - 25);
    final needle = Paint()
      ..color = FubaoColors.orangeStrong
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needle);
    canvas.drawCircle(center, 11, Paint()..color = Colors.white);
    canvas.drawCircle(center, 7, Paint()..color = FubaoColors.orangeStrong);

    _paintLabel(canvas, _numberLabel(min),
        Offset(center.dx - radius - 2, center.dy - 20), TextAlign.left);
    _paintLabel(canvas, _numberLabel(max),
        Offset(center.dx + radius + 2, center.dy - 20), TextAlign.right);
  }

  void _paintLabel(
      Canvas canvas, String text, Offset anchor, TextAlign textAlign) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: FubaoColors.inkMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    )..layout();
    final dx =
        textAlign == TextAlign.right ? anchor.dx - painter.width : anchor.dx;
    painter.paint(canvas, Offset(dx, anchor.dy));
  }

  @override
  bool shouldRepaint(covariant _HealthDialPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.min != min ||
      oldDelegate.max != max;
}

String _elderPrompt(HealthMetric metric) => switch (metric) {
      HealthMetric.bloodPressure => '拨动指针，输入血压仪上的数值',
      HealthMetric.bloodGlucose => '拨动指针，输入血糖仪上的数值',
      HealthMetric.mood => '今天的心情更接近哪一种？',
      HealthMetric.weight => '拨动指针，输入体重秤上的数值',
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
