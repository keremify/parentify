part of '../overview.dart';

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.child,
    this.visibility = VisibilityLevel.full,
  });

  final Child child;
  final VisibilityLevel visibility;

  @override
  Widget build(BuildContext context) {
    final ratio = child.dayOverDay.ratio;
    final now = AppClock.now();

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.inkCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -80,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    child.accent.withValues(alpha: 0.5),
                    child.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.strings.todayUpperDate(
                        formatDateUpper(now, strings: context.strings),
                      ),
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sync_rounded,
                            size: 10,
                            color: AppColors.mintBright,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatSyncedAt(
                              child.lastSyncedAt,
                              strings: context.strings,
                            ),
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      formatMinutes(
                        child.todayMinutes,
                        strings: context.strings,
                      ),
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: TrendChip(change: ratio, onDark: true),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  context.strings.versusYesterday(
                    formatMinutes(
                      child.yesterdayMinutes,
                      strings: context.strings,
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 14),
                if (visibility == VisibilityLevel.trends)
                  Text(
                    context.strings.dailyTotalShared,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 9.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  )
                else if (visibility == VisibilityLevel.guided)
                  Row(
                    children: [
                      _TodayStat(
                        label: context.strings.unlocks,
                        value: '${child.unlocksToday}',
                      ),
                      _StatDivider(),
                      _TodayStat(
                        label: context.strings.topApp,
                        value: child.topApp?.name ?? '—',
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      _TodayStat(
                        label: context.strings.unlocks,
                        value: '${child.unlocksToday}',
                      ),
                      _StatDivider(),
                      _TodayStat(
                        label: context.strings.peakWindow,
                        value: formatHourRange(
                          child.peakWindowStart,
                          child.peakWindowStart + 3,
                          strings: context.strings,
                        ),
                      ),
                      _StatDivider(),
                      _TodayStat(
                        label: context.strings.topApp,
                        value: child.topApp?.name ?? '—',
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

class _TodayStat extends StatelessWidget {
  const _TodayStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 25,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}
