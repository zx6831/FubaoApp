import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/demo_fubao_repository.dart';
import 'package:fubao_app/design/fubao_colors.dart';
import 'package:fubao_app/design/fubao_theme.dart';
import 'package:fubao_app/features/child/child_plans_page.dart';
import 'package:fubao_app/features/child/child_home_page.dart';
import 'package:fubao_app/features/child/child_profile_page.dart';
import 'package:fubao_app/features/child/child_topics_page.dart';
import 'package:fubao_app/features/child/create_plan_page.dart';
import 'package:fubao_app/features/elder/elder_plans_page.dart';
import 'package:fubao_app/widgets/fubao_widgets.dart';

void main() {
  Future<void> pumpPhonePage(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFubaoTheme(),
        home: Scaffold(body: page),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('child plans title is centered on the screen', (tester) async {
    await pumpPhonePage(
      tester,
      ChildPlansPage(repository: DemoFubaoRepository()),
    );

    final titleCenter = tester.getCenter(find.text('计划')).dx;
    expect((titleCenter - 195).abs(), lessThanOrEqualTo(1));
  });

  testWidgets('child topics removes the logo and centers its title',
      (tester) async {
    await pumpPhonePage(
      tester,
      ChildTopicsPage(repository: DemoFubaoRepository()),
    );

    expect(find.byType(BrandMark), findsNothing);
    final titleCenter = tester.getCenter(find.text('话题')).dx;
    expect((titleCenter - 195).abs(), lessThanOrEqualTo(1));
  });

  testWidgets('device online state uses a separate green status dot',
      (tester) async {
    await pumpPhonePage(
      tester,
      ChildProfilePage(onLogout: () async {}),
    );

    final dot = find.byKey(const Key('device-online-dot'));
    expect(dot, findsOneWidget);
    final decoration =
        tester.widget<Container>(dot).decoration! as BoxDecoration;
    expect(decoration.color, FubaoColors.mintStrong);
    expect(decoration.shape, BoxShape.circle);
    expect(find.text('设备在线'), findsOneWidget);
  });

  testWidgets('Chinese button labels use the bundled font', (tester) async {
    await pumpPhonePage(tester, const CreatePlanPage());

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('下一步'),
        matching: find.byType(FilledButton),
      ),
    );
    final textStyle = button.style?.textStyle?.resolve(<WidgetState>{});
    expect(textStyle?.fontFamily, 'NotoSansSC');
  });

  testWidgets('task times use clock icons instead of unsupported glyphs',
      (tester) async {
    await pumpPhonePage(
      tester,
      ChildHomePage(repository: DemoFubaoRepository()),
    );
    expect(find.textContaining('◷'), findsNothing);
    expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);

    await pumpPhonePage(
      tester,
      ElderPlansPage(repository: DemoFubaoRepository()),
    );
    expect(find.textContaining('◷'), findsNothing);
    expect(find.byIcon(Icons.access_time_rounded), findsAtLeastNWidgets(1));
  });
}
