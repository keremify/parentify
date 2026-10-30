import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/child.dart';
import '../../models/usage_driver.dart';
import '../../services/change_explainer.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';

/// A plain-language decomposition of today's change, with an evidence sheet.
class WhyChangedCard extends StatelessWidget {
  const WhyChangedCard({super.key, required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    final delta = child.dayOverDay.difference;
    final drivers = ChangeExplainer.explainDay(
      child,
      limit: 4,
      strings: context.strings,
    );
    final shown = drivers.take(3).toList();
    final heading = delta == 0
        ? context.strings.todayLevelWithYesterday
        : context.strings.todayDiffThanYesterday(
            formatDifference(delta, strings: context.strings),
          );

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
      radius: 22,
      boxShadow: AppShadows.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.route_rounded,
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
                      context.strings.whyItChanged,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.strings.biggestPieces,
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
              DemoPill(label: context.strings.whyBadge, icon: null),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            heading,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if (shown.isNotEmpty) ...[
            const SizedBox(height: 9),
            for (var index = 0; index < shown.length; index++) ...[
              if (index > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(),
                ),
              _DriverRow(driver: shown[index]),
            ],
          ] else ...[
            const SizedBox(height: 5),
            Text(
              context.strings.noSingleAppMoved,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ],
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _showEvidence(context),
              icon: const Icon(Icons.calculate_outlined, size: 14),
              label: Text(context.strings.showTheMath),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 48),
                textStyle: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEvidence(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      barrierColor: AppColors.ink.withValues(alpha: 0.42),
      builder: (_) => _EvidenceSheet(child: child),
    );
  }
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({required this.driver});

  final UsageDriver driver;

  @override
  Widget build(BuildContext context) {
    final tint = driver.isHigher ? AppColors.coral : AppColors.mint;
    final contextOnly = !driver.isAttribution;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driver.label,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                driver.detail,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 10,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              if (contextOnly)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    context.strings.contextOnlyNotAddedTwice,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.subtle,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatDifference(driver.minutes, strings: context.strings),
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: tint,
          ),
        ),
      ],
    );
  }
}

class _EvidenceSheet extends StatelessWidget {
  const _EvidenceSheet({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    final rows = ChangeExplainer.attribution(child, strings: context.strings);
    final contextRows = ChangeExplainer.explainDay(
      child,
      limit: 8,
      strings: context.strings,
    ).where((driver) => !driver.isAttribution).toList();
    final delta = child.dayOverDay.difference;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const IconBubble(
                icon: Icons.calculate_outlined,
                color: AppColors.sky,
                size: 42,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.strings.showTheMath,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.strings.everyAppLineIsDelta,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              RoundIconButton(
                icon: Icons.close_rounded,
                onPressed: () => Navigator.of(context).pop(),
                size: 34,
                background: AppColors.cream,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              context.strings.mathSummary(
                formatMinutes(child.todayMinutes, strings: context.strings),
                formatMinutes(child.yesterdayMinutes, strings: context.strings),
                formatDifference(delta, strings: context.strings),
              ),
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _EvidenceLabel(context.strings.appByApp),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text(
              context.strings.noAppChangedMeasurably,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            )
          else
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rows[index].label,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            rows[index].evidence,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatDifference(
                        rows[index].minutes,
                        strings: context.strings,
                      ),
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: rows[index].isHigher
                            ? AppColors.coral
                            : AppColors.mint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          if (contextRows.isNotEmpty) ...[
            const SizedBox(height: 20),
            _EvidenceLabel(context.strings.contextSignals),
            const SizedBox(height: 4),
            Text(
              context.strings.contextSignalsBody,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 9.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.subtle,
              ),
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < contextRows.length; index++) ...[
              if (index > 0) const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contextRows[index].label,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            contextRows[index].evidence,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      contextRows[index].detail,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 18),
          Text(
            context.strings.sourceSimulatedActivity(child.deviceName),
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.subtle,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceLabel extends StatelessWidget {
  const _EvidenceLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: AppColors.subtle,
      ),
    );
  }
}

/// 14-day comparison card with day-over-day and week-over-week trends.
class ChangeCard extends StatelessWidget {
  const ChangeCard({super.key, required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    final day = child.dayOverDay;
    final week = child.weekOverWeek;

    return SoftCard(
      padding: const EdgeInsets.all(18),
      radius: 24,
      boxShadow: AppShadows.soft,
      child: Column(
        children: [
          _ComparisonBlock(
            label: context.strings.today,
            value: formatMinutes(child.todayMinutes, strings: context.strings),
            against: context.strings.versusYesterday(
              formatMinutes(child.yesterdayMinutes, strings: context.strings),
            ),
            comparison: day,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(),
          ),
          _ComparisonBlock(
            label: context.strings.thisWeek,
            value: formatMinutes(child.weekMinutes, strings: context.strings),
            against: context.strings.vsLastWeek(
              formatMinutes(
                child.previousWeekMinutes,
                strings: context.strings,
              ),
            ),
            comparison: week,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Text(
                context.strings.fourteenDayShape,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: child.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                context.strings.thisWeek,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(width: 9),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                context.strings.previous,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TrendChart(
            values: child.days.map((entry) => entry.minutes).toList(),
            dates: child.days.map((entry) => entry.date).toList(),
            color: child.accent,
            height: 122,
          ),
        ],
      ),
    );
  }
}

class _ComparisonBlock extends StatelessWidget {
  const _ComparisonBlock({
    required this.label,
    required this.value,
    required this.against,
    required this.comparison,
  });

  final String label;
  final String value;
  final String against;
  final UsageComparison comparison;

  @override
  Widget build(BuildContext context) {
    final rising = comparison.isHigher;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: AppColors.subtle,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 24,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TrendChip(change: comparison.ratio),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                against,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 1),
            Text(
              formatDifference(comparison.difference, strings: context.strings),
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: rising ? AppColors.coral : AppColors.good,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
