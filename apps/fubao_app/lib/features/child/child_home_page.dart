import 'package:flutter/material.dart';

import '../../data/care_share_service.dart';
import '../../data/fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../design/fubao_illustrations.dart';
import '../../widgets/fubao_widgets.dart';
import '../../domain/models.dart';
import '../health/health_center_page.dart';

class ChildHomePage extends StatefulWidget {
  const ChildHomePage({required this.repository, this.shareText, super.key});

  final FubaoRepository repository;
  final Future<CareShareTarget> Function(String text)? shareText;

  @override
  State<ChildHomePage> createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage> {
  int conversationSet = 0;
  FubaoRepository get repository => widget.repository;

  static const conversationSets = [
    [
      _ConversationPrompt(FubaoIllustration.coffee, '轻松聊聊',
          '今天有没有一件让你\n觉得开心的事？', '今天有没有一件让你觉得开心的事？'),
      _ConversationPrompt(FubaoIllustration.sofa, '互相支持',
          '遇到小困难也没关系，\n我们一起想想办法吧。', '遇到小困难也没关系，我们一起想想办法吧。'),
    ],
    [
      _ConversationPrompt(FubaoIllustration.park, '散步时光', '今天散步看到什么\n有趣的事情了吗？',
          '今天散步看到什么有趣的事情了吗？'),
      _ConversationPrompt(FubaoIllustration.plants, '温暖问候',
          '最近睡得怎么样？\n记得好好休息呀。', '最近睡得怎么样？记得好好休息呀。'),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: repository,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Row(
              children: [
                const BrandMark(),
                const Spacer(),
                _HeaderAction(
                  icon: Icons.favorite_border_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('家人的关怀都在这里')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SparkHero(spark: repository.spark),
            if (repository.alerts
                .any((alert) => alert.status == 'pending')) ...[
              const SizedBox(height: 12),
              _AlertBanner(
                alert: repository.alerts
                    .firstWhere((alert) => alert.status == 'pending'),
                onTap: () => _openHealth(context),
              ),
            ],
            const SizedBox(height: 14),
            _TaskProgressCard(repository: repository),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _BloodPressureCard(
                        reading: _latest(HealthMetric.bloodPressure),
                        onTap: () => _openHealth(context))),
                const SizedBox(width: 10),
                Expanded(
                    child: _MoodCard(
                        reading: _latest(HealthMetric.mood),
                        onTap: () => _openHealth(context))),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text('聊一聊，会更好',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => conversationSet =
                      (conversationSet + 1) % conversationSets.length),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('换一换'),
                  style: TextButton.styleFrom(
                      foregroundColor: FubaoColors.inkMuted),
                ),
              ],
            ),
            for (var i = 0;
                i < conversationSets[conversationSet].length;
                i++) ...[
              _ConversationCard(
                prompt: conversationSets[conversationSet][i],
                onPressed: () => _shareConversation(
                    context, conversationSets[conversationSet][i].shareText),
              ),
              if (i == 0) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  HealthReading? _latest(HealthMetric metric) {
    for (final reading in repository.healthReadings) {
      if (reading.metric == metric) return reading;
    }
    return null;
  }

  void _openHealth(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (_) => HealthCenterPage(repository: repository)),
      );

  Future<void> _shareConversation(BuildContext context, String text) async {
    final target = await (widget.shareText ?? CareShareService().share)(text);
    if (!context.mounted) return;
    final message = switch (target) {
      CareShareTarget.wechat => '话术已复制，正在打开微信',
      CareShareTarget.system => '已打开系统分享',
      CareShareTarget.clipboard => '话术已复制，可粘贴到聊天应用',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.alert, required this.onTap});
  final CareAlert alert;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FubaoCard(
      onTap: onTap,
      color: const Color(0xFFFFF4EA),
      borderColor: FubaoColors.orangeStrong,
      child: Row(children: [
        const Icon(Icons.notification_important_rounded,
            color: FubaoColors.orangeStrong),
        const SizedBox(width: 10),
        Expanded(
            child: Text(alert.message,
                maxLines: 2, overflow: TextOverflow.ellipsis)),
        const Icon(Icons.chevron_right_rounded,
            color: FubaoColors.orangeStrong),
      ]));
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 3,
        shadowColor: const Color(0x1A4A3A2E),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(width: 46, height: 46, child: Icon(icon, size: 25)),
        ),
      );
}

class _SparkHero extends StatelessWidget {
  const _SparkHero({required this.spark});
  final FamilySpark spark;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Container(
      height: 182 + (scale - 1).clamp(0, 0.5) * 120,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF4FCF8), Color(0xFFFCFDFB)],
        ),
        border: Border.all(color: FubaoColors.borderMint),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: SparkIllustration(spark: spark),
          ),
          Expanded(
            flex: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${spark.streakDays}',
                    style: TextStyle(
                        color: spark.lit
                            ? FubaoColors.mintStrong
                            : FubaoColors.inkMuted,
                        fontSize: 56,
                        height: 1,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(spark.lit ? '已连续互动 ${spark.streakDays} 天' : '今日火花还未点亮',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('每天一点点，一起更健康',
                    style:
                        TextStyle(color: FubaoColors.inkMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskProgressCard extends StatelessWidget {
  const _TaskProgressCard({required this.repository});
  final FubaoRepository repository;

  @override
  Widget build(BuildContext context) {
    final done = repository.completedTaskCount;
    final total = repository.tasks.length;
    final progress = total == 0 ? 0.0 : done / total;
    final deferred = repository.tasks
        .where((task) => task.isSkipped && !task.isCompleted)
        .length;
    return FubaoCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const FubaoIllustrationBubble(
            illustration: FubaoIllustration.clipboard,
            size: 88,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('今日任务进度',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$done / $total 已完成',
                    style: const TextStyle(color: FubaoColors.inkMuted)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    color: FubaoColors.mintStrong,
                    backgroundColor: FubaoColors.divider,
                  ),
                ),
                const SizedBox(height: 8),
                if (deferred > 0) ...[
                  Text(
                    '\u957f\u8f88\u6709 $deferred \u9879\u9009\u62e9\u7a0d\u540e\u5b8c\u6210',
                    style: const TextStyle(
                        color: FubaoColors.orangeStrong,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                ],
                const Text('继续加油，完成所有任务吧！',
                    style:
                        TextStyle(color: FubaoColors.inkMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  color: FubaoColors.mintStrong,
                  backgroundColor: FubaoColors.mintSoft,
                ),
                Text('$done/$total',
                    style: const TextStyle(
                        color: FubaoColors.mintStrong,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BloodPressureCard extends StatelessWidget {
  const _BloodPressureCard({required this.reading, required this.onTap});
  final HealthReading? reading;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return FubaoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        height: 140 + (scale - 1).clamp(0, 0.5) * 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Expanded(
                  child: Text('血压',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800))),
              _StatusPill('稳定'),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  reading == null
                      ? '--/--'
                      : '${reading!.value['systolic']}/${reading!.value['diastolic']}',
                  maxLines: 1,
                  style: const TextStyle(
                    color: FubaoColors.mintStrong,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const Text('mmHg',
                style: TextStyle(color: FubaoColors.mintStrong, fontSize: 12)),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: FubaoColors.inkMuted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _readingTimeLabel(reading?.recordedAt),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: FubaoColors.inkMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.reading, required this.onTap});
  final HealthReading? reading;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return FubaoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        height: 140 + (scale - 1).clamp(0, 0.5) * 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(
                  child: Text('今日心情',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800))),
              _StatusPill(reading?.value['text']?.toString() ?? '未记录',
                  filled: reading != null),
            ]),
            Expanded(
              child: Center(
                child: Icon(
                  _moodIcon(reading?.value['text']?.toString()),
                  key: Key(
                      'mood-icon-${_moodKey(reading?.value['text']?.toString())}'),
                  size: 62,
                  color: _moodColor(reading?.value['text']?.toString()),
                ),
              ),
            ),
            Text(
              reading == null ? '今天还没有记录心情' : '谢谢你分享心情！',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: TextStyle(color: FubaoColors.inkMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.text, {this.filled = false});
  final String text;
  final bool filled;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: filled ? FubaoColors.mintStrong : FubaoColors.mintSoft,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text,
            style: TextStyle(
                color: filled ? Colors.white : FubaoColors.mintStrong,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );
}

IconData _moodIcon(String? mood) => switch (mood) {
      '开心' || '愉快' => Icons.sentiment_very_satisfied_rounded,
      '平静' => Icons.sentiment_satisfied_alt_rounded,
      '一般' => Icons.sentiment_neutral_rounded,
      '低落' || '不开心' => Icons.sentiment_dissatisfied_rounded,
      '不舒服' => Icons.sick_outlined,
      _ => Icons.sentiment_satisfied_outlined,
    };

String _moodKey(String? mood) => switch (mood) {
      '开心' || '愉快' => 'happy',
      '平静' => 'calm',
      '一般' => 'neutral',
      '低落' || '不开心' => 'sad',
      '不舒服' => 'unwell',
      _ => 'unknown',
    };

Color _moodColor(String? mood) => switch (mood) {
      '低落' || '不开心' || '不舒服' => FubaoColors.orangeStrong,
      '一般' => FubaoColors.inkMuted,
      _ => FubaoColors.mintStrong,
    };

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.prompt, required this.onPressed});
  final _ConversationPrompt prompt;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => FubaoCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            FubaoIllustrationBubble(
              illustration: prompt.image,
              size: 72,
              backgroundColor: const Color(0xFFFFF2E7),
              padding: const EdgeInsets.all(5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prompt.category,
                      style: const TextStyle(
                          color: FubaoColors.orangeStrong,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(prompt.text,
                      style: const TextStyle(fontSize: 14, height: 1.35)),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: FubaoColors.orangeStrong,
                side: const BorderSide(color: FubaoColors.orangeStrong),
                minimumSize: const Size(72, 42),
              ),
              child: const Text('去聊聊'),
            ),
          ],
        ),
      );
}

class _ConversationPrompt {
  const _ConversationPrompt(
      this.image, this.category, this.text, this.shareText);
  final FubaoIllustration image;
  final String category;
  final String text;
  final String shareText;
}

String _readingTimeLabel(DateTime? value) {
  if (value == null) return '今天暂无记录';
  final local = value.toLocal();
  final now = DateTime.now();
  final sameDay = local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return sameDay ? '今天 $time' : '${local.month}月${local.day}日 $time';
}
