import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_usage.dart';
import '../models/child.dart';
import '../models/context_note.dart';
import '../theme/category_visuals.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'context_chip.dart';

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.app,
    this.size = 44,
    this.radius = 13,
  });

  final UsageApp app;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: app.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: app.color.withValues(alpha: 0.10)),
      ),
      alignment: Alignment.center,
      child: Icon(app.icon, color: app.color, size: size * 0.48),
    );
  }
}

class AppUsageRow extends StatelessWidget {
  const AppUsageRow({
    super.key,
    required this.app,
    required this.maxMinutes,
    this.showToday = true,
    this.onTap,
  });

  final UsageApp app;
  final int maxMinutes;
  final bool showToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final fraction = maxMinutes <= 0
        ? 0.0
        : (app.weekMinutes / maxMinutes).clamp(0.0, 1.0);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppIconBadge(app: app),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        app.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatMinutes(app.weekMinutes, strings: strings),
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 5,
                    backgroundColor: app.color.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(app.color),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      strings.categoryLabel(app.category),
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                    const Spacer(),
                    if (showToday)
                      Text(
                        strings.todaySuffix(
                          formatMinutes(app.todayMinutes, strings: strings),
                        ),
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.subtle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.subtle,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: content,
    );
  }
}

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.maxMinutes,
    this.showApps = true,
    this.showTime = true,
    this.note,
    this.onAddNote,
  });

  final UsageSession session;
  final int maxMinutes;
  final bool showApps;
  final bool showTime;
  final ContextNote? note;
  final VoidCallback? onAddNote;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final categoryColor = session.category.color;
    final fraction = maxMinutes <= 0
        ? 0.0
        : (session.minutes / maxMinutes).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.85)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(session.category.icon, color: categoryColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        session.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatMinutes(session.minutes, strings: strings),
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  showTime
                      ? strings.sessionTime(
                          relativeDay(session.start, strings: strings),
                          formatTime(session.start, strings: strings),
                          formatTime(session.end, strings: strings),
                        )
                      : relativeDay(session.start, strings: strings),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 5,
                    backgroundColor: categoryColor.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        strings.categoryLabel(session.category),
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    if (showApps) ...[
                      const Spacer(),
                      Flexible(
                        child: Text(
                          session.apps.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.subtle,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (note != null) ...[
                  const SizedBox(height: 8),
                  ContextNoteChip(note: note!, dense: true),
                ] else if (onAddNote != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onAddNote,
                      icon: const Icon(Icons.add_comment_outlined, size: 13),
                      label: Text(strings.addContext),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.muted,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 48),
                        textStyle: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
