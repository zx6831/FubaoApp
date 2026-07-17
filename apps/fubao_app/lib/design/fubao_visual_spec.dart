import 'package:flutter/widgets.dart';

@immutable
class FubaoRoleVisualSpec {
  const FubaoRoleVisualSpec({
    required this.pagePadding,
    required this.cardRadius,
    required this.minimumTapTarget,
    required this.pageTitleSize,
    required this.bodySize,
    required this.navigationHeight,
  });

  static const child = FubaoRoleVisualSpec(
    pagePadding: 18,
    cardRadius: 22,
    minimumTapTarget: 44,
    pageTitleSize: 25,
    bodySize: 14,
    navigationHeight: 78,
  );

  static const elder = FubaoRoleVisualSpec(
    pagePadding: 20,
    cardRadius: 28,
    minimumTapTarget: 64,
    pageTitleSize: 38,
    bodySize: 21,
    navigationHeight: 92,
  );

  final double pagePadding;
  final double cardRadius;
  final double minimumTapTarget;
  final double pageTitleSize;
  final double bodySize;
  final double navigationHeight;
}
