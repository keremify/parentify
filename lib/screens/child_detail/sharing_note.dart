import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/child.dart';
import '../../models/visibility.dart';
import '../../theme/app_theme.dart';

/// Explains a non-full sharing level without implying anything was removed.
class SharingNote extends StatelessWidget {
  const SharingNote({super.key, required this.child, required this.level});

  final Child child;
  final VisibilityLevel level;

  @override
  Widget build(BuildContext context) {
    final detail = level == VisibilityLevel.trends
        ? context.strings.sharingTrendsBody(child.name)
        : context.strings.sharingGuidedBody(child.name);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.violetSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.visibility_outlined,
            size: 14,
            color: AppColors.violet,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.strings.agreedWithFamily(
                    context.strings.visibilityLabel(level),
                  ),
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.violet,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 9.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkMuted,
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
