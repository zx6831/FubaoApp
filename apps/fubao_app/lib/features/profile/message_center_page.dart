import 'package:flutter/material.dart';

import '../../data/fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';

class MessageCenterPage extends StatefulWidget {
  const MessageCenterPage({required this.repository, super.key});

  final FubaoRepository repository;

  @override
  State<MessageCenterPage> createState() => _MessageCenterPageState();
}

class _MessageCenterPageState extends State<MessageCenterPage> {
  AppMessageType? filter;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('消息中心'), centerTitle: true),
        body: AnimatedBuilder(
          animation: widget.repository,
          builder: (context, _) {
            final messages = widget.repository.messages
                .where((message) => filter == null || message.type == filter)
                .toList();
            return RefreshIndicator(
              onRefresh: widget.repository.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _chip(null, '全部'),
                      _chip(AppMessageType.weeklyReport, '健康周报'),
                      _chip(AppMessageType.alert, '关怀告警'),
                      _chip(AppMessageType.system, '系统消息'),
                      _chip(AppMessageType.insight, '健康知识'),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  if (messages.isEmpty)
                    const FubaoCard(
                      padding: EdgeInsets.all(28),
                      child: Column(children: [
                        Icon(Icons.mark_email_read_outlined,
                            size: 54, color: FubaoColors.mintStrong),
                        SizedBox(height: 12),
                        Text('暂时没有这类消息',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ]),
                    )
                  else
                    for (final message in messages) ...[
                      _MessageCard(
                        message: message,
                        onTap: () => widget.repository.markMessageRead(
                          message.id,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            );
          },
        ),
      );

  Widget _chip(AppMessageType? value, String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: filter == value,
          onSelected: (_) => setState(() => filter = value),
        ),
      );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.onTap});

  final AppMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FubaoCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: _color.withValues(alpha: .12),
            child: Icon(_icon, color: _color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(message.title,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  if (!message.isRead)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: FubaoColors.orangeStrong,
                        shape: BoxShape.circle,
                      ),
                    ),
                ]),
                const SizedBox(height: 5),
                Text(message.body,
                    style: const TextStyle(
                        color: FubaoColors.inkMuted, height: 1.45)),
                const SizedBox(height: 7),
                Text(_dateLabel(message.createdAt),
                    style: const TextStyle(
                        color: FubaoColors.inkMuted, fontSize: 11)),
              ],
            ),
          ),
        ]),
      );

  Color get _color => switch (message.type) {
        AppMessageType.alert => FubaoColors.orangeStrong,
        _ => FubaoColors.mintStrong,
      };

  IconData get _icon => switch (message.type) {
        AppMessageType.weeklyReport => Icons.assessment_outlined,
        AppMessageType.alert => Icons.notifications_active_outlined,
        AppMessageType.system => Icons.info_outline_rounded,
        AppMessageType.insight => Icons.lightbulb_outline_rounded,
      };

  String _dateLabel(DateTime date) =>
      '${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
