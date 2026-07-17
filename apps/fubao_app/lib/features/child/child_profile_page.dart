import 'package:flutter/material.dart';

import '../../design/fubao_colors.dart';
import '../../design/fubao_illustrations.dart';
import '../../widgets/fubao_widgets.dart';

class ChildProfilePage extends StatelessWidget {
  const ChildProfilePage({required this.onSwitchRole, super.key});
  final VoidCallback onSwitchRole;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            const Row(children: [
              BrandMark(),
              Spacer(),
              _ProfileAction(Icons.notifications_none_rounded),
              SizedBox(width: 10),
              _ProfileAction(Icons.settings_outlined),
            ]),
            const SizedBox(height: 16),
            FubaoCard(
              borderColor: const Color(0xFFF2E5D9),
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const FubaoIllustrationBubble(
                  illustration: FubaoIllustration.mascotAvatar,
                  size: 108,
                  backgroundColor: Color(0xFFFFF1DF),
                  padding: EdgeInsets.all(2),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('小雨',
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.w900)),
                      SizedBox(height: 8),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: '关怀妈妈的第 '),
                        TextSpan(
                            text: '12',
                            style: TextStyle(
                                color: FubaoColors.mintStrong,
                                fontWeight: FontWeight.w900)),
                        TextSpan(text: ' 天')
                      ])),
                      SizedBox(height: 8),
                      Row(children: [
                        Container(
                          key: Key('device-online-dot'),
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: FubaoColors.mintStrong,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 7),
                        Text('设备在线',
                            style: TextStyle(
                                color: FubaoColors.inkMuted, fontSize: 12)),
                      ]),
                    ])),
                const Icon(Icons.chevron_right_rounded,
                    color: FubaoColors.inkMuted),
              ]),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFF0FAF6), Color(0xFFFAFDFB)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: FubaoColors.borderMint),
              ),
              child: const Row(children: [
                FubaoIllustrationAsset(FubaoIllustration.spark,
                    width: 130, height: 100),
                SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('我的成就',
                          style: TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w900)),
                      SizedBox(height: 6),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: '已连续互动 '),
                        TextSpan(
                            text: '12',
                            style: TextStyle(
                                color: FubaoColors.mintStrong,
                                fontWeight: FontWeight.w900)),
                        TextSpan(text: ' 天')
                      ])),
                      SizedBox(height: 5),
                      Text('坚持关心，让爱每天都在发光',
                          style: TextStyle(
                              color: FubaoColors.inkMuted, fontSize: 11)),
                    ])),
              ]),
            ),
            const SizedBox(height: 14),
            const _SettingsGroup(items: [
              (Icons.groups_rounded, '家庭成员', FubaoColors.mintStrong),
              (Icons.folder_copy_rounded, '健康档案', FubaoColors.orangeStrong),
              (Icons.watch_rounded, '设备管理', FubaoColors.mintStrong),
            ]),
            const SizedBox(height: 12),
            const _SettingsGroup(items: [
              (
                Icons.notifications_active_rounded,
                '提醒与勿扰',
                FubaoColors.orangeStrong
              ),
              (Icons.shield_rounded, '隐私与数据', FubaoColors.mintStrong),
              (Icons.chat_bubble_rounded, '帮助与反馈', FubaoColors.orangeStrong),
            ]),
            const SizedBox(height: 12),
            InkWell(
              onTap: onSwitchRole,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF4FBF7),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: FubaoColors.borderMint)),
                child: const Row(children: [
                  FubaoIllustrationAsset(FubaoIllustration.plants,
                      width: 86, height: 62),
                  SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('一起成长的小约定',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('每天进步一点点，我们都很棒！',
                            style: TextStyle(
                                color: FubaoColors.inkMuted, fontSize: 11)),
                      ])),
                  Icon(Icons.favorite_rounded, color: FubaoColors.mintStrong),
                ]),
              ),
            ),
          ],
        ),
      );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction(this.icon);
  final IconData icon;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 44, height: 44, child: Icon(icon)),
      );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});
  final List<(IconData, String, Color)> items;
  @override
  Widget build(BuildContext context) => FubaoCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              minLeadingWidth: 28,
              contentPadding: EdgeInsets.zero,
              leading: Icon(items[i].$1, color: items[i].$3),
              title: Text(items[i].$2,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: FubaoColors.inkMuted),
            ),
            if (i < items.length - 1) const Divider(height: 1),
          ],
        ]),
      );
}
