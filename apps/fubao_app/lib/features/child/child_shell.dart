import 'package:flutter/material.dart';

import '../../data/fubao_repository.dart';
import '../../widgets/fubao_widgets.dart';
import 'child_home_page.dart';
import 'child_plans_page.dart';
import 'child_profile_page.dart';
import 'child_topics_page.dart';

class ChildShell extends StatefulWidget {
  const ChildShell({
    required this.repository,
    required this.onLogout,
    super.key,
  });

  final FubaoRepository repository;
  final Future<void> Function() onLogout;

  @override
  State<ChildShell> createState() => _ChildShellState();
}

class _ChildShellState extends State<ChildShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ChildHomePage(repository: widget.repository),
      ChildPlansPage(repository: widget.repository),
      ChildTopicsPage(repository: widget.repository),
      ChildProfilePage(onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: FubaoBottomNavigation(
        currentIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}
