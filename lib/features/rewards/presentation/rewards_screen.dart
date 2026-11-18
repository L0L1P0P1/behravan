import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/night_weather.dart';
import '../../tutorial/presentation/tutorial_screen.dart';
import '../application/rewards_provider.dart';
import '../domain/rewards.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(rewardsProvider);
    final nextGoal = rewards.nextGoal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('باغ جایزه‌ها'),
        actions: const [TutorialButton(topic: TutorialTopic.rewards)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _LevelHeroCard(rewards: rewards),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    emoji: '🔥',
                    value: '${rewards.loggingStreak} روز',
                    label: 'ثبت پشت سر هم',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    emoji: '🏅',
                    value:
                        '${rewards.unlocked.length} از ${rewards.badges.length}',
                    label: 'نشان گرفته‌شده',
                  ),
                ),
              ],
            ),
          ),
          if (nextGoal != null) ...[
            const SizedBox(height: 12),
            _NextGoalCard(badge: nextGoal),
          ],
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SectionHeader(title: 'نشان‌های من'),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemCount: rewards.badges.length,
            itemBuilder: (context, i) => _BadgeTile(badge: rewards.badges[i]),
          ),
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SectionHeader(title: 'چطور ستاره بگیرم؟'),
          ),
          const SizedBox(height: 10),
          const _StarRulesCard(),
        ],
      ),
    );
  }
}

class _LevelHeroCard extends StatelessWidget {
  final RewardsSummary rewards;

  const _LevelHeroCard({required this.rewards});

  @override
  Widget build(BuildContext context) {
    final next = rewards.nextLevel;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFE0F2FE), Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sunny.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  rewards.level.emoji,
                  style: const TextStyle(fontSize: 34),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحله ${rewards.level.number}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      rewards.level.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.sunny,
                    size: 26,
                  ),
                  Text(
                    '${rewards.stars}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.sunnyDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rewards.levelProgress,
              minHeight: 12,
              backgroundColor: Colors.white,
              color: AppColors.sunny,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            next == null
                ? 'به بالاترین مرحله رسیدی! باغت پر از گل شده 🎉'
                : '${next.minStars - rewards.stars} ستاره تا مرحله «${next.title}» ${next.emoji}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatTile({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextGoalCard extends StatelessWidget {
  final RewardBadge badge;

  const _NextGoalCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هدف بعدی: ${badge.title}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  badge.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: badge.ratio,
                          minHeight: 8,
                          backgroundColor: AppColors.border,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${badge.progress.clamp(0, badge.target)}/${badge.target}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final RewardBadge badge;

  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.isUnlocked;

    return Tooltip(
      message: badge.description,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        decoration: BoxDecoration(
          color: unlocked ? AppColors.sunnySoft : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: unlocked ? AppColors.sunny : AppColors.border,
            width: unlocked ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Opacity(
              opacity: unlocked ? 1 : 0.3,
              child: Text(badge.emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                badge.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  color: unlocked ? AppColors.sunnyDark : AppColors.muted,
                ),
              ),
            ),
            if (unlocked)
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.success,
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: badge.ratio,
                  minHeight: 5,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StarRulesCard extends StatelessWidget {
  const _StarRulesCard();

  @override
  Widget build(BuildContext context) {
    Widget rule(Widget leading, String text, int stars) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 26, child: Center(child: leading)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ),
          Text(
            '+$stars',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.sunnyDark,
            ),
          ),
          const Icon(Icons.star_rounded, size: 16, color: AppColors.sunny),
        ],
      ),
    );

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          rule(const NightWeatherIcon(isDry: true), 'شب آفتابی (خشک)', 3),
          rule(const NightWeatherIcon(isDry: false), 'ثبت شب بارانی (خیس)', 1),
          rule(
            const Icon(Icons.alarm_on_rounded, color: AppColors.primary),
            'دستشویی رفتن با یادآوری',
            2,
          ),
          rule(
            const Icon(Icons.water_drop_rounded, color: AppColors.primary),
            'هر ثبت دیگر ادرار، حتی خیس شدن',
            1,
          ),
          rule(
            const Icon(Icons.favorite_rounded, color: AppColors.success),
            'مدفوع سالم (نوع ۳ تا ۵)',
            2,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'گیاه‌ها هم به آفتاب نیاز دارند هم به باران؛ هر ثبتِ راست و درست باغت را بزرگ‌تر می‌کند 🌱',
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
