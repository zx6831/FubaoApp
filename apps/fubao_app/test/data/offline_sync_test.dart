import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/auth_session.dart';
import 'package:fubao_app/data/local_data_store.dart';
import 'package:fubao_app/data/remote_api_client.dart';
import 'package:fubao_app/data/remote_fubao_repository.dart';
import 'package:fubao_app/data/session_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('queues an offline task once and reuses its idempotency key', () async {
    var online = true;
    var completed = false;
    final completionKeys = <String>[];
    final local = MemoryLocalDataStore();
    final sessionStore = MemorySessionStore()
      ..value = AuthSession.fromJson({
        'accessToken': 'access',
        'accessTokenExpiresAt':
            DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
        'refreshToken': 'refresh',
        'refreshTokenExpiresAt':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'user': {'id': 'elder-1', 'role': 'elder', 'nickname': '王阿姨'},
      });
    http.Response success(Map<String, dynamic> data) => http.Response.bytes(
          utf8.encode(jsonEncode({'code': 0, 'msg': 'success', 'data': data})),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
    final api = RemoteApiClient(
      baseUrl: 'http://localhost:3000/api',
      sessionStore: sessionStore,
      httpClient: MockClient((request) async {
        if (!online) throw http.ClientException('offline', request.url);
        if (request.url.path.endsWith('/tasks/task-1/complete')) {
          completionKeys.add(request.headers['idempotency-key']!);
          completed = true;
          return success({'id': 'task-1', 'status': 'completed'});
        }
        if (request.url.path.endsWith('/plans')) {
          return success({
            'items': [
              {
                'id': 'plan-1',
                'kind': 'medicine',
                'title': '晚间用药',
                'subtitle': '饭后服用',
                'status': 'active',
                'schedule': {
                  'time': '20:00',
                  'daysOfWeek': [1, 2, 3, 4, 5, 6, 7]
                },
              }
            ],
          });
        }
        if (request.url.path.endsWith('/tasks/today')) {
          return success({
            'items': [
              {
                'id': 'task-1',
                'planId': 'plan-1',
                'kind': 'medicine',
                'title': '晚间用药',
                'subtitle': '饭后服用',
                'status': completed ? 'completed' : 'pending',
              }
            ],
          });
        }
        if (request.url.path.endsWith('/sparks/current')) {
          return success({
            'lit': false,
            'streakDays': 0,
            'childActive': false,
            'elderActive': true
          });
        }
        if (request.url.path.endsWith('/reports/weekly')) {
          return success({
            'from': '2026-07-12',
            'to': '2026-07-18',
            'tasks': {'completed': 0, 'total': 1},
            'completionRate': 0
          });
        }
        return success({'items': const []});
      }),
    );
    await api.restoreSession();
    final repository = RemoteFubaoRepository(api, localStore: local);
    await repository.refresh();

    online = false;
    await repository.setTaskCompleted(
      'task-1',
      true,
      idempotencyKey: 'offline-fixed-key',
    );
    expect(repository.tasks.single.isCompleted, isTrue);
    expect(repository.pendingSyncCount, 1);
    expect(repository.syncError, contains('自动同步'));

    online = true;
    await repository.refresh();
    expect(repository.pendingSyncCount, 0);
    expect(completionKeys, ['offline-fixed-key']);
    expect(repository.syncError, isNull);
    repository.dispose();
    api.dispose();
  });
}
