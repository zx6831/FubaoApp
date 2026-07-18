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
    final editDialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: editDialog, matching: find.text('用药史')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: editDialog, matching: find.text('既往病史')),
      findsOneWidget,
    );
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
      find.text('模拟恢复出厂设置'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('模拟恢复出厂设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认恢复'));
    await tester.pumpAndSettle();
    final resetDevice = await repository.currentDevice();
    expect(resetDevice['status'], 'offline');
    expect((resetDevice['settings'] as Map)['volume'], 60);
    expect((resetDevice['settings'] as Map)['speechRate'], 50);
    expect(find.textContaining('绑定关系保持不变'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('解绑设备'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('解绑设备'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认解绑'));
    await tester.pumpAndSettle();
    final unbound = await repository.currentDevice();
    expect(unbound, {'status': 'unbound'});
    expect(find.textContaining('数据保留至'), findsOneWidget);
    expect(find.text('当前没有绑定设备'), findsOneWidget);
    expect(find.text('发现设备'), findsOneWidget);

    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('发现设备'));
    await tester.pumpAndSettle();
    expect(find.text('模拟配网并激活'), findsOneWidget);
    await tester.tap(find.text('模拟配网并激活'));
    await tester.pumpAndSettle();
    expect((await repository.currentDevice())['status'], 'online');
    expect(find.text('FB-DEMO-001'), findsOneWidget);
  });

  testWidgets('DND depends on the two independent reminder switches',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ProfileSettingsPage(kind: ProfileSettingKind.reminder),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('task-reminder-switch')));
    await tester.pump();
    expect(tester.widget<SwitchListTile>(
      find.byKey(const Key('health-reminder-switch')),
    ).value, isTrue);
    expect(tester.widget<SwitchListTile>(
      find.byKey(const Key('dnd-switch')),
    ).onChanged, isNotNull);

    await tester.tap(find.byKey(const Key('health-reminder-switch')));
    await tester.pump();
    final dnd = tester.widget<SwitchListTile>(
      find.byKey(const Key('dnd-switch')),
    );
    expect(dnd.value, isFalse);
    expect(dnd.onChanged, isNull);
    expect(find.text('开启任意一种提醒后可设置'), findsOneWidget);
  });
}
