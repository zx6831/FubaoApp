import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/demo_fubao_repository.dart';
import 'package:fubao_app/design/fubao_colors.dart';
import 'package:fubao_app/design/fubao_theme.dart';
import 'package:fubao_app/features/child/child_home_page.dart';
import 'package:fubao_app/features/child/child_plans_page.dart';
import 'package:fubao_app/features/child/child_profile_page.dart';
import 'package:fubao_app/features/child/child_topics_page.dart';
import 'package:fubao_app/features/child/create_plan_page.dart';
import 'package:fubao_app/features/elder/elder_home_page.dart';
import 'package:fubao_app/features/elder/elder_plans_page.dart';
import 'package:fubao_app/features/elder/elder_profile_page.dart';
import 'package:fubao_app/features/elder/elder_topics_page.dart';

void main() {
  setUpAll(() async {
    final fontLoader = FontLoader('NotoSansSC')
      ..addFont(rootBundle.load('assets/fonts/NotoSansSC-VF.ttf'));
    final iconFontLoader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([fontLoader.load(), iconFontLoader.load()]);
  });

  Future<void> pumpReferencePage(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildFubaoTheme(),
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('golden-page'),
            child: ColoredBox(color: FubaoColors.canvas, child: page),
          ),
        ),
      ),
    );
    final imageElements = find.byType(Image).evaluate().toList();
    await tester.runAsync(() async {
      for (final element in imageElements) {
        final image = element.widget as Image;
        await precacheImage(image.image, element);
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> expectPage(WidgetTester tester, String name) async {
    await expectLater(
      find.byKey(const Key('golden-page')),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  group('390x844 approved-page visual baselines', () {
    testWidgets('younger home', (tester) async {
      await pumpReferencePage(
          tester, ChildHomePage(repository: DemoFubaoRepository()));
      await expectPage(tester, 'younger_home');
    });

    testWidgets('younger plans', (tester) async {
      await pumpReferencePage(
          tester, ChildPlansPage(repository: DemoFubaoRepository()));
      await expectPage(tester, 'younger_plans');
    });

    testWidgets('younger create plan', (tester) async {
      await pumpReferencePage(tester, const CreatePlanPage());
      await expectPage(tester, 'younger_create_plan');
    });

    testWidgets('younger topics', (tester) async {
      await pumpReferencePage(
          tester, ChildTopicsPage(repository: DemoFubaoRepository()));
      await expectPage(tester, 'younger_topics');
    });

    testWidgets('younger profile', (tester) async {
      await pumpReferencePage(tester, ChildProfilePage(onSwitchRole: () {}));
      await expectPage(tester, 'younger_profile');
    });

    testWidgets('elder home', (tester) async {
      await pumpReferencePage(
          tester, ElderHomePage(repository: DemoFubaoRepository()));
      await expectPage(tester, 'elder_home');
    });

    testWidgets('elder plans', (tester) async {
      await pumpReferencePage(
          tester, ElderPlansPage(repository: DemoFubaoRepository()));
      await expectPage(tester, 'elder_plans');
    });

    testWidgets('elder topics completed state', (tester) async {
      final repository = DemoFubaoRepository();
      for (final task in repository.tasks) {
        repository.setTaskCompleted(task.id, true);
      }
      await pumpReferencePage(tester, ElderTopicsPage(repository: repository));
      await expectPage(tester, 'elder_topics');
    });

    testWidgets('elder profile', (tester) async {
      await pumpReferencePage(tester, ElderProfilePage(onSwitchRole: () {}));
      await expectPage(tester, 'elder_profile');
    });
  });
}
