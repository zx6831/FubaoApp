import 'package:flutter/material.dart';

import '../data/fubao_repository.dart';
import '../design/fubao_colors.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({required this.repository, super.key});

  final FubaoRepository repository;

  @override
  Widget build(BuildContext context) {
    final message = repository.syncError;
    if (message == null) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFFFFF3E8),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Icon(Icons.cloud_off_rounded,
                size: 18, color: FubaoColors.orangeStrong),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: FubaoColors.inkMuted, fontSize: 12)),
            ),
            if (repository.pendingSyncCount > 0)
              Text('${repository.pendingSyncCount} 项待同步',
                  style: const TextStyle(
                      color: FubaoColors.orangeStrong,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}
