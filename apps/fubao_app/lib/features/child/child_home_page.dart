import 'package:flutter/material.dart';

import '../../data/fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../design/fubao_illustrations.dart';
import '../../widgets/fubao_widgets.dart';

class ChildHomePage extends StatelessWidget {
  const ChildHomePage({required this.repository, super.key});

  final FubaoRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: repository,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Row(
              children: [
                const BrandMark(),
                const Spacer(),
                _HeaderAction(
                  icon: Icons.favorite_border_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('家人的关怀都在这里')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SparkHero(days: 12),
            const SizedBox(height: 14),
            _TaskProgressCard(repository: repository),
            const SizedBox(height: 12),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _BloodPressureCard()),
                SizedBox(width: 10),
                Expanded(child: _MoodCard()),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text('聊一聊，会更好',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('换一换'),
                  style: TextButton.styleFrom(
                      foregroundColor: FubaoColors.inkMuted),
                ),
              ],
            ),
            const _ConversationCard(
              image: FubaoIllustration.coffee,
              category: '轻松聊聊',
              text: '今天有没有一件让你\n觉得开心的事？',
            ),
            const SizedBox(height: 10),
            const _ConversationCard(
              image: FubaoIllustration.sofa,
              category: '互相支持',
              text: '遇到小困难也没关系，\n我们一起想想办法吧。',
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 3,
        shadowColor: const Color(0x1A4A3A2E),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(width: 46, height: 46, child: Icon(icon, size: 25)),
        ),
      );
}

class _SparkHero extends StatelessWidget {
  const _SparkHero({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) => Container(
        height: 182,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF4FCF8), Color(0xFFFCFDFB)],
          ),
          border: Border.all(color: FubaoColors.borderMint),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Expanded(
              flex: 5,
              child: FubaoIllustrationAsset(FubaoIllustration.spark),
            ),
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$days',
                      style: const TextStyle(
                          color: FubaoColors.mintStrong,
                          fontSize: 56,
                          height: 1,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('已连续互动 $days 天',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('每天一点点，一起更健康',
                      style:
                          TextStyle(color: FubaoColors.inkMuted, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TaskProgressCard extends StatelessWidget {
  const _TaskProgressCard({required this.repository});
  final FubaoRepository repository;

  @override
  Widget build(BuildContext context) {
    final done = repository.completedTaskCount;
    final total = repository.tasks.length;
    final progress = done / total;
    return FubaoCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const FubaoIllustrationBubble(
            illustration: FubaoIllustration.clipboard,
            size: 88,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('今日任务进度',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$done / $total 已完成',
                    style: const TextStyle(color: FubaoColors.inkMuted)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    color: FubaoColors.mintStrong,
                    backgroundColor: FubaoColors.divider,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('继续加油，完成所有任务吧！',
                    style:
                        TextStyle(color: FubaoColors.inkMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  color: FubaoColors.mintStrong,
                  backgroundColor: FubaoColors.mintSoft,
                ),
                Text('$done/$total',
                    style: const TextStyle(
                        color: FubaoColors.mintStrong,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BloodPressureCard extends StatelessWidget {
  const _BloodPressureCard();
  @override
  Widget build(BuildContext context) => const FubaoCard(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          height: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text('血压',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800))),
                _StatusPill('稳定'),
              ]),
              SizedBox(height: 8),
              Text('128/82',
                  style: TextStyle(
                      color: FubaoColors.mintStrong,
                      fontSize: 25,
                      fontWeight: FontWeight.w900)),
              Text('mmHg',
                  style:
                      TextStyle(color: FubaoColors.mintStrong, fontSize: 12)),
              Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: FubaoColors.inkMuted,
                  ),
                  SizedBox(width: 5),
                  Text(
                    '今天 08:30',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: TextStyle(color: FubaoColors.inkMuted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _MoodCard extends StatelessWidget {
  const _MoodCard();
  @override
  Widget build(BuildContext context) => const FubaoCard(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          height: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text('今日心情',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800))),
                _StatusPill('愉快', filled: true),
              ]),
              Expanded(
                  child: Center(
                      child: FubaoIllustrationAsset(FubaoIllustration.mood,
                          width: 72, height: 72))),
              Text(
                '谢谢你分享心情！',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: TextStyle(color: FubaoColors.inkMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.text, {this.filled = false});
  final String text;
  final bool filled;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: filled ? FubaoColors.mintStrong : FubaoColors.mintSoft,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text,
            style: TextStyle(
                color: filled ? Colors.white : FubaoColors.mintStrong,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard(
      {required this.image, required this.category, required this.text});
  final FubaoIllustration image;
  final String category;
  final String text;
  @override
  Widget build(BuildContext context) => FubaoCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            FubaoIllustrationBubble(
              illustration: image,
              size: 72,
              backgroundColor: const Color(0xFFFFF2E7),
              padding: const EdgeInsets.all(5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category,
                      style: const TextStyle(
                          color: FubaoColors.orangeStrong,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(text,
                      style: const TextStyle(fontSize: 14, height: 1.35)),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: FubaoColors.orangeStrong,
                side: const BorderSide(color: FubaoColors.orangeStrong),
                minimumSize: const Size(72, 42),
              ),
              child: const Text('去聊聊'),
            ),
          ],
        ),
      );
}
