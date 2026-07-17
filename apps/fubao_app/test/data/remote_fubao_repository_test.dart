import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fubao_app/data/auth_session.dart';
import 'package:fubao_app/data/remote_api_client.dart';
import 'package:fubao_app/data/remote_fubao_repository.dart';
import 'package:fubao_app/data/session_store.dart';
import 'package:fubao_app/domain/models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  http.Response success(Map<String, dynamic> data, [int status = 200]) =>
      http.Response.bytes(
        utf8.encode(jsonEncode({'code': 0, 'msg': 'success', 'data': data})),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  AuthSession session() => AuthSession.fromJson({
        'accessToken': 'access',
        'accessTokenExpiresAt':
            DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
        'refreshToken': 'refresh',
        'refreshTokenExpiresAt':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'user': {'id': 'elder-1', 'role': 'elder', 'nickname': '王阿姨'},
      });

  test(
      'loads cloud plans and completes a task with the original idempotency key',
      () async {
    var completed = false;
    String? idempotencyKey;
    final store = MemorySessionStore()..value = session();
    final api = RemoteApiClient(
      baseUrl: 'http://localhost:3000/api',
      sessionStore: store,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/plans')) {
          return success({
            'items': [
              {
                'id': 'plan-1',
                'kind': 'medicine',
                'title': '晚间用药',
                'subtitle': '饭后温水服用',
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
                'subtitle': '饭后温水服用',
                'reminderAt': '2026-07-17T12:00:00.000Z',
                'status': completed ? 'completed' : 'pending',
                'record': completed
                    ? {
                        'status': 'completed',
                        'source': 'app',
                        'data': null,
                        'completedAt': '2026-07-17T12:01:00.000Z',
                      }
                    : null,
              }
            ],
          });
        }
        if (request.url.path.endsWith('/tasks/task-1/complete')) {
          idempotencyKey = request.headers.entries
              .where((entry) => entry.key.toLowerCase() == 'idempotency-key')
              .single
              .value;
          completed = true;
          return success({'id': 'task-1', 'status': 'completed'}, 201);
        }
        if (request.url.path.endsWith('/health-data') ||
            request.url.path.endsWith('/alerts')) {
          return success({'items': const []});
        }
        if (request.url.path.endsWith('/sparks/current')) {
          return success({
            'lit': false,
            'streakDays': 0,
            'childActive': false,
            'elderActive': true,
          });
        }
        throw StateError(
            'Unexpected request: ${request.method} ${request.url}');
      }),
    );
    await api.restoreSession();
    final repository = RemoteFubaoRepository(api);

    await repository.refresh();
    expect(repository.tasks.single.title, '晚间用药');
    expect(repository.plans.single.completed, 0);

    await repository.setTaskCompleted(
      'task-1',
      true,
      idempotencyKey: 'offline-operation-1',
    );
    expect(idempotencyKey, 'offline-operation-1');
    expect(repository.tasks.single.isCompleted, isTrue);
    expect(repository.plans.single.completed, 1);
    repository.dispose();
    api.dispose();
  });

  test('serializes all plan enrollment fields for the three-step flow',
      () async {
    Map<String, dynamic>? posted;
    final store = MemorySessionStore()..value = session();
    final api = RemoteApiClient(
      baseUrl: 'http://localhost:3000/api',
      sessionStore: store,
      httpClient: MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/plans')) {
          posted = (jsonDecode(request.body) as Map).cast<String, dynamic>();
          return success({
            'id': 'plan-glucose',
            'kind': 'bloodGlucose',
            'title': '晨起血糖',
            'subtitle': '空腹测量',
            'status': 'active',
            'schedule': posted!['schedule'],
          }, 201);
        }
        if (request.url.path.endsWith('/plans')) {
          return success({'items': const []});
        }
        if (request.url.path.endsWith('/tasks/today')) {
          return success({'items': const []});
        }
        if (request.url.path.endsWith('/health-data') ||
            request.url.path.endsWith('/alerts')) {
          return success({'items': const []});
        }
        if (request.url.path.endsWith('/sparks/current')) {
          return success({
            'lit': false,
            'streakDays': 0,
            'childActive': true,
            'elderActive': false,
          });
        }
        throw StateError(
            'Unexpected request: ${request.method} ${request.url}');
      }),
    );
    await api.restoreSession();
    final repository = RemoteFubaoRepository(api);

    await repository.createPlan(PlanDraft(
      kind: TaskKind.bloodGlucose,
      title: '晨起血糖',
      subtitle: '空腹测量',
      startsOn: DateTime(2026, 7, 17),
      reminderTime: '07:30',
      daysOfWeek: const [1, 3, 5],
      enrollmentData: const {'note': '早餐前'},
    ));

    expect(posted, containsPair('kind', 'bloodGlucose'));
    expect(posted?['startsOn'], '2026-07-17');
    expect(posted?['schedule'], {
      'time': '07:30',
      'daysOfWeek': [1, 3, 5],
    });
    expect(posted?['enrollmentData'], {'note': '早餐前'});
    repository.dispose();
    api.dispose();
  });
}
