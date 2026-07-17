import 'package:flutter/material.dart';

import '../../design/fubao_colors.dart';
import '../../design/fubao_illustrations.dart';
import '../../widgets/fubao_widgets.dart';
import '../profile/profile_settings_page.dart';

class ElderProfilePage extends StatelessWidget {
  const ElderProfilePage({required this.onLogout, required this.onLeaveFamily, super.key});
  final Future<void> Function() onLogout;
  final Future<void> Function() onLeaveFamily;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
          children: [
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('王阿姨',
                        style: TextStyle(
                            fontSize: 42, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Row(children: [
                      Flexible(
                          child: Text('今天也要照顾好自己',
                              style: TextStyle(
                                  color: FubaoColors.inkMuted,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700))),
                      SizedBox(width: 8),
                      Icon(Icons.favorite_rounded,
                          color: FubaoColors.orangeStrong),
                    ]),
                  ])),
              ReadAloudButton(text: '王阿姨，今天也要照顾好自己。'),
            ]),
            const SizedBox(height: 10),
            const Center(
                child: FubaoIllustrationAsset(
                    FubaoIllustration.elderProfileMascot,
                    width: 250,
                    height: 205)),
            const SizedBox(height: 4),
            _ElderMenuItem(
                icon: Icons.folder_special_rounded,
                title: '我的健康档案',
                color: FubaoColors.mintStrong,
                onTap: () => _open(context, ProfileSettingKind.health)),
            const SizedBox(height: 10),
            _ElderMenuItem(
                icon: Icons.text_fields_rounded,
                title: '字体大小',
                color: FubaoColors.mintStrong,
                onTap: () => _open(context, ProfileSettingKind.font)),
            const SizedBox(height: 10),
            _ElderMenuItem(
                icon: Icons.volume_up_rounded,
                title: '朗读设置',
                color: FubaoColors.mintStrong,
                onTap: () => _open(context, ProfileSettingKind.reading)),
            const SizedBox(height: 10),
            _ElderMenuItem(
                icon: Icons.alarm_rounded,
                title: '提醒时间',
                color: FubaoColors.orangeStrong,
                onTap: () => _open(context, ProfileSettingKind.reminder)),
            const SizedBox(height: 10),
            _ElderMenuItem(
                icon: Icons.groups_rounded,
                title: '联系家人',
                color: FubaoColors.mintStrong,
                onTap: () => _open(context, ProfileSettingKind.contact)),
            const SizedBox(height: 16),
            _ElderMenuItem(
                icon: Icons.logout_rounded,
                title: '退出登录',
                color: FubaoColors.mintDeep,
                onTap: () => _confirmLogout(context)),
            const SizedBox(height: 10),
            _ElderMenuItem(
                icon: Icons.power_settings_new_rounded,
                title: '退出家庭组',
                color: FubaoColors.orangeStrong,
                onTap: () => _confirmLeave(context)),
          ],
        ),
      );

  void _open(BuildContext context, ProfileSettingKind kind) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileSettingsPage(kind: kind, elder: true)));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('退出登录？'), content: const Text('将返回手机号登录页面，但不会退出家庭组。'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('退出登录'))])) ?? false;
    if (confirmed) await onLogout();
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('退出家庭组？'), content: const Text('退出后将无法查看当前家庭任务，并返回输入邀请码页面。账号仍保持登录。'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')), FilledButton(style: FilledButton.styleFrom(backgroundColor: FubaoColors.orangeStrong), onPressed: () => Navigator.pop(context, true), child: const Text('退出家庭组'))])) ?? false;
    if (confirmed) await onLeaveFamily();
  }
}

class _ElderMenuItem extends StatelessWidget {
  const _ElderMenuItem(
      {required this.icon,
      required this.title,
      required this.color,
      this.onTap});
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => FubaoCard(
        onTap: onTap ?? () {},
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
                color: FubaoColors.mintSoft, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(width: 18),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 25, fontWeight: FontWeight.w800))),
          if (title != '退出家庭组' && title != '退出登录')
            const Icon(Icons.chevron_right_rounded,
                color: FubaoColors.inkMuted, size: 36),
        ]),
      );
}
