import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/context_note.dart';
import '../models/user_role.dart';
import '../theme/app_theme.dart';

/// Shared visual language for note tags.
abstract final class NoteTagStyle {
  static IconData icon(NoteTag tag) => switch (tag) {
    NoteTag.school => Icons.school_outlined,
    NoteTag.friends => Icons.groups_2_outlined,
    NoteTag.family => Icons.favorite_border_rounded,
    NoteTag.sleep => Icons.bedtime_outlined,
    NoteTag.bored => Icons.sentiment_neutral_outlined,
    NoteTag.other => Icons.chat_bubble_outline_rounded,
  };

  static Color color(NoteTag tag) => switch (tag) {
    NoteTag.school => AppColors.sky,
    NoteTag.friends => AppColors.rose,
    NoteTag.family => AppColors.mint,
    NoteTag.sleep => AppColors.violet,
    NoteTag.bored => AppColors.warning,
    NoteTag.other => AppColors.muted,
  };

  static String label(NoteTag tag, {AppStrings strings = AppStrings.english}) =>
      strings.noteTagLabel(tag);
}

/// A readable note, used on the context strip and inside session cards.
class ContextNoteChip extends StatelessWidget {
  const ContextNoteChip({
    super.key,
    required this.note,
    this.onTap,
    this.dense = false,
  });

  final ContextNote note;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = NoteTagStyle.color(note.tag);
    final strings = context.strings;

    return Semantics(
      button: onTap != null,
      label: strings.noteSemantics(note.text),
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: BoxConstraints(minHeight: onTap == null ? 0 : 48),
            alignment: onTap == null ? null : Alignment.centerLeft,
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 9 : 11,
              vertical: dense ? 7 : 9,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.14)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  NoteTagStyle.icon(note.tag),
                  size: dense ? 13 : 15,
                  color: color,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.text,
                        maxLines: dense ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: dense ? 10 : 11,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      if (!dense) ...[
                        const SizedBox(height: 3),
                        Text(
                          strings.noteMeta(
                            NoteTagStyle.label(note.tag, strings: strings),
                            note.author == UserRole.child
                                ? strings.childNote
                                : strings.parentNote,
                          ),
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: color.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The selectable tag chips used by the note composer.
class NoteTagChip extends StatelessWidget {
  const NoteTagChip({
    super.key,
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final NoteTag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = NoteTagStyle.color(tag);
    final label = NoteTagStyle.label(tag, strings: context.strings);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 17),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.16) : AppColors.cream,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.5) : AppColors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                NoteTagStyle.icon(tag),
                size: 13,
                color: selected ? color : AppColors.muted,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
