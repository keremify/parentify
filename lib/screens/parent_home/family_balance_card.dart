import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

class FamilyBalanceCard extends StatelessWidget {
  const FamilyBalanceCard({
    super.key,
    required this.state,
    required this.onToggle,
  });

  final AppState state;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final kidsToday = state.familyTodayMinutes;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.balance_rounded,
                color: AppColors.sky,
                size: 38,
                radius: 13,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.strings.familyBalance,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.strings.familyBalanceSubtitle,
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
              Switch.adaptive(
                value: state.includeParentUsage,
                onChanged: (_) => onToggle(),
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.violet,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.includeParentUsage) ...[
            Row(
              children: [
                Expanded(
                  child: BalanceStat(
                    label: context.strings.kidsToday,
                    value: formatMinutes(kidsToday, strings: context.strings),
                    color: AppColors.violet,
                  ),
                ),
                Expanded(
                  child: BalanceStat(
                    label: context.strings.youToday,
                    value: formatMinutes(
                      state.parentTodayMinutes,
                      strings: context.strings,
                    ),
                    color: AppColors.coral,
                  ),
                ),
                Expanded(
                  child: BalanceStat(
                    label: context.strings.allTogether,
                    value: formatMinutes(
                      state.wholeFamilyToday,
                      strings: context.strings,
                    ),
                    color: AppColors.mint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              context.strings.familyWeekLogged(
                formatMinutes(
                  state.familyWeekMinutes + state.parentWeekMinutes,
                  strings: context.strings,
                ),
              ),
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 9.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ] else
            Text(
              context.strings.familyBalanceOff,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
        ],
      ),
    );
  }
}

class BalanceStat extends StatelessWidget {
  const BalanceStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: AppColors.subtle,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: color,
          ),
        ),
      ],
    );
  }
}
