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
        if (request.url.path.endsWith('/topics/today')) {
          return success({
            'items': [
              {
                'id': 'topic-1',
                'title': '今天的任务完成得很棒',
                'description': '肯定坚持和努力。',
                'suggestedWords': '妈，今天辛苦啦！',
              }
            ],
          });
        }
        if (request.url.path.endsWith('/messages')) {
          return success({
            'items': [
              {
                'id': 'message-1',
                'type': 'weeklyReport',
                'title': '本周健康周报已生成',
                'body': '看看本周任务完成情况。',
                'readAt': null,
                'createdAt': '2026-07-18T00:30:00.000Z',
              }
            ],
          });
        }
        if (request.url.path.endsWith('/reports/weekly')) {
          return success({
            'from': '2026-07-12',
            'to': '2026-07-18',
            'tasks': {'completed': completed ? 1 : 0, 'total': 1},
            'completionRate': completed ? 1 : 0,
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
    expect(repository.topics.single.id, 'topic-1');
    expect(repository.messages.single.type, AppMessageType.weeklyReport);
    expect(repository.weeklyReport?.total, 1);

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
        if (request.url.path.endsWith('/topics/today') ||
            request.url.path.endsWith('/messages')) {
          return success({'items': const []});
        }
        if (request.url.path.endsWith('/reports/weekly')) {
          return success({
            'from': '2026-07-12',
            'to': '2026-07-18',
            'tasks': {'completed': 0, 'total': 0},
            'completionRate': 0,
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

  test('sends engagement and privacy actions to their scoped endpoints',
      () async {
    final requests = <String>[];
    final store = MemorySessionStore()..value = session();
    final api = RemoteApiClient(
      baseUrl: 'http://localhost:3000/api',
      sessionStore: store,
      httpClient: MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/messages/message-1/read')) {
          return success({
            'id': 'message-1',
            'type': 'system',
            'title': '系统消息',
            'body': '已读',
            'readAt': '2026-07-18T01:00:00.000Z',
            'createdAt': '2026-07-18T00:30:00.000Z',
          });
        }
        if (request.url.path.endsWith('/privacy/export')) {
          return success({'generatedAt': '2026-07-18T01:00:00.000Z'});
        }
        if (request.url.path.endsWith('/privacy/account')) {
          return success({'deleteAfter': '2026-08-17T01:00:00.000Z'});
        }
        if (request.url.path.endsWith('/families/current')) {
          return success({
            'id': 'family-1',
            'members': [
              {'userId': 'elder-1', 'role': 'elder', 'nickname': '王阿姨'}
            ],
          });
        }
        if (request.url.path.endsWith('/profiles/elder') &&
            request.method == 'GET') {
          return success({'relativeName': '妈妈'});
        }
        if (request.url.path.endsWith('/profiles/elder') &&
            request.method == 'PUT') {
          return success({
            ...(jsonDecode(request.body) as Map).cast<String, dynamic>(),
            'consentAt': '2026-07-18T02:00:00.000Z',
          });
        }
        if (request.url.path.endsWith('/devices/current') &&
            request.method == 'GET') {
          return success({'id': 'device-1', 'status': 'online'});
        }
        if (request.url.path.endsWith('/devices/settings')) {
          return success(
              (jsonDecode(request.body) as Map).cast<String, dynamic>());
        }
        if (request.url.path.endsWith('/devices/status')) {
          return success({'id': 'device-1', 'status': 'offline'});
        }
        if (request.url.path.endsWith('/devices/factory-reset')) {
          return success({'id': 'device-1', 'status': 'discovered'});
        }
        if (request.url.path.endsWith('/devices/current') &&
            request.method == 'DELETE') {
          return success({'unbound': true});
        }
        return success({'submitted': true});
      }),
    );
    await api.restoreSession();
    final repository = RemoteFubaoRepository(api);

    await repository.markTopicCopied('topic-1');
    await repository.markMessageRead('message-1');
    final exported = await repository.exportData();
    final deleteAfter = await repository.scheduleAccountDeletion();
    await repository.submitFeedback('希望增加语音提示');
    await repository.registerPushToken('a' * 64);
    expect((await repository.familyDetails())['id'], 'family-1');
    expect((await repository.elderHealthProfile())['relativeName'], '妈妈');
    expect(
      (await repository.updateElderHealthProfile({
        'relativeName': '母亲',
        'heightCm': 162,
        'weightKg': 58.5,
        'chronicConditions': ['高血压'],
        'consentConfirmed': true,
      }))['relativeName'],
      '母亲',
    );
    expect((await repository.currentDevice())['status'], 'online');
    expect(
      (await repository.updateDeviceSettings({
        'volume': 60,
        'speechRate': 50,
        'dndEnabled': true,
        'dndStart': '22:00',
        'dndEnd': '07:00',
      }))['volume'],
      60,
    );
    expect((await repository.setDeviceOnline(false))['status'], 'offline');
    expect((await repository.factoryResetDevice())['status'], 'discovered');
    await repository.unbindDevice();

    expect(exported['generatedAt'], isNotNull);
    expect(deleteAfter, DateTime.parse('2026-08-17T01:00:00.000Z'));
    expect(requests, contains('POST /api/topics/topic-1/copied'));
    expect(requests, contains('PATCH /api/messages/message-1/read'));
    expect(requests, contains('GET /api/privacy/export'));
    expect(requests, contains('DELETE /api/privacy/account'));
    expect(requests, contains('POST /api/feedback'));
    expect(requests, contains('POST /api/notifications/device-token'));
    expect(requests, contains('GET /api/families/current'));
    expect(requests, contains('GET /api/profiles/elder'));
    expect(requests, contains('PUT /api/profiles/elder'));
    expect(requests, contains('PATCH /api/devices/settings'));
    expect(requests, contains('PATCH /api/devices/status'));
    expect(requests, contains('POST /api/devices/factory-reset'));
    expect(requests, contains('DELETE /api/devices/current'));
    repository.dispose();
    api.dispose();
  });
}
