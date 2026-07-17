import 'package:flutter/material.dart';

import '../../data/fubao_repository.dart';
import '../../widgets/fubao_widgets.dart';
import 'elder_home_page.dart';
import 'elder_plans_page.dart';
import 'elder_profile_page.dart';
import 'elder_topics_page.dart';

class ElderShell extends StatefulWidget {
  const ElderShell({
    required this.repository,
    required this.onSwitchRole,
    super.key,
  });

  final FubaoRepository repository;
  final VoidCallback onSwitchRole;

  @override
  State<ElderShell> createState() => _ElderShellState();
}

class _ElderShellState extends State<ElderShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ElderHomePage(repository: widget.repository),
      ElderPlansPage(repository: widget.repository),
      ElderTopicsPage(repository: widget.repository),
      ElderProfilePage(onSwitchRole: widget.onSwitchRole),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: FubaoBottomNavigation(
        currentIndex: _index,
        elder: true,
        onDestinationSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}
