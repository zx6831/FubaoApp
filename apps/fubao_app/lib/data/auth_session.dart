import '../domain/models.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.userId,
    required this.role,
    required this.nickname,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AuthSession(
      accessToken: json['accessToken'] as String,
      accessTokenExpiresAt: DateTime.parse(json['accessTokenExpiresAt'] as String),
      refreshToken: json['refreshToken'] as String,
      refreshTokenExpiresAt: DateTime.parse(json['refreshTokenExpiresAt'] as String),
      userId: user['id'] as String,
      role: user['role'] == 'elder' ? AppRole.elder : AppRole.child,
      nickname: user['nickname'] as String,
    );
  }

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final String userId;
  final AppRole role;
  final String nickname;

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'accessTokenExpiresAt': accessTokenExpiresAt.toIso8601String(),
        'refreshToken': refreshToken,
        'refreshTokenExpiresAt': refreshTokenExpiresAt.toIso8601String(),
        'user': {
          'id': userId,
          'role': role.name,
          'nickname': nickname,
        },
      };
}
