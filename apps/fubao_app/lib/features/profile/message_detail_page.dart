import 'package:flutter/material.dart';

import '../../design/fubao_colors.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';

class MessageDetailPage extends StatelessWidget {
  const MessageDetailPage({
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.icon = Icons.chat_bubble_outline_rounded,
    this.accent = FubaoColors.mintStrong,
    super.key,
  });

  factory MessageDetailPage.fromMessage(AppMessage message) =>
      MessageDetailPage(
        title: message.title,
        body: message.body,
        category: switch (message.type) {
          AppMessageType.weeklyReport => '健康周报',
          AppMessageType.alert => '关怀告警',
          AppMessageType.system => '系统消息',
          AppMessageType.insight => '健康知识',
        },
        createdAt: message.createdAt,
        icon: switch (message.type) {
          AppMessageType.weeklyReport => Icons.assessment_outlined,
          AppMessageType.alert => Icons.notifications_active_outlined,
          AppMessageType.system => Icons.info_outline_rounded,
          AppMessageType.insight => Icons.lightbulb_outline_rounded,
        },
        accent: message.type == AppMessageType.alert
            ? FubaoColors.orangeStrong
            : FubaoColors.mintStrong,
      );

  final String title;
  final String body;
  final String category;
  final DateTime createdAt;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('消息详情'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FubaoCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: accent.withValues(alpha: .12),
                      child: Icon(icon, color: accent, size: 29),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category,
                              style: TextStyle(
                                  color: accent, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(_dateLabel(createdAt),
                              style: const TextStyle(
                                  color: FubaoColors.inkMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  Text(body,
                      style: const TextStyle(fontSize: 17, height: 1.75)),
                ],
              ),
            ),
          ],
        ),
      );

  String _dateLabel(DateTime date) =>
      '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
