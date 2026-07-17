import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import 'auth_session.dart';
import 'remote_api_client.dart';

enum RemoteFlowState { restoring, signedOut, familySetup, ready }

class RemoteAppController extends ChangeNotifier {
  RemoteAppController(this.api);

  final RemoteApiClient api;
  RemoteFlowState state = RemoteFlowState.restoring;
  String? errorMessage;
  String? testCode;
  String? invitationCode;
  DateTime? invitationExpiresAt;

  AuthSession? get session => api.session;
  AppRole? get role => session?.role;

  Future<void> initialize() async {
    final restored = await api.restoreSession();
    if (restored == null) {
      state = RemoteFlowState.signedOut;
      notifyListeners();
      return;
    }
    await _resolveFamilyState();
  }

  Future<bool> requestCode(String phone) async {
    return _run(() async {
      final data = await api.post('auth/request-code', body: {'phone': phone}, authenticated: false);
      testCode = data['testCode'] as String?;
    });
  }

  Future<bool> verifyCode(String phone, String code, AppRole role) async {
    return _run(() async {
      final data = await api.post(
        'auth/verify-code',
        body: {'phone': phone, 'code': code, 'role': role.name},
        authenticated: false,
      );
      await api.saveSession(data);
      await _resolveFamilyState();
    });
  }

  Future<bool> createFamilyAndInvitation() async {
    return _run(() async {
      await api.post('families');
      final invitation = await api.post('families/invitations');
      invitationCode = invitation['code'] as String;
      invitationExpiresAt = DateTime.parse(invitation['expiresAt'] as String);
      state = RemoteFlowState.familySetup;
    });
  }

  Future<bool> joinFamily(String code) async {
    return _run(() async {
      await api.post('families/join', body: {'code': code});
      state = RemoteFlowState.ready;
    });
  }

  Future<void> refreshFamily() async {
    await _resolveFamilyState();
  }

  Future<void> logout() async {
    final refreshToken = api.session?.refreshToken;
    if (refreshToken != null) {
      try {
        await api.post('auth/logout', body: {'refreshToken': refreshToken});
      } catch (_) {
        // Local logout must still succeed if the network is unavailable.
      }
    }
    await api.clearSession();
    invitationCode = null;
    state = RemoteFlowState.signedOut;
    notifyListeners();
  }

  Future<void> _resolveFamilyState() async {
    try {
      final family = await api.get('families/current');
      final members = (family['members'] as List?) ?? const [];
      final hasElder = members.whereType<Map>().any((member) => member['role'] == 'elder');
      state = role == AppRole.child && !hasElder
          ? RemoteFlowState.familySetup
          : RemoteFlowState.ready;
      errorMessage = null;
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        state = RemoteFlowState.familySetup;
        errorMessage = null;
      } else if (error.statusCode == 401) {
        state = RemoteFlowState.signedOut;
        errorMessage = error.message;
      } else {
        state = RemoteFlowState.familySetup;
        errorMessage = error.message;
      }
    }
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = '网络连接失败，请稍后重试';
    }
    notifyListeners();
    return false;
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}
