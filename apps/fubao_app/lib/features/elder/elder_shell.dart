import 'package:flutter/material.dart';

import '../../data/fubao_repository.dart';
import '../../widgets/fubao_widgets.dart';
import '../../widgets/sync_status_banner.dart';
import 'elder_home_page.dart';
import 'elder_plans_page.dart';
import 'elder_profile_page.dart';
import 'elder_topics_page.dart';

class ElderShell extends StatefulWidget {
  const ElderShell({
    required this.repository,
    required this.onLogout,
    required this.onLeaveFamily,
    super.key,
  });

  final FubaoRepository repository;
  final Future<void> Function() onLogout;
  final Future<void> Function() onLeaveFamily;

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
      ElderTopicsPage(
        repository: widget.repository,
        onOpenPlans: () => setState(() => _index = 1),
      ),
      ElderProfilePage(
        repository: widget.repository,
        onLogout: widget.onLogout,
        onLeaveFamily: widget.onLeaveFamily,
      ),
    ];

    return Scaffold(
      body: AnimatedBuilder(
        animation: widget.repository,
        builder: (context, _) => Column(children: [
          SyncStatusBanner(repository: widget.repository),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ]),
      ),
      bottomNavigationBar: FubaoBottomNavigation(
        currentIndex: _index,
        elder: true,
        onDestinationSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}
