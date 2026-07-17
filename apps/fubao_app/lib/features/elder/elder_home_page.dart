import 'package:flutter/material.dart';

import '../../data/fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../design/fubao_illustrations.dart';
import '../../widgets/fubao_widgets.dart';

class ElderHomePage extends StatelessWidget {
  const ElderHomePage({required this.repository, super.key});
  final FubaoRepository repository;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: repository,
          builder: (context, _) {
            final medicine =
                repository.tasks.firstWhere((task) => task.id == 'medicine');
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('早上好，王阿姨',
                            style: TextStyle(
                                fontSize: 35,
                                fontWeight: FontWeight.w900,
                                height: 1.2)),
                        SizedBox(height: 14),
                        SparkBadge(compact: true),
                      ])),
                  const ReadAloudButton(text: '早上好，王阿姨。今天要做的事是按时吃药和记录血压。'),
                ]),
                const SizedBox(height: 20),
                FubaoCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('今天要做的事',
                            style: TextStyle(
                                fontSize: 29, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 18),
                        Row(children: [
                          const FubaoIllustrationBubble(
                            illustration: FubaoIllustration.pill,
                            size: 120,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(medicine.title,
                                    style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 25,
                                      color: FubaoColors.mintStrong,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          medicine.timeLabel,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            fontSize: 23,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ])),
                        ]),
                        const SizedBox(height: 20),
                        if (!medicine.isCompleted) ...[
                          _LargeTaskButton(
                            label: '我已经吃了',
                            icon: Icons.check_rounded,
                            color: FubaoColors.mintStrong,
                            onTap: () =>
                                repository.setTaskCompleted('medicine', true),
                          ),
                          const SizedBox(height: 12),
                          _LargeTaskButton(
                            label: '我还没吃',
                            icon: Icons.radio_button_unchecked_rounded,
                            color: FubaoColors.orangeStrong,
                            onTap: () => ScaffoldMessenger.of(context)
                                .showSnackBar(
                                    const SnackBar(content: Text('稍后会再次提醒你'))),
                          ),
                        ] else
                          _LargeTaskButton(
                            label: '已完成',
                            icon: Icons.check_circle_rounded,
                            color: FubaoColors.mintStrong,
                            onTap: () {},
                          ),
                      ]),
                ),
                const SizedBox(height: 16),
                FubaoCard(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请坐好休息 5 分钟后记录血压'))),
                  padding: const EdgeInsets.all(16),
                  child: const Row(children: [
                    FubaoIllustrationAsset(
                        FubaoIllustration.elderBloodPressureDevice,
                        width: 126,
                        height: 104),
                    SizedBox(width: 14),
                    Expanded(
                        child: Text('记录血压',
                            style: TextStyle(
                                fontSize: 29, fontWeight: FontWeight.w900))),
                    CircleAvatar(
                        radius: 28,
                        backgroundColor: FubaoColors.mintStrong,
                        child: Icon(Icons.chevron_right_rounded,
                            color: Colors.white, size: 40)),
                  ]),
                ),
              ],
            );
          },
        ),
      );
}

class _LargeTaskButton extends StatelessWidget {
  const _LargeTaskButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: color,
        elevation: 4,
        shadowColor: color.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 88,
            child: Row(children: [
              const SizedBox(width: 22),
              CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.white,
                  child: Icon(icon, color: color, size: 36)),
              const SizedBox(width: 20),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w900))),
            ]),
          ),
        ),
      );
}
