import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/child.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'charts.dart';
import 'child_avatar.dart';
import 'common.dart';

class ChildSelectorCard extends StatelessWidget {
  const ChildSelectorCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  final Child child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return SoftCard(
      padding: const EdgeInsets.all(16),
      radius: 26,
      onTap: onTap,
      boxShadow: AppShadows.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChildAvatar(
                child: child,
                size: 52,
                heroTag: 'child-avatar-${child.id}',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      strings.ageDevice(child.age, child.deviceName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  size: 15,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.todayBadge,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: AppColors.subtle,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatMinutes(child.todayMinutes, strings: strings),
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 27,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: TrendChip(change: child.dayOverDay.ratio),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MiniSparkline(
            values: child.last7Days.map((day) => day.minutes).toList(),
            color: child.accent,
            height: 30,
          ),
        ],
      ),
    );
  }
}
