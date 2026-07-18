import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/demo_fubao_repository.dart';
import 'package:fubao_app/features/profile/profile_settings_page.dart';

void main() {
  testWidgets('family and health settings render repository data',
      (tester) async {
    final repository = DemoFubaoRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(MaterialApp(
      home: ProfileSettingsPage(
        key: const ValueKey('family-settings'),
        kind: ProfileSettingKind.family,
        repository: repository,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('小雨'), findsOneWidget);
    expect(find.text('王阿姨'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: ProfileSettingsPage(
        key: const ValueKey('health-settings'),
        kind: ProfileSettingKind.health,
        repository: repository,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('妈妈'), findsOneWidget);
    expect(find.text('高血压'), findsOneWidget);
    expect(find.text('162 cm / 58.5 kg'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('编辑健康档案'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('编辑健康档案'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '母亲');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect((await repository.elderHealthProfile())['relativeName'], '母亲');
  });

  testWidgets('device settings update status and unbind separately from logout',
      (tester) async {
    final repository = DemoFubaoRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(MaterialApp(
      home: ProfileSettingsPage(
        kind: ProfileSettingKind.device,
        repository: repository,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('FB-DEMO-001'), findsOneWidget);

    await tester.tap(find.text('模拟设备在线'));
    await tester.pumpAndSettle();
    expect((await repository.currentDevice())['status'], 'offline');

    await tester.scrollUntilVisible(
      find.text('解绑设备'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('解绑设备'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认解绑'));
    await tester.pumpAndSettle();
    expect((await repository.currentDevice())['status'], 'unbound');
    expect(find.textContaining('数据保留至'), findsOneWidget);
  });
}
