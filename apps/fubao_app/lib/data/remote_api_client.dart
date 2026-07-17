import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_session.dart';
import 'session_store.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class RemoteApiClient {
  RemoteApiClient({
    required String baseUrl,
    required SessionStore sessionStore,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
        _sessionStore = sessionStore,
        _http = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  final String _baseUrl;
  final SessionStore _sessionStore;
  final http.Client _http;
  final bool _ownsHttpClient;
  AuthSession? _session;

  AuthSession? get session => _session;

  Future<AuthSession?> restoreSession() async {
    _session = await _sessionStore.read();
    if (_session != null &&
        _session!.refreshTokenExpiresAt.isBefore(DateTime.now())) {
      await clearSession();
    }
    return _session;
  }

  Future<Map<String, dynamic>> get(String path, {bool authenticated = true}) =>
      _request('GET', path, authenticated: authenticated);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
    Map<String, String>? headers,
  }) =>
      _request('POST', path,
          body: body, authenticated: authenticated, extraHeaders: headers);

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) =>
      _request('PUT', path, body: body, authenticated: true);

  Future<Map<String, dynamic>> patch(String path,
          {Map<String, dynamic>? body}) =>
      _request('PATCH', path, body: body, authenticated: true);

  Future<Map<String, dynamic>> delete(String path) =>
      _request('DELETE', path, authenticated: true);

  Future<void> saveSession(Map<String, dynamic> json) async {
    _session = AuthSession.fromJson(json);
    await _sessionStore.write(_session!);
  }

  Future<void> clearSession() async {
    _session = null;
    await _sessionStore.clear();
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
    bool mayRefresh = true,
    Map<String, String>? extraHeaders,
  }) async {
    if (authenticated && _session == null) {
      throw const ApiException(401, '请先登录');
    }
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      headers['Authorization'] = 'Bearer ${_session!.accessToken}';
    }
    if (extraHeaders != null) headers.addAll(extraHeaders);
    final uri = Uri.parse('$_baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}');
    final encodedBody = jsonEncode(body ?? const {});
    final response = switch (method) {
      'GET' => await _http.get(uri, headers: headers),
      'PUT' => await _http.put(uri, headers: headers, body: encodedBody),
      'PATCH' => await _http.patch(uri, headers: headers, body: encodedBody),
      'DELETE' => await _http.delete(uri, headers: headers),
      _ => await _http.post(uri, headers: headers, body: encodedBody),
    };

    if (response.statusCode == 401 &&
        authenticated &&
        mayRefresh &&
        _session != null) {
      final refreshed = await _refreshSession();
      if (refreshed) {
        return _request(
          method,
          path,
          body: body,
          authenticated: true,
          mayRefresh: false,
          extraHeaders: extraHeaders,
        );
      }
    }

    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(response.statusCode, '服务器返回了无法识别的内容');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        envelope['code'] != 0) {
      throw ApiException(
          response.statusCode, envelope['msg']?.toString() ?? '请求失败');
    }
    return (envelope['data'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<bool> _refreshSession() async {
    try {
      final data = await post(
        'auth/refresh',
        body: {'refreshToken': _session!.refreshToken},
        authenticated: false,
      );
      await saveSession(data);
      return true;
    } on ApiException {
      await clearSession();
      return false;
    } on http.ClientException {
      await clearSession();
      return false;
    }
  }

  void dispose() {
    if (_ownsHttpClient) _http.close();
  }
}
