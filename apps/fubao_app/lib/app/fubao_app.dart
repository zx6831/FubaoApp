import 'package:flutter/material.dart';

import '../data/demo_fubao_repository.dart';
import '../design/fubao_theme.dart';
import '../domain/models.dart';
import '../features/auth/role_selection_page.dart';
import '../features/child/child_shell.dart';
import '../features/elder/elder_shell.dart';

class FubaoApp extends StatefulWidget {
  const FubaoApp({super.key});

  @override
  State<FubaoApp> createState() => _FubaoAppState();
}

class _FubaoAppState extends State<FubaoApp> {
  final _repository = DemoFubaoRepository();
  AppRole? _role;

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '福豹',
      theme: buildFubaoTheme(),
      home: switch (_role) {
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
      },
    );
  }
}
