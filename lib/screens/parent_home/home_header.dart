import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.state,
    required this.now,
    required this.hasPending,
    required this.onOpenSettings,
    required this.onOpenAlerts,
  });

  final AppState state;
  final DateTime now;
  final bool hasPending;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const BrandLockup(markSize: 28),
            const Spacer(),
            RoundIconButton(
              icon: Icons.notifications_none_rounded,
              onPressed: onOpenAlerts,
              size: 42,
              tooltip: context.strings.alerts,
              showBadge: hasPending,
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: context.strings.settings,
              excludeFromSemantics: true,
              child: Semantics(
                button: true,
                label: context.strings.settings,
                onTap: onOpenSettings,
                excludeSemantics: true,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: InkWell(
                      onTap: onOpenSettings,
                      excludeFromSemantics: true,
                      customBorder: const CircleBorder(),
                      child: SmallAvatar(
                        initials: state.parentName.isEmpty
                            ? '?'
                            : state.parentName.substring(0, 1).toUpperCase(),
                        color: AppColors.violet,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          context.strings.dateHeading(now),
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.violet,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          context.strings.greetingWithName(now, state.parentName),
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 26,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          context.strings.homeGreetingSubtitle,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12.5,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
