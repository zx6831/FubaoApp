import 'package:flutter/material.dart';

import '../../design/fubao_colors.dart';
import '../../design/fubao_illustrations.dart';
import '../../widgets/fubao_widgets.dart';

class ElderProfilePage extends StatelessWidget {
  const ElderProfilePage({required this.onSwitchRole, super.key});
  final VoidCallback onSwitchRole;

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
                    height: 205,
                    fit: BoxFit.cover)),
            const SizedBox(height: 4),
            const _ElderMenuItem(
                icon: Icons.folder_special_rounded,
                title: '我的健康档案',
                color: FubaoColors.mintStrong),
            const SizedBox(height: 10),
            const _ElderMenuItem(
                icon: Icons.text_fields_rounded,
                title: '字体大小',
                color: FubaoColors.mintStrong),
            const SizedBox(height: 10),
            const _ElderMenuItem(
                icon: Icons.volume_up_rounded,
                title: '朗读设置',
                color: FubaoColors.mintStrong),
            const SizedBox(height: 10),
            const _ElderMenuItem(
                icon: Icons.alarm_rounded,
                title: '提醒时间',
                color: FubaoColors.orangeStrong),
            const SizedBox(height: 10),
            const _ElderMenuItem(
                icon: Icons.groups_rounded,
                title: '联系家人',
                color: FubaoColors.mintStrong),
            const SizedBox(height: 16),
            _ElderMenuItem(
                icon: Icons.power_settings_new_rounded,
                title: '退出家庭组',
                color: FubaoColors.orangeStrong,
                onTap: onSwitchRole),
          ],
        ),
      );
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
          if (title != '退出家庭组')
            const Icon(Icons.chevron_right_rounded,
                color: FubaoColors.inkMuted, size: 36),
        ]),
      );
}
