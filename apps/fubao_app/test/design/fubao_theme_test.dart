import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/design/fubao_colors.dart';
import 'package:fubao_app/design/fubao_theme.dart';

void main() {
  test('theme uses the approved mint and warm canvas', () {
    final theme = buildFubaoTheme();

    expect(theme.colorScheme.primary, FubaoColors.mint);
    expect(theme.scaffoldBackgroundColor, FubaoColors.canvas);
    expect(theme.brightness, Brightness.light);
  });
}
