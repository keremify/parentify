import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/app_usage.dart';
import '../../models/child.dart';
import '../../models/visibility.dart';
import '../../state/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../theme/category_visuals.dart';
import '../../utils/formatters.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/usage_widgets.dart';
import '../agreement_sheet.dart';
import 'sharing_note.dart';

/// Apps tab displaying weekly category donut, usage distribution, and individual apps.
class AppsTab extends StatelessWidget {
  const AppsTab({
    super.key,
    required this.child,
    required this.gutter,
    required this.onOpenApp,
  });

  final Child child;
  final double gutter;
  final ValueChanged<UsageApp> onOpenApp;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = context.strings;
    final level = state.isChild
        ? VisibilityLevel.full
        : state.visibilityFor(child.id);
    final categories = child.weeklyCategories;
    final slices = [
      for (final entry in categories)
        DonutSlice(
          label: strings.categoryLabel(entry.key),
          value: entry.value,
          color: entry.key.color,
        ),
    ];
    final apps = child.appsByUsage;
    final maxMinutes = apps.isEmpty ? 0 : apps.first.weekMinutes;

    if (!state.isChild && level == VisibilityLevel.trends) {
      return ListView(
        padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 42),
        children: [
          SharingNote(child: child, level: level),
          const SizedBox(height: 14),
          SoftCard(
            padding: const EdgeInsets.all(22),
            radius: 24,
            child: Column(
              children: [
                const IconBubble(
                  icon: Icons.lock_outline_rounded,
                  color: AppColors.violet,
                  size: 48,
                ),
                const SizedBox(height: 13),
                Text(
                  context.strings.appDetailPrivate,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  context.strings.appDetailPrivateBody(child.name),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 10.5,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => showVisibilitySheet(context, child: child),
                  child: Text(context.strings.reviewSharingLevel),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 42),
      children: [
        Row(
          children: [
            Text(
              context.strings.last7Days,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppColors.subtle,
              ),
            ),
            const Spacer(),
            Text(
              context.strings.tracked(
                formatMinutes(child.weekAppMinutes, strings: context.strings),
              ),
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        SoftCard(
          padding: const EdgeInsets.all(17),
          radius: 24,
          boxShadow: AppShadows.soft,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 280;
              final donut = CategoryDonut(
                slices: slices,
                total: child.weekAppMinutes,
                size: 120,
                strokeWidth: 15,
              );
              final legend = _CategoryLegend(
                categories: categories,
                total: child.weekAppMinutes,
              );

              if (compact) {
                return Column(
                  children: [donut, const SizedBox(height: 16), legend],
                );
              }
              return Row(
                children: [
                  donut,
                  const SizedBox(width: 16),
                  Expanded(child: legend),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 26),
        SectionHeader(
          title: context.strings.allApps,
          subtitle: context.strings.appsSorted(apps.length),
        ),
        const SizedBox(height: 11),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          radius: 22,
          boxShadow: AppShadows.soft,
          child: Column(
            children: [
              for (var index = 0; index < apps.length; index++) ...[
                if (index > 0) const Divider(),
                AppUsageRow(
                  app: apps[index],
                  maxMinutes: maxMinutes,
                  onTap: level == VisibilityLevel.full
                      ? () => onOpenApp(apps[index])
                      : null,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              level == VisibilityLevel.full
                  ? Icons.touch_app_outlined
                  : Icons.lock_outline_rounded,
              size: 12,
              color: AppColors.subtle,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                level == VisibilityLevel.full
                    ? context.strings.tapAppToSeeRhythm
                    : context.strings.appTotalsSharedDrillDown(child.name),
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({required this.categories, required this.total});

  final List<MapEntry<AppCategory, int>> categories;
  final int total;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in categories) ...[
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: entry.key.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  strings.categoryLabel(entry.key),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
              Text(
                strings.percent(
                  total == 0 ? 0 : (entry.value / total * 100).round(),
                ),
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
        ],
        const SizedBox(height: 1),
        Text(
          context.strings.timeByCategory,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: AppColors.subtle.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
