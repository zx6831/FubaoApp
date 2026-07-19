import 'package:flutter/material.dart';

import '../design/fubao_colors.dart';
import '../design/fubao_illustrations.dart';
import '../data/speech_service.dart';
import '../design/fubao_visual_spec.dart';
import '../domain/models.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    final iconSize = large ? 42.0 : 34.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size.square(iconSize),
          painter: const _FubaoCatMarkPainter(),
        ),
        SizedBox(width: large ? 8 : 6),
        Text(
          '福豹',
          style: TextStyle(
            color: FubaoColors.ink,
            fontSize: large ? 29 : 24,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

class _FubaoCatMarkPainter extends CustomPainter {
  const _FubaoCatMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 34;
    final mintPaint = Paint()..color = FubaoColors.mint;
    final mintStrongPaint = Paint()..color = FubaoColors.mintStrong;
    final creamPaint = Paint()..color = const Color(0xFFF9FFF9);
    final inkPaint = Paint()
      ..color = const Color(0xFF31584A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65 * scale
      ..strokeCap = StrokeCap.round;

    final leftEar = Path()
      ..moveTo(5 * scale, 12 * scale)
      ..lineTo(5.8 * scale, 4.3 * scale)
      ..quadraticBezierTo(6.1 * scale, 2.7 * scale, 7.8 * scale, 4 * scale)
      ..lineTo(12.4 * scale, 7.1 * scale)
      ..close();
    final rightEar = Path()
      ..moveTo(21.6 * scale, 7.1 * scale)
      ..lineTo(26.2 * scale, 4 * scale)
      ..quadraticBezierTo(27.9 * scale, 2.7 * scale, 28.2 * scale, 4.3 * scale)
      ..lineTo(29 * scale, 12 * scale)
      ..close();
    canvas.drawPath(leftEar, mintPaint);
    canvas.drawPath(rightEar, mintPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3.5 * scale, 6 * scale, 27 * scale, 25 * scale),
        Radius.circular(11 * scale),
      ),
      mintPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(17 * scale, 20.5 * scale),
        width: 22 * scale,
        height: 15.5 * scale,
      ),
      creamPaint,
    );
    canvas.drawCircle(
        Offset(12 * scale, 16.2 * scale), 1.2 * scale, mintStrongPaint);
    canvas.drawCircle(
        Offset(22 * scale, 16.2 * scale), 1.2 * scale, mintStrongPaint);
    canvas.drawCircle(
        Offset(17 * scale, 20.1 * scale), 1.15 * scale, mintStrongPaint);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(17 * scale, 21.3 * scale),
        width: 7.5 * scale,
        height: 5.5 * scale,
      ),
      0.18,
      2.78,
      false,
      inkPaint,
    );
    canvas.drawLine(Offset(7.2 * scale, 21 * scale),
        Offset(12.1 * scale, 21.9 * scale), inkPaint);
    canvas.drawLine(Offset(21.9 * scale, 21.9 * scale),
        Offset(26.8 * scale, 21 * scale), inkPaint);
  }

  @override
  bool shouldRepaint(covariant _FubaoCatMarkPainter oldDelegate) => false;
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

class FubaoIllustrationBubble extends StatelessWidget {
  const FubaoIllustrationBubble({
    required this.illustration,
    required this.size,
    super.key,
    this.backgroundColor = FubaoColors.mintSoft,
    this.padding = const EdgeInsets.all(7),
    this.circular = true,
  });

  final FubaoIllustration illustration;
  final double size;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final bool circular;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: circular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circular ? null : BorderRadius.circular(size * .24),
        ),
        child: FubaoIllustrationAsset(illustration),
      );
}

class CenteredPageHeader extends StatelessWidget {
  const CenteredPageHeader({
    required this.title,
    super.key,
    this.leading,
    this.trailing,
    this.titleStyle,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (leading != null)
              Align(alignment: Alignment.centerLeft, child: leading),
            Text(
              title,
              key: Key('page-title-$title'),
              maxLines: 1,
              style: titleStyle ??
                  const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
            if (trailing != null)
              Align(alignment: Alignment.centerRight, child: trailing),
          ],
        ),
      );
}

class FubaoProgressRing extends StatelessWidget {
  const FubaoProgressRing({
    required this.value,
    required this.label,
    super.key,
    this.size = 76,
    this.strokeWidth = 8,
  });

  final double value;
  final String label;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
        key: const Key('fubao-progress-ring'),
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              color: FubaoColors.mintStrong,
              backgroundColor: FubaoColors.mintSoft,
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.all(strokeWidth + 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: FubaoColors.mintStrong,
                      fontSize: 21,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
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
  const SparkBadge({required this.spark, super.key, this.compact = false});

  final FamilySpark spark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: compact ? const Key('compact-spark-badge') : null,
      constraints:
          compact ? const BoxConstraints(minHeight: 38, maxHeight: 38) : null,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 16,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: spark.lit ? FubaoColors.mintSoft : const Color(0xFFF0F1F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded,
              color: spark.lit ? FubaoColors.mintStrong : FubaoColors.inkMuted,
              size: compact ? 18 : 24),
          SizedBox(width: compact ? 5 : 7),
          Text(
            spark.lit
                ? compact
                    ? '连续 ${spark.streakDays} 天'
                    : '已连续互动 ${spark.streakDays} 天'
                : '今日火花未点亮',
            style: TextStyle(
              fontSize: compact ? 14 : 17,
              height: 1,
              fontWeight: FontWeight.w800,
              color: spark.lit ? FubaoColors.mintStrong : FubaoColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class SparkIllustration extends StatelessWidget {
  const SparkIllustration({
    required this.spark,
    super.key,
    this.width,
    this.height,
  });

  final FamilySpark spark;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return FubaoIllustrationAsset(
      spark.lit ? FubaoIllustration.spark : FubaoIllustration.sparkUnlit,
      width: width,
      height: height,
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
      TaskKind.bloodGlucose => Icons.bloodtype_outlined,
      TaskKind.walk => Icons.directions_walk_rounded,
      TaskKind.mood => Icons.sentiment_satisfied_alt_rounded,
      TaskKind.weight => Icons.monitor_weight_outlined,
      TaskKind.custom => Icons.fact_check_outlined,
    };

/// Shared task-to-illustration mapping for both family roles.
FubaoIllustration illustrationForTask(TaskKind kind) => switch (kind) {
      TaskKind.medicine => FubaoIllustration.pill,
      TaskKind.bloodPressure => FubaoIllustration.elderBloodPressureDevice,
      TaskKind.bloodGlucose => FubaoIllustration.planClipboard,
      TaskKind.walk => FubaoIllustration.elderPark,
      TaskKind.mood => FubaoIllustration.elderMood,
      TaskKind.weight => FubaoIllustration.planClipboard,
      TaskKind.custom => FubaoIllustration.pencil,
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
  const ReadAloudButton({required this.text, this.rate = 0.5, super.key});

  final String text;
  final double rate;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '点击朗读本页内容',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () async {
          final speaking = await SpeechService().speak(text, rate: rate);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(speaking ? '正在朗读' : '当前调试平台不支持系统朗读，请在 iPhone 上体验。'),
            ),
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
