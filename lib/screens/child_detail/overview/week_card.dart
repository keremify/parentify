part of '../overview.dart';

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    final dates = child.last7Days.map((day) => day.date).toList();
    final minutes = child.last7Days.map((day) => day.minutes).toList();

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      radius: 24,
      boxShadow: AppShadows.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.strings.thisWeek,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.strings.screenTimeLast7Days,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.subtle,
                      ),
                    ),
                  ],
                ),
              ),
              TrendChip(change: child.weekOverWeek.ratio),
            ],
          ),
          const SizedBox(height: 16),
          WeeklyBarChart(
            minutes: minutes,
            dates: dates,
            color: child.accent,
            height: 106,
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _WeekStat(
                  label: context.strings.dailyAverage,
                  value: formatMinutes(
                    child.weeklyAverage,
                    strings: context.strings,
                  ),
                ),
              ),
              Container(width: 1, height: 26, color: AppColors.line),
              Expanded(
                child: _WeekStat(
                  label: context.strings.weekTotal,
                  value: formatMinutes(
                    child.weekMinutes,
                    strings: context.strings,
                  ),
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekStat extends StatelessWidget {
  const _WeekStat({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: AppColors.subtle,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
