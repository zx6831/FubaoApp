import 'package:flutter/material.dart';

import '../../data/demo_fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';

class ElderHomePage extends StatelessWidget {
  const ElderHomePage({required this.repository, super.key});

  final DemoFubaoRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: repository,
        builder: (context, _) {
          final medicine =
              repository.tasks.singleWhere((task) => task.id == 'medicine');
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('早上好，王阿姨',
                            style: Theme.of(context).textTheme.headlineLarge),
                        const EmptySpacer(height: 12),
                        const SparkBadge(compact: true),
                      ],
                    ),
                  ),
                  const ReadAloudButton(text: '早上好，王阿姨。今天要做的事是按时吃药、记录血压。'),
                ],
              ),
              const EmptySpacer(height: 28),
              SectionTitle('今天要做的事', elder: true),
              const EmptySpacer(height: 14),
              _MedicineTaskCard(
                task: medicine,
                onChanged: (value) =>
                    repository.setTaskCompleted('medicine', value),
              ),
              const EmptySpacer(height: 16),
              FubaoCard(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('测试版已记录血压 128/82 mmHg')),
                ),
                padding: const EdgeInsets.all(22),
                child: const Row(
                  children: [
                    FubaoIconBubble(
                        icon: Icons.monitor_heart_outlined,
                        color: FubaoColors.mintStrong,
                        size: 76),
                    SizedBox(width: 20),
                    Expanded(
                        child: Text('记录血压',
                            style: TextStyle(
                                fontSize: 29, fontWeight: FontWeight.w900))),
                    Icon(Icons.arrow_forward_rounded,
                        size: 38, color: FubaoColors.mintStrong),
                  ],
                ),
              ),
              const EmptySpacer(height: 20),
              const SafetyNote(),
            ],
          );
        },
      ),
    );
  }
}

class _MedicineTaskCard extends StatelessWidget {
  const _MedicineTaskCard({required this.task, required this.onChanged});

  final HealthTask task;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FubaoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FubaoIconBubble(
                  icon: Icons.medication_rounded,
                  color: FubaoColors.mintStrong,
                  size: 82),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(task.timeLabel,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ElderChoiceButton(
            label: task.isCompleted ? '已完成' : '我已经吃了',
            icon: Icons.check_circle_rounded,
            color: FubaoColors.mintStrong,
            onPressed: () => onChanged(true),
          ),
          const SizedBox(height: 14),
          _ElderChoiceButton(
            label: '我还没吃',
            icon: Icons.radio_button_unchecked_rounded,
            color: FubaoColors.orangeStrong,
            onPressed: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ElderChoiceButton extends StatelessWidget {
  const _ElderChoiceButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onPressed});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(78),
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 34),
      label: Text(label),
    );
  }
}
