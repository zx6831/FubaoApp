import 'package:flutter/material.dart';

import '../../design/fubao_colors.dart';
import '../../widgets/fubao_widgets.dart';

class ChildProfilePage extends StatelessWidget {
  const ChildProfilePage({required this.onSwitchRole, super.key});

  final VoidCallback onSwitchRole;

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
                Row(children: [
                  Icon(Icons.notifications_none_rounded),
                  SizedBox(width: 18),
                  Icon(Icons.settings_outlined)
                ])
              ]),
          const EmptySpacer(height: 24),
          FubaoCard(
            child: Row(
              children: [
                const FubaoIconBubble(
                    icon: Icons.pets_rounded,
                    color: FubaoColors.mintStrong,
                    size: 82),
                const SizedBox(width: 18),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('小雨',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 5),
                      const Text('关怀妈妈的第 12 天'),
                      const SizedBox(height: 6),
                      const Row(children: [
                        Icon(Icons.circle,
                            size: 10, color: FubaoColors.mintStrong),
                        SizedBox(width: 6),
                        Text('设备在线')
                      ])
                    ])),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const EmptySpacer(height: 14),
          const FubaoCard(
              color: FubaoColors.mintSoft,
              child: Row(children: [
                FubaoIconBubble(
                    icon: Icons.auto_awesome_rounded,
                    color: FubaoColors.mintStrong,
                    size: 64),
                SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('我的成就',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      SizedBox(height: 5),
                      Text('已连续互动 12 天'),
                      Text('坚持关心，让爱每天都在发光')
                    ]))
              ])),
          const EmptySpacer(height: 14),
          _MenuGroup(items: const [
            ('家庭成员', Icons.group_rounded, FubaoColors.mintStrong),
            ('健康档案', Icons.folder_shared_rounded, FubaoColors.orangeStrong),
            ('设备管理', Icons.watch_rounded, FubaoColors.mintStrong),
          ]),
          const EmptySpacer(height: 14),
          _MenuGroup(items: const [
            (
              '提醒与勿扰',
              Icons.notifications_active_rounded,
              FubaoColors.orangeStrong
            ),
            ('隐私与数据', Icons.lock_rounded, FubaoColors.mintStrong),
            ('帮助与反馈', Icons.chat_rounded, FubaoColors.orangeStrong),
          ]),
          const EmptySpacer(height: 16),
          TextButton.icon(
              onPressed: onSwitchRole,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('切换体验角色')),
          const EmptySpacer(height: 12),
          const SafetyNote(),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});
  final List<(String, IconData, Color)> items;

  @override
  Widget build(BuildContext context) {
    return FubaoCard(
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: FubaoIconBubble(
                  icon: items[index].$2, color: items[index].$3, size: 46),
              title: Text(items[index].$1,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${items[index].$1}功能已打开'))),
            ),
            if (index < items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
