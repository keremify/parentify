import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class CheckInCard extends StatelessWidget {
  const CheckInCard({super.key, required this.state, required this.onTap});

  final AppState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final last = state.lastCheckIn;
    final streak = state.checkInStreak;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      radius: 22,
      color: AppColors.mintSoft.withValues(alpha: 0.55),
      border: Border.all(color: AppColors.mint.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.event_available_outlined,
                color: AppColors.mint,
                size: 38,
                radius: 13,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.strings.weeklyCheckIn,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.strings.weeklyCheckInSubtitle,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.subtle,
                      ),
                    ),
                  ],
                ),
              ),
              if (streak > 0)
                DemoPill(
                  label: context.strings.checkInStreak(streak),
                  icon: null,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            last == null
                ? context.strings.checkInEmpty
                : context.strings.checkInLast(last.topic, last.question),
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 10.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 11),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.forum_outlined, size: 16),
            label: Text(
              last == null
                  ? context.strings.startCheckIn
                  : context.strings.openCheckIn,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.mint,
              side: BorderSide(color: AppColors.mint.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
    );
  }
}
