import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import 'auth_session.dart';
import 'remote_api_client.dart';

enum RemoteFlowState { restoring, signedOut, familySetup, onboarding, ready }

class RemoteAppController extends ChangeNotifier {
  RemoteAppController(this.api);

  final RemoteApiClient api;
  RemoteFlowState state = RemoteFlowState.restoring;
  String? errorMessage;
  String? testCode;
  String? invitationCode;
  DateTime? invitationExpiresAt;
  bool profileComplete = false;
  bool deviceActive = false;
  String? discoveredDeviceSerial;

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
      final data = await api.post('auth/request-code',
          body: {'phone': phone}, authenticated: false);
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
      await _resolveFamilyState();
    });
  }

  Future<void> refreshFamily() async {
    await _resolveFamilyState();
  }

  Future<bool> saveHealthProfile({
    required String relativeName,
    required double? heightCm,
    required double? weightKg,
    required List<String> chronicConditions,
    required String emergencyContact,
  }) =>
      _run(() async {
        await api.put('profiles/elder', body: {
          'relativeName': relativeName,
          if (heightCm != null) 'heightCm': heightCm,
          if (weightKg != null) 'weightKg': weightKg,
          'chronicConditions': chronicConditions,
          'medicationHistory': <String, dynamic>{},
          'medicalHistory': <String, dynamic>{},
          if (emergencyContact.isNotEmpty) 'emergencyContact': emergencyContact,
          'consentConfirmed': true,
        });
        profileComplete = true;
        state = RemoteFlowState.onboarding;
      });

  Future<bool> discoverDevice() => _run(() async {
        final result = await api.post('devices/discover');
        final devices = result['devices'] as List;
        discoveredDeviceSerial =
            (devices.first as Map)['serialNumber'] as String;
        state = RemoteFlowState.onboarding;
      });

  Future<bool> activateDevice(String networkName) => _run(() async {
        if (discoveredDeviceSerial == null) {
          throw const ApiException(400, '请先发现设备');
        }
        await api.post('devices/activate', body: {
          'serialNumber': discoveredDeviceSerial,
          'networkName': networkName,
        });
        deviceActive = true;
        state = RemoteFlowState.ready;
      });

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

  Future<bool> leaveFamily() => _run(() async {
        await api.delete('families/current/membership');
        invitationCode = null;
        profileComplete = false;
        deviceActive = false;
        discoveredDeviceSerial = null;
        state = RemoteFlowState.familySetup;
      });

  Future<void> _resolveFamilyState() async {
    try {
      final family = await api.get('families/current');
      final members = (family['members'] as List?) ?? const [];
      final hasElder =
          members.whereType<Map>().any((member) => member['role'] == 'elder');
      if (role == AppRole.child && !hasElder) {
        state = RemoteFlowState.familySetup;
      } else {
        final onboarding = await api.get('onboarding/status');
        profileComplete = onboarding['profileComplete'] == true;
        deviceActive = onboarding['deviceActive'] == true;
        state = onboarding['complete'] == true
            ? RemoteFlowState.ready
            : RemoteFlowState.onboarding;
      }
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
