import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/agreement.dart';
import '../models/child.dart';
import '../models/visibility.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common.dart';

/// The two-sided plan card: agreement, sharing level and any open request.
///
/// Child mode uses it as the "Together" card. Parent mode uses it as a banner
/// on the child's overview.
class FamilyPlanCard extends StatelessWidget {
  const FamilyPlanCard({
    super.key,
    required this.child,
    required this.agreement,
    required this.pending,
    required this.visibility,
    required this.isChild,
    this.declined,
    this.onAsk,
    this.onAdjust,
    this.onReview,
  });

  final Child child;
  final Agreement? agreement;
  final Agreement? pending;
  final VisibilityLevel visibility;
  final bool isChild;
  final Agreement? declined;
  final VoidCallback? onAsk;
  final VoidCallback? onAdjust;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      radius: 22,
      boxShadow: AppShadows.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.handshake_outlined,
                color: AppColors.mint,
                size: 38,
                radius: 13,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isChild ? strings.together : strings.ourFamilyPlan,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isChild
                          ? strings.madeTogether
                          : strings.agreedNotImposed(child.name),
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
              if (agreement != null)
                DemoPill(label: strings.activeBadge, icon: null),
            ],
          ),
          const SizedBox(height: 11),
          if (agreement != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppColors.mint,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          agreement!.title,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    agreement!.detail,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 10,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              isChild ? strings.noPlanChild : strings.noAgreementParent,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isChild
                    ? Icons.visibility_outlined
                    : Icons.lock_outline_rounded,
                size: 13,
                color: AppColors.subtle,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isChild
                      ? strings.parentSeesShort(
                          strings.visibilityShortLabel(visibility),
                        )
                      : strings.sharingWithChild(
                          child.name,
                          strings.visibilityLabel(visibility),
                        ),
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 9.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ),
              if (onAdjust != null)
                TextButton(
                  onPressed: onAdjust,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(strings.adjust),
                ),
            ],
          ),
          if (pending != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 13,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isChild
                        ? strings.requestWaiting
                        : strings.childHasOpenRequest(child.name),
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.warning,
                    ),
                  ),
                ),
                if (onReview != null)
                  TextButton(
                    onPressed: onReview,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(strings.review),
                  ),
              ],
            ),
          ],
          if (pending == null && declined != null) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.forum_outlined,
                  size: 13,
                  color: AppColors.subtle,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isChild
                        ? (declined!.responseNote == null ||
                                  declined!.responseNote!.isEmpty
                              ? strings.parentRepliedNoNote
                              : strings.parentRepliedWithNote(
                                  declined!.responseNote!,
                                ))
                        : strings.lastReplySaved(child.name),
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 9.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (isChild && onAsk != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onAsk,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(strings.askForMoreTime),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(
                  color: AppColors.violet.withValues(alpha: 0.3),
                ),
                foregroundColor: AppColors.violet,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Parent-home card for an answerable request.
class PendingRequestCard extends StatelessWidget {
  const PendingRequestCard({
    super.key,
    required this.child,
    required this.agreement,
    required this.onReview,
  });

  final Child child;
  final Agreement agreement;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      radius: 22,
      color: AppColors.violetSoft,
      border: Border.all(color: AppColors.violet.withValues(alpha: 0.18)),
      onTap: onReview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SmallAvatar(
                initials: child.initials,
                color: child.accent,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.askedUpper(child.name),
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: AppColors.violet,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      agreement.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DemoPill(label: strings.newBadge, icon: null),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            agreement.detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 10.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                strings.askedAt(
                  formatSyncedAt(agreement.createdAt, strings: strings),
                ),
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtle,
                ),
              ),
              const Spacer(),
              Text(
                strings.reviewRequest,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.violet,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: AppColors.violet,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
