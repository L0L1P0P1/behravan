import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/rewards.dart';

final rewardsProvider = Provider<RewardsSummary>((ref) {
  final now = DateTime.now();
  return computeRewards(
    voiding: ref.watch(voidingLogsProvider).value ?? const [],
    nights: ref.watch(enuresisLogsProvider).value ?? const [],
    bowel: ref.watch(bowelLogsProvider).value ?? const [],
    today: DateTime(now.year, now.month, now.day),
  );
});

/// Ids of badges the child has already been congratulated for. A badge stays
/// here even if deleting logs re-locks it, so it is never celebrated twice.
const seenBadgesKey = 'seen_badges';
