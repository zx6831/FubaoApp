enum AppEnvironment { demo, dev, production }

class AppConfig {
  const AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
  });

  factory AppConfig.fromValues({
    String environmentName = 'demo',
    String apiBaseUrl = '',
  }) {
    final environment = switch (environmentName.trim().toLowerCase()) {
      'demo' || '' => AppEnvironment.demo,
      'dev' => AppEnvironment.dev,
      'production' => AppEnvironment.production,
      _ => throw ArgumentError.value(
          environmentName,
          'environmentName',
          '必须是 demo、dev 或 production',
        ),
    };
    final normalizedUrl = apiBaseUrl.trim();
    if (environment != AppEnvironment.demo && normalizedUrl.isEmpty) {
      throw ArgumentError('dev 和 production 环境必须配置 API_BASE_URL');
    }
    if (environment == AppEnvironment.production &&
        !normalizedUrl.startsWith('https://')) {
      throw ArgumentError('production 环境必须使用 HTTPS API');
    }
    return AppConfig._(
      environment: environment,
      apiBaseUrl: normalizedUrl,
    );
  }

  factory AppConfig.fromDartDefines() => AppConfig.fromValues(
        environmentName:
            const String.fromEnvironment('APP_ENV', defaultValue: 'demo'),
        apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
      );

  final AppEnvironment environment;
  final String apiBaseUrl;

  bool get usesRemoteApi => environment != AppEnvironment.demo;
}
