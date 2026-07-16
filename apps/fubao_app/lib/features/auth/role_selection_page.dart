import 'package:flutter/material.dart';

import '../../design/fubao_colors.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({required this.onSelected, super.key});

  final ValueChanged<AppRole> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                      alignment: Alignment.centerLeft, child: BrandMark()),
                  const SizedBox(height: 48),
                  Text('欢迎回家',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Text(
                    '选择你的身份，进入对应的关怀空间。',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: FubaoColors.inkMuted,
                        ),
                  ),
                  const SizedBox(height: 32),
                  _RoleCard(
                    title: '我是子女',
                    subtitle: '查看健康进度，安排每日计划',
                    icon: Icons.favorite_rounded,
                    color: FubaoColors.mintStrong,
                    onTap: () => onSelected(AppRole.child),
                  ),
                  const SizedBox(height: 18),
                  _RoleCard(
                    title: '我是长辈',
                    subtitle: '轻松完成任务，记录今天状态',
                    icon: Icons.wb_sunny_rounded,
                    color: FubaoColors.orangeStrong,
                    onTap: () => onSelected(AppRole.elder),
                  ),
                  const SizedBox(height: 32),
                  const SafetyNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FubaoColors.card,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              FubaoIconBubble(icon: icon, color: color, size: 62),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}
