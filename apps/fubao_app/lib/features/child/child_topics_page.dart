import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/care_share_service.dart';
import '../../data/fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../design/fubao_illustrations.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';
import '../profile/message_center_page.dart';

class ChildTopicsPage extends StatelessWidget {
  const ChildTopicsPage({required this.repository, super.key});
  final FubaoRepository repository;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            const CenteredPageHeader(
              title: '话题',
              trailing: Icon(Icons.auto_awesome_rounded,
                  color: FubaoColors.orangeStrong, size: 26),
            ),
            const SizedBox(height: 22),
            const Row(children: [
              Icon(Icons.favorite_rounded,
                  color: FubaoColors.orangeStrong, size: 30),
              SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('今天适合聊一聊',
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('用一句温暖的话，拉近彼此的距离',
                        style: TextStyle(
                            color: FubaoColors.inkMuted, fontSize: 13)),
                  ])),
            ]),
            const SizedBox(height: 16),
            for (var i = 0; i < repository.topics.length; i++) ...[
              _TopicCard(
                topic: repository.topics[i],
                index: i,
                repository: repository,
              ),
              const SizedBox(height: 12),
            ],
            _WeeklyReport(repository: repository),
            const SizedBox(height: 14),
            _MessageHistory(repository: repository),
          ],
        ),
      );
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.index,
    required this.repository,
  });
  final CareTopic topic;
  final int index;
  final FubaoRepository repository;
  @override
  Widget build(BuildContext context) => FubaoCard(
        borderColor: const Color(0xFFFFD9B8),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          FubaoIllustrationBubble(
            illustration: index == 0
                ? FubaoIllustration.clipboard
                : FubaoIllustration.park,
            size: 82,
            backgroundColor: const Color(0xFFFFF4E9),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(topic.title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(topic.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: FubaoColors.inkMuted,
                        fontSize: 12,
                        height: 1.4)),
              ])),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () async {
              await Clipboard.setData(
                  ClipboardData(text: topic.suggestedWords));
              await repository.markTopicCopied(topic.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('话术已复制'),
                  action: SnackBarAction(
                    label: '分享',
                    onPressed: () =>
                        CareShareService().share(topic.suggestedWords),
                  ),
                ));
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: FubaoColors.orangeStrong,
              side: const BorderSide(color: FubaoColors.orangeStrong),
              minimumSize: const Size(74, 42),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('复制话术'),
          ),
        ]),
      );
}

class _WeeklyReport extends StatelessWidget {
  const _WeeklyReport({required this.repository});
  final FubaoRepository repository;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFF0FAF6), Color(0xFFFAFDFB)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: FubaoColors.borderMint),
        ),
        child: Column(children: [
          Row(children: [
            const FubaoIllustrationAsset(FubaoIllustration.planClipboard,
                width: 84, height: 72),
            const SizedBox(width: 12),
            const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('本周健康周报',
                      style:
                          TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  Text('3 月 31 日 - 4 月 6 日',
                      style:
                          TextStyle(color: FubaoColors.inkMuted, fontSize: 12)),
                ])),
          ]),
          const Divider(color: FubaoColors.borderMint),
          Row(children: [
            Expanded(
                child: _ReportMetric(
                    label: '任务完成情况',
                    value:
                        '${repository.completedTaskCount} / ${repository.tasks.length}',
                    suffix: '次')),
            const SizedBox(
                height: 58,
                child: VerticalDivider(color: FubaoColors.borderMint)),
            Expanded(
                child: _ReportMetric(
                    label: '连续打卡天数',
                    value: '${repository.spark.streakDays}',
                    suffix: '天')),
          ]),
        ]),
      );
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric(
      {required this.label, required this.value, required this.suffix});
  final String label;
  final String value;
  final String suffix;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: FubaoColors.inkMuted, fontSize: 12)),
        const SizedBox(height: 3),
        Text.rich(TextSpan(children: [
          TextSpan(
              text: value,
              style: const TextStyle(
                  color: FubaoColors.mintStrong,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          TextSpan(
              text: ' $suffix',
              style:
                  const TextStyle(color: FubaoColors.inkMuted, fontSize: 12)),
        ])),
      ]);
}

class _MessageHistory extends StatelessWidget {
  const _MessageHistory({required this.repository});
  final FubaoRepository repository;
  @override
  Widget build(BuildContext context) => FubaoCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
                child: Text('消息记录',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessageCenterPage(repository: repository),
                ),
              ),
              child: const Text('查看全部 ›',
                  style: TextStyle(color: FubaoColors.inkMuted, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 8),
          const _HistoryRow(
              image: FubaoIllustration.coffee,
              title: '轻松聊聊',
              text: '今天有没有一件让你觉得开心的事？',
              time: '今天 08:30'),
          const Divider(),
          const _HistoryRow(
              image: FubaoIllustration.sofa,
              title: '互相支持',
              text: '遇到小困难也没关系，我们一起想想办法吧。',
              time: '昨天 21:10'),
        ]),
      );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow(
      {required this.image,
      required this.title,
      required this.text,
      required this.time});
  final FubaoIllustration image;
  final String title;
  final String text;
  final String time;
  @override
  Widget build(BuildContext context) => Row(children: [
        FubaoIllustrationBubble(
          illustration: image,
          size: 46,
          backgroundColor: const Color(0xFFFFF4E9),
          padding: const EdgeInsets.all(3),
        ),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            Text(time,
                style:
                    const TextStyle(color: FubaoColors.inkMuted, fontSize: 10))
          ]),
          Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: FubaoColors.inkMuted, fontSize: 11)),
        ])),
      ]);
}
