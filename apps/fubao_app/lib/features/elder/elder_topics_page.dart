import 'package:flutter/material.dart';

import '../../data/fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../design/fubao_illustrations.dart';
import '../../widgets/fubao_widgets.dart';

class ElderTopicsPage extends StatelessWidget {
  const ElderTopicsPage({
    required this.repository,
    this.onOpenPlans,
    super.key,
  });
  final FubaoRepository repository;
  final VoidCallback? onOpenPlans;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: repository,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
            children: [
              const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Text('今天聊什么',
                            style: TextStyle(
                                fontSize: 39, fontWeight: FontWeight.w900))),
                    ReadAloudButton(text: '今天聊什么。看看家人给你的暖心话题。'),
                  ]),
              const SizedBox(height: 22),
              repository.allTasksCompleted
                  ? const _CompletedHero()
                  : const _PendingHero(),
              const SizedBox(height: 18),
              if (repository.allTasksCompleted) ...[
                const _ElderTopicCard(
                    image: FubaoIllustration.elderSun,
                    title: '今天有什么开心的事？'),
                const SizedBox(height: 14),
                const _ElderTopicCard(
                    image: FubaoIllustration.elderPark,
                    title: '下午散步时看到什么？'),
              ] else
                FubaoCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(children: [
                    const Icon(Icons.checklist_rounded,
                        size: 62, color: FubaoColors.mintStrong),
                    const SizedBox(height: 12),
                    const Text('完成任务后，暖心话题会出现在这里',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 23, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onOpenPlans,
                      child: const Text('去完成任务'),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      );
}

class _PendingHero extends StatelessWidget {
  const _PendingHero();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFF0FAF6), Color(0xFFFAFDFB)]),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: FubaoColors.borderMint),
        ),
        child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('先完成今天的任务',
                  style: TextStyle(
                      color: FubaoColors.mintDeep,
                      fontSize: 29,
                      fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text('完成后就能看到家人准备的暖心话题',
                  style: TextStyle(color: FubaoColors.inkMuted, fontSize: 18)),
            ]),
      );
}

class _CompletedHero extends StatelessWidget {
  const _CompletedHero();
  @override
  Widget build(BuildContext context) => Container(
        height: 210,
        padding: const EdgeInsets.fromLTRB(22, 24, 8, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFEAF8F2), Color(0xFFF7FCF9)]),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(children: [
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Text('今天的任务都完成啦！',
                    style: TextStyle(
                        color: FubaoColors.mintDeep,
                        fontSize: 29,
                        height: 1.35,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 12),
                Text('看看家人给你的暖心话题',
                    style:
                        TextStyle(color: FubaoColors.inkMuted, fontSize: 16)),
              ])),
          const FubaoIllustrationAsset(FubaoIllustration.elderProfileMascot,
              width: 160, height: 184),
        ]),
      );
}

class _ElderTopicCard extends StatelessWidget {
  const _ElderTopicCard({required this.image, required this.title});
  final FubaoIllustration image;
  final String title;
  @override
  Widget build(BuildContext context) => FubaoCard(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          FubaoIllustrationBubble(
            illustration: image,
            size: 128,
          ),
          const SizedBox(width: 18),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 29,
                      height: 1.35,
                      fontWeight: FontWeight.w900))),
          const CircleAvatar(
              radius: 28,
              backgroundColor: FubaoColors.mintStrong,
              child: Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 38)),
        ]),
      );
}
