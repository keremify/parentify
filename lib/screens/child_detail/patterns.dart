import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/child.dart';
import '../../services/ai_analyzer_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';

/// Card showing AI behavioral observations and rhythm signals.
class ObservationsCard extends StatelessWidget {
  const ObservationsCard({super.key, required this.observations});

  final List<AiObservation> observations;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      radius: 24,
      boxShadow: AppShadows.soft,
      child: Column(
        children: [
          for (var index = 0; index < observations.length; index++) ...[
            if (index > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBubble(
                    icon: _toneIcon(observations[index].tone),
                    color: _toneColor(observations[index].tone),
                    size: 34,
                    radius: 11,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                observations[index].title,
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cream,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                observations[index].tag.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: AppColors.subtle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          observations[index].detail,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 10.5,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _toneColor(InsightTone tone) => switch (tone) {
  InsightTone.positive => AppColors.mint,
  InsightTone.attention => AppColors.warning,
  InsightTone.neutral => AppColors.violet,
};

IconData _toneIcon(InsightTone tone) => switch (tone) {
  InsightTone.positive => Icons.trending_down_rounded,
  InsightTone.attention => Icons.flag_outlined,
  InsightTone.neutral => Icons.auto_awesome_rounded,
};

/// Peak usage and late-night activity indicator card.
class PeakCard extends StatelessWidget {
  const PeakCard({super.key, required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    final start = child.peakWindowStart;
    final windowMinutes = child.hourlyToday.isEmpty
        ? 0
        : start + 2 < child.hourlyToday.length
        ? child.hourlyToday[start] +
              child.hourlyToday[start + 1] +
              child.hourlyToday[start + 2]
        : child.hourlyToday[start];
    final peakShare = child.todayMinutes == 0
        ? 0.0
        : windowMinutes / child.todayMinutes;
    final lateMinutes = child.lateNightMinutes;
    final strings = context.strings;

    return SoftCard(
      padding: const EdgeInsets.all(18),
      radius: 24,
      boxShadow: AppShadows.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.nightlight_round,
                color: AppColors.violet,
                size: 40,
                radius: 14,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatHourRange(start, start + 3, strings: strings),
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.busiestWindow((peakShare * 100).round()),
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
              DemoPill(label: strings.todayBadge, icon: null),
            ],
          ),
          const SizedBox(height: 17),
          HourlyActivityStrip(
            hourly: child.hourlyToday,
            color: child.accent,
            height: 58,
          ),
          const SizedBox(height: 13),
          const Divider(),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _PeakStat(
                  label: strings.eveningUse,
                  value: formatMinutes(child.eveningMinutes, strings: strings),
                  detail: strings.sixToTen,
                  color: AppColors.ink,
                ),
              ),
              Container(width: 1, height: 28, color: AppColors.line),
              Expanded(
                child: _PeakStat(
                  label: strings.after10Pm,
                  value: formatMinutes(lateMinutes, strings: strings),
                  detail: lateMinutes > 15
                      ? strings.worthACheckIn
                      : strings.settled,
                  color: lateMinutes > 15 ? AppColors.warning : AppColors.good,
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

class _PeakStat extends StatelessWidget {
  const _PeakStat({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final String detail;
  final Color color;
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
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          detail,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: AppColors.subtle,
          ),
        ),
      ],
    );
  }
}

/// A conversation starter or routine suggestion card.
class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.index,
    required this.suggestion,
  });

  final int index;
  final AiSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.85)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: const BoxDecoration(
              color: AppColors.violetSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.violet,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  suggestion.detail,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 10.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
