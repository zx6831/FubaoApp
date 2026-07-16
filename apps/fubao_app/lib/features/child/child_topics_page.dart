import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/demo_fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../widgets/fubao_widgets.dart';

class ChildTopicsPage extends StatelessWidget {
  const ChildTopicsPage({required this.repository, super.key});

  final DemoFubaoRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BrandMark(),
                Text('话题',
                    style:
                        TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
                Icon(Icons.auto_awesome_rounded,
                    color: FubaoColors.orangeStrong)
              ]),
          const EmptySpacer(height: 30),
          const SectionTitle('今天适合聊一聊'),
          const EmptySpacer(height: 6),
          Text('用一句温暖的话，拉近彼此的距离',
              style: Theme.of(context).textTheme.bodyMedium),
          const EmptySpacer(height: 16),
          for (final topic in repository.topics) ...[
            FubaoCard(
              borderColor: FubaoColors.orange.withValues(alpha: 0.38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    FubaoIconBubble(
                        icon: topic.icon,
                        color: FubaoColors.orangeStrong,
                        size: 58),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Text(topic.title,
                            style: Theme.of(context).textTheme.titleLarge))
                  ]),
                  const SizedBox(height: 14),
                  Text(topic.description),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                          child: Text(topic.suggestedWords,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: topic.suggestedWords));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('话术已复制，可以去微信粘贴发送')));
                          }
                        },
                        child: const Text('复制话术'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const EmptySpacer(height: 12),
          ],
          const EmptySpacer(height: 12),
          const _WeeklyReport(),
          const EmptySpacer(height: 24),
          const SectionTitle('消息记录'),
          const EmptySpacer(height: 12),
          const FubaoCard(
            child: Column(
              children: [
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: FubaoIconBubble(
                        icon: Icons.coffee_rounded,
                        color: FubaoColors.orangeStrong),
                    title: Text('轻松聊聊'),
                    subtitle: Text('今天有没有一件让你开心的事？'),
                    trailing: Text('今天')),
                Divider(),
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: FubaoIconBubble(
                        icon: Icons.favorite_rounded,
                        color: FubaoColors.mintStrong),
                    title: Text('互相支持'),
                    subtitle: Text('遇到小困难也没关系，一起想办法。'),
                    trailing: Text('昨天')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyReport extends StatelessWidget {
  const _WeeklyReport();

  @override
  Widget build(BuildContext context) {
    return FubaoCard(
      color: FubaoColors.mintSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const FubaoIconBubble(
                icon: Icons.fact_check_rounded, color: FubaoColors.mintStrong),
            const SizedBox(width: 12),
            Text('本周健康周报', style: Theme.of(context).textTheme.titleLarge)
          ]),
          const SizedBox(height: 18),
          const Row(children: [
            Expanded(child: _ReportMetric(value: '9/12', label: '任务完成')),
            SizedBox(width: 12),
            Expanded(child: _ReportMetric(value: '12 天', label: '连续互动'))
          ]),
        ],
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: FubaoColors.mintStrong)),
        Text(label)
      ]));
}
