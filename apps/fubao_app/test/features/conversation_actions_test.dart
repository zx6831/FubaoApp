import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/care_share_service.dart';
import 'package:fubao_app/data/demo_fubao_repository.dart';
import 'package:fubao_app/features/child/child_home_page.dart';

void main() {
  testWidgets(
      'home conversation refresh changes prompts and share has feedback',
      (tester) async {
    final repository = DemoFubaoRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChildHomePage(
          repository: repository,
          shareText: (_) async => CareShareTarget.clipboard,
        ),
      ),
    ));

    await tester.scrollUntilVisible(
      find.text('轻松聊聊'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('轻松聊聊'), findsOneWidget);
    await tester.tap(find.text('换一换'));
    await tester.pump();
    expect(find.text('散步时光'), findsOneWidget);
    expect(find.text('温暖问候'), findsOneWidget);

    await tester.ensureVisible(find.text('去聊聊').first);
    await tester.pump();
    await tester.tap(find.text('去聊聊').first);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
