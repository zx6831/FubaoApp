import 'package:flutter/material.dart';

import '../../design/fubao_colors.dart';
import '../../widgets/fubao_widgets.dart';

class ElderProfilePage extends StatelessWidget {
  const ElderProfilePage({required this.onSwitchRole, super.key});

  final VoidCallback onSwitchRole;

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('我的健康档案', Icons.folder_shared_rounded, FubaoColors.mintStrong),
      ('字体大小', Icons.text_fields_rounded, FubaoColors.mintStrong),
      ('朗读设置', Icons.volume_up_rounded, FubaoColors.mintStrong),
      ('提醒时间', Icons.alarm_rounded, FubaoColors.orangeStrong),
      ('联系家人', Icons.group_rounded, FubaoColors.mintStrong),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('王阿姨',
                        style: TextStyle(
                            fontSize: 42, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('今天也要照顾好自己',
                        style: TextStyle(
                            fontSize: 23, color: FubaoColors.inkMuted))
                  ])),
              ReadAloudButton(text: '王阿姨，今天也要照顾好自己。'),
            ],
          ),
          const EmptySpacer(height: 22),
          const Center(
              child: FubaoIconBubble(
                  icon: Icons.pets_rounded,
                  color: FubaoColors.mintStrong,
                  size: 132)),
          const EmptySpacer(height: 20),
          FubaoCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  ListTile(
                    minVerticalPadding: 18,
                    contentPadding: const EdgeInsets.symmetric(vertical: 3),
                    leading: FubaoIconBubble(
                        icon: items[index].$2,
                        color: items[index].$3,
                        size: 58),
                    title: Text(items[index].$1,
                        style: const TextStyle(
                            fontSize: 25, fontWeight: FontWeight.w900)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 36),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${items[index].$1}已打开'))),
                  ),
                  if (index < items.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const EmptySpacer(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(64),
                foregroundColor: FubaoColors.inkMuted,
                textStyle:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            onPressed: onSwitchRole,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('切换体验角色'),
          ),
          const EmptySpacer(height: 10),
          TextButton.icon(
            style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                foregroundColor: FubaoColors.brick,
                textStyle:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                        title: const Text('退出家庭组？'),
                        content: const Text('退出后将无法查看家庭计划。测试版不会真正删除数据。'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('取消')),
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('我知道了'))
                        ])),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('退出家庭组'),
          ),
        ],
      ),
    );
  }
}
