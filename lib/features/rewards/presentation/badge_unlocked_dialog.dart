import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confetti.dart';
import '../domain/rewards.dart';

/// Congratulates the child on one or more newly earned badges.
class BadgeUnlockedDialog extends StatefulWidget {
  final List<RewardBadge> badges;

  const BadgeUnlockedDialog({super.key, required this.badges});

  static Future<void> show(BuildContext context, List<RewardBadge> badges) {
    return showDialog(
      context: context,
      builder: (ctx) => BadgeUnlockedDialog(badges: badges),
    );
  }

  @override
  State<BadgeUnlockedDialog> createState() => _BadgeUnlockedDialogState();
}

class _BadgeUnlockedDialogState extends State<BadgeUnlockedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  final _particles = ConfettiParticle.burst();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badges = widget.badges;
    final single = badges.length == 1;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: const Size(340, 340),
              painter: ConfettiPainter(
                progress: _controller.value,
                particles: _particles,
              ),
            ),
          ),
          ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'نشان جدید گرفتی! 🎉',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final b in badges.take(6))
                          _BadgeMedal(badge: b, large: single),
                      ],
                    ),
                    if (single) ...[
                      const SizedBox(height: 10),
                      Text(
                        badges.first.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sunnyDark,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('هورا! ادامه می‌دم 🌟'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeMedal extends StatelessWidget {
  final RewardBadge badge;
  final bool large;

  const _BadgeMedal({required this.badge, required this.large});

  @override
  Widget build(BuildContext context) {
    final size = large ? 96.0 : 64.0;
    return SizedBox(
      width: large ? 160 : 80,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sunnySoft,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.sunny, width: 2),
            ),
            child: Text(
              badge.emoji,
              style: TextStyle(fontSize: large ? 48 : 30),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: large ? 15 : 12,
              fontWeight: FontWeight.w800,
              color: AppColors.sunnyDark,
            ),
          ),
        ],
      ),
    );
  }
}
