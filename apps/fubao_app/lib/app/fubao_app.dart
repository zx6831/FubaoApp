import 'package:flutter/material.dart';

import '../data/fubao_repository.dart';
import '../data/demo_fubao_repository.dart';
import '../data/remote_api_client.dart';
import '../data/remote_app_controller.dart';
import '../data/session_store.dart';
import '../design/fubao_theme.dart';
import '../domain/models.dart';
import '../features/auth/role_selection_page.dart';
import '../features/auth/family_binding_page.dart';
import '../features/auth/phone_login_page.dart';
import '../features/child/child_shell.dart';
import '../features/elder/elder_shell.dart';
import 'app_config.dart';

class FubaoApp extends StatefulWidget {
  const FubaoApp({
    this.config,
    this.repository,
    this.remoteController,
    super.key,
  });

  final AppConfig? config;
  final FubaoRepository? repository;
  final RemoteAppController? remoteController;

  @override
  State<FubaoApp> createState() => _FubaoAppState();
}

class _FubaoAppState extends State<FubaoApp> {
  late final FubaoRepository _repository;
  late final bool _ownsRepository;
  late final AppConfig _config;
  RemoteAppController? _remoteController;
  bool _ownsRemoteController = false;
  AppRole? _role;

  @override
  void initState() {
    super.initState();
    _config = widget.config ?? AppConfig.fromValues();
    _ownsRepository = widget.repository == null;
    _repository = widget.repository ?? DemoFubaoRepository();
    if (_config.usesRemoteApi) {
      _ownsRemoteController = widget.remoteController == null;
      _remoteController = widget.remoteController ??
          RemoteAppController(
            RemoteApiClient(
              baseUrl: _config.apiBaseUrl,
              sessionStore: PlatformSessionStore(),
            ),
          );
      _remoteController!.initialize();
    }
  }

  @override
  void dispose() {
    if (_ownsRepository) _repository.dispose();
    if (_ownsRemoteController) _remoteController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '福豹',
      theme: buildFubaoTheme(),
      home: _config.usesRemoteApi ? _buildRemoteHome() : _buildDemoHome(),
    );
  }

  Widget _buildDemoHome() => switch (_role) {
        AppRole.child => ChildShell(
            repository: _repository,
            onSwitchRole: () => setState(() => _role = null),
          ),
        AppRole.elder => ElderShell(
            repository: _repository,
            onSwitchRole: () => setState(() => _role = null),
          ),
        null => RoleSelectionPage(
            onSelected: (role) => setState(() => _role = role),
          ),
      };

  Widget _buildRemoteHome() {
    final controller = _remoteController!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => switch (controller.state) {
        RemoteFlowState.restoring => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        RemoteFlowState.signedOut => PhoneLoginPage(
            errorMessage: controller.errorMessage,
            testCode: controller.testCode,
            onRequestCode: controller.requestCode,
            onVerifyCode: controller.verifyCode,
          ),
        RemoteFlowState.familySetup => FamilyBindingPage(
            role: controller.role!,
            invitationCode: controller.invitationCode,
            errorMessage: controller.errorMessage,
            onCreateInvitation: controller.createFamilyAndInvitation,
            onJoin: controller.joinFamily,
            onRefresh: controller.refreshFamily,
            onLogout: controller.logout,
          ),
        RemoteFlowState.ready => controller.role == AppRole.child
            ? ChildShell(
                repository: _repository,
                onSwitchRole: () => controller.logout(),
              )
            : ElderShell(
                repository: _repository,
                onSwitchRole: () => controller.logout(),
              ),
      },
    );
  }
}
