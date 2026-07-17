import 'package:flutter/material.dart';

import '../design/fubao_colors.dart';
import '../design/fubao_illustrations.dart';
import '../design/fubao_visual_spec.dart';
import '../domain/models.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          FubaoIllustration.brandLogo.assetPath,
          width: large ? 112 : 90,
          height: large ? 50 : 40,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class FubaoCard extends StatelessWidget {
  const FubaoCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.color = FubaoColors.card,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(26),
      side: borderColor == null
          ? BorderSide.none
          : BorderSide(color: borderColor!),
    );
    final content = Padding(padding: padding, child: child);

    return Material(
      color: color,
      elevation: 4,
      shadowColor: const Color(0x1A4A3A2E),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              child: content,
            ),
    );
  }
}

class FubaoIllustrationAsset extends StatelessWidget {
  const FubaoIllustrationAsset(
    this.illustration, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
  });

  final FubaoIllustration illustration;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      illustration.assetPath,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

class FubaoIconBubble extends StatelessWidget {
  const FubaoIconBubble({
    required this.icon,
    required this.color,
    super.key,
    this.size = 52,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title,
      {super.key, this.trailing, this.elder = false});

  final String title;
  final Widget? trailing;
  final bool elder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: elder
                ? Theme.of(context).textTheme.headlineMedium
                : Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class SparkBadge extends StatelessWidget {
  const SparkBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: FubaoColors.mintSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: FubaoColors.mintStrong),
          const SizedBox(width: 7),
          Text(
            compact ? '连续 12 天' : '已连续互动 12 天',
            style: TextStyle(
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w800,
              color: FubaoColors.mintStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyNote extends StatelessWidget {
  const SafetyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_outlined,
            size: 18, color: FubaoColors.inkMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '福豹提供健康管理与关怀提醒，不替代医生诊断和治疗。',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

IconData iconForTask(TaskKind kind) => switch (kind) {
      TaskKind.medicine => Icons.medication_rounded,
      TaskKind.bloodPressure => Icons.monitor_heart_outlined,
      TaskKind.walk => Icons.directions_walk_rounded,
      TaskKind.mood => Icons.sentiment_satisfied_alt_rounded,
    };

class FubaoBottomNavigation extends StatelessWidget {
  const FubaoBottomNavigation({
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
    this.elder = false,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool elder;

  @override
  Widget build(BuildContext context) {
    final spec = elder ? FubaoRoleVisualSpec.elder : FubaoRoleVisualSpec.child;
    const destinations = [
      (Icons.home_outlined, Icons.home_rounded, '首页'),
      (Icons.calendar_today_outlined, Icons.calendar_month_rounded, '计划'),
      (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, '话题'),
      (Icons.person_outline_rounded, Icons.person_rounded, '我的'),
    ];

    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: const Color(0x1A4A3A2E),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SizedBox(
        key: const Key('fubao-bottom-navigation'),
        height: spec.navigationHeight,
        child: Row(
          children: [
            for (var index = 0; index < destinations.length; index++)
              Expanded(
                child: _FubaoNavigationItem(
                  icon: destinations[index].$1,
                  selectedIcon: destinations[index].$2,
                  label: destinations[index].$3,
                  selected: index == currentIndex,
                  elder: elder,
                  onTap: () => onDestinationSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FubaoNavigationItem extends StatelessWidget {
  const _FubaoNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.elder,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool elder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? FubaoColors.mintStrong : FubaoColors.inkMuted;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Flutter Web can briefly lay out at a sub-pixel viewport while
            // Chrome applies a responsive-size override. Avoid rendering the
            // full navigation label until a meaningful tap area exists.
            if (constraints.maxWidth < 44 || constraints.maxHeight < 44) {
              return const SizedBox.expand();
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? selectedIcon : icon,
                    color: color, size: elder ? 33 : 27),
                SizedBox(height: elder ? 3 : 2),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: elder ? 16 : 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 18 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: FubaoColors.mintStrong,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ReadAloudButton extends StatelessWidget {
  const ReadAloudButton({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '点击朗读本页内容',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('朗读内容：$text')),
          );
        },
        child: Container(
          constraints: const BoxConstraints(minWidth: 72, minHeight: 72),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [FubaoColors.mint, FubaoColors.mintStrong],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2445C38F),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.volume_up_rounded,
              color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

class EmptySpacer extends StatelessWidget {
  const EmptySpacer({super.key, this.height = 16});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}
