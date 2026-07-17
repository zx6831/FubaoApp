import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/auth_session.dart';
import 'package:fubao_app/data/remote_api_client.dart';
import 'package:fubao_app/data/remote_app_controller.dart';
import 'package:fubao_app/data/session_store.dart';
import 'package:fubao_app/domain/models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  http.Response jsonResponse(Map<String, dynamic> body, int status) =>
      http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Map<String, dynamic> sessionJson(String access, String refresh) => {
        'accessToken': access,
        'accessTokenExpiresAt': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
        'refreshToken': refresh,
        'refreshTokenExpiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'user': {'id': 'child-1', 'role': 'child', 'nickname': '小雨'},
      };

  test('restores the saved session and rotates tokens after a 401', () async {
    final store = MemorySessionStore()
      ..value = AuthSession.fromJson(sessionJson('expired-access', 'refresh-1'));
    var familyRequests = 0;
    String? seenRefreshToken;
    final client = RemoteApiClient(
      baseUrl: 'http://localhost:3000/api/',
      sessionStore: store,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          seenRefreshToken = jsonDecode(request.body)['refreshToken'] as String?;
          return jsonResponse({'code': 0, 'msg': 'success', 'data': sessionJson('fresh-access', 'refresh-2')}, 200);
        }
        familyRequests++;
        if (familyRequests == 1) {
          expect(request.headers['Authorization'], 'Bearer expired-access');
          return jsonResponse({'code': 401, 'msg': 'expired', 'data': null}, 401);
        }
        expect(request.headers['Authorization'], 'Bearer fresh-access');
        return jsonResponse({'code': 0, 'msg': 'success', 'data': {'id': 'family-1'}}, 200);
      }),
    );

    await client.restoreSession();
    final family = await client.get('families/current');

    expect(family['id'], 'family-1');
    expect(store.value?.refreshToken, 'refresh-2');
    expect(seenRefreshToken, 'refresh-1');
    expect(familyRequests, 2);
  });

  test('memory store round-trips a session for browser debugging', () async {
    final store = MemorySessionStore();
    final session = AuthSession.fromJson(sessionJson('access', 'refresh'));
    await store.write(session);
    expect((await store.read())?.role, AppRole.child);
    await store.clear();
    expect(await store.read(), isNull);
  });

  test('child remains in family setup until an elder has joined', () async {
    final store = MemorySessionStore()
      ..value = AuthSession.fromJson(sessionJson('access', 'refresh'));
    final client = RemoteApiClient(
      baseUrl: 'http://localhost:3000/api',
      sessionStore: store,
      httpClient: MockClient((request) async => jsonResponse({
            'code': 0,
            'msg': 'success',
            'data': {
              'id': 'family-1',
              'members': [
                {'userId': 'child-1', 'role': 'child', 'nickname': '小雨'},
              ],
            },
          }, 200)),
    );
    final controller = RemoteAppController(client);

    await controller.initialize();

    expect(controller.state, RemoteFlowState.familySetup);
    controller.dispose();
  });

  test('leaving a family keeps the elder session active', () async {
    final elderJson = sessionJson('elder-access', 'elder-refresh')
      ..['user'] = {'id': 'elder-1', 'role': 'elder', 'nickname': '王阿姨'};
    final store = MemorySessionStore()..value = AuthSession.fromJson(elderJson);
    final client = RemoteApiClient(
      baseUrl: 'http://localhost:3000/api',
      sessionStore: store,
      httpClient: MockClient((request) async => jsonResponse({
            'code': 0,
            'msg': 'success',
            'data': {'left': true, 'sessionActive': true},
          }, 200)),
    );
    await client.restoreSession();
    final controller = RemoteAppController(client)..state = RemoteFlowState.ready;

    expect(await controller.leaveFamily(), isTrue);
    expect(controller.state, RemoteFlowState.familySetup);
    expect(store.value?.role, AppRole.elder);
    controller.dispose();
  });
}
