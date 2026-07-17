import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/app/app_config.dart';

void main() {
  test('demo is the safe default environment', () {
    final config = AppConfig.fromValues();

    expect(config.environment, AppEnvironment.demo);
    expect(config.usesRemoteApi, isFalse);
  });

  test('production requires an HTTPS API endpoint', () {
    expect(
      () => AppConfig.fromValues(
        environmentName: 'production',
        apiBaseUrl: 'http://api.example.test',
      ),
      throwsArgumentError,
    );

    final config = AppConfig.fromValues(
      environmentName: 'production',
      apiBaseUrl: 'https://api.example.test',
    );
    expect(config.usesRemoteApi, isTrue);
  });
}
