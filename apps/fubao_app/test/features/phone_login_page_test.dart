import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/design/fubao_theme.dart';
import 'package:fubao_app/domain/models.dart';
import 'package:fubao_app/features/auth/phone_login_page.dart';

void main() {
  testWidgets('requests a code and submits the selected role', (tester) async {
    String? requestedPhone;
    (String, String, AppRole)? verification;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFubaoTheme(),
        home: PhoneLoginPage(
          testCode: '2468',
          onRequestCode: (phone) async {
            requestedPhone = phone;
            return true;
          },
          onVerifyCode: (phone, code, role) async {
            verification = (phone, code, role);
            return true;
          },
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('phoneField')), '13800000001');
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pumpAndSettle();
    expect(requestedPhone, '13800000001');
    expect(find.text('调试验证码：2468'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('codeField')), '2468');
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pumpAndSettle();
    expect(verification, ('13800000001', '2468', AppRole.child));
  });
}
