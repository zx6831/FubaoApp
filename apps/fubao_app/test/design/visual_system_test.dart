import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/design/fubao_illustrations.dart';
import 'package:fubao_app/design/fubao_visual_spec.dart';
import 'package:fubao_app/widgets/fubao_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('role specs protect child and elder touch targets', () {
    expect(FubaoRoleVisualSpec.child.minimumTapTarget, 44);
    expect(FubaoRoleVisualSpec.elder.minimumTapTarget, 64);
    expect(
      FubaoRoleVisualSpec.elder.pageTitleSize,
      greaterThan(FubaoRoleVisualSpec.child.pageTitleSize),
    );
  });

  test('every approved illustration is bundled locally', () async {
    for (final illustration in FubaoIllustration.values) {
      final data = await rootBundle.load(illustration.assetPath);
      expect(data.lengthInBytes, greaterThan(100));
    }
  });

  test('every raster illustration is high-resolution with transparent corners',
      () async {
    for (final illustration in FubaoIllustration.values) {
      final data = await rootBundle.load(illustration.assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      expect(
        image.width,
        greaterThanOrEqualTo(1024),
        reason: '${illustration.name} must have a 1024px master width',
      );
      expect(
        image.height,
        greaterThanOrEqualTo(1024),
        reason: '${illustration.name} must have a 1024px master height',
      );
      expect(rgba, isNotNull);

      final bytes = rgba!.buffer.asUint8List();
      final cornerAlphaOffsets = [
        3,
        (image.width - 1) * 4 + 3,
        (image.height - 1) * image.width * 4 + 3,
        (image.width * image.height - 1) * 4 + 3,
      ];
      for (final offset in cornerAlphaOffsets) {
        expect(
          bytes[offset],
          0,
          reason: '${illustration.name} must have transparent corners',
        );
      }

      image.dispose();
      codec.dispose();
    }
  });

  testWidgets('custom navigation replaces Material NavigationBar',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FubaoBottomNavigation(
            currentIndex: 0,
            onDestinationSelected: _ignoreSelection,
          ),
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const Key('fubao-bottom-navigation')), findsOneWidget);
    expect(
        tester.getSize(find.byKey(const Key('fubao-bottom-navigation'))).height,
        78);
  });

  testWidgets('elder navigation uses the larger role height', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FubaoBottomNavigation(
            currentIndex: 0,
            elder: true,
            onDestinationSelected: _ignoreSelection,
          ),
        ),
      ),
    );

    expect(
        tester.getSize(find.byKey(const Key('fubao-bottom-navigation'))).height,
        92);
  });

  testWidgets('navigation tolerates the transient tiny Web viewport',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 1,
            height: 1,
            child: FubaoBottomNavigation(
              currentIndex: 0,
              elder: true,
              onDestinationSelected: _ignoreSelection,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

void _ignoreSelection(int _) {}
