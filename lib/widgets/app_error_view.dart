import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Shown instead of Flutter's red error box when a widget build fails.
///
/// The demo keeps everything on-device, so there is no crash reporter to send
/// anything to. This keeps the failure calm and explains the one recovery step
/// that matters: restart to return to the seeded family view.
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.violetSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.violet,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.strings.somethingWentWrong,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.strings.appErrorBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
