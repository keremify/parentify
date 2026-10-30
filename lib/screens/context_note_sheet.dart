import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/context_note.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/clock.dart';
import '../widgets/common.dart';
import '../widgets/context_chip.dart';

/// Opens the note composer. The caller decides which part of the day the note
/// belongs to and stores the returned note in [AppState].
Future<ContextNote?> showContextNoteSheet(
  BuildContext context, {
  required String childId,
  required NoteScope scope,
  String? targetId,
  String? title,
  String? subtitle,
}) {
  return showModalBottomSheet<ContextNote>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _ContextNoteSheet(
        childId: childId,
        scope: scope,
        targetId: targetId,
        title: title,
        subtitle: subtitle,
      ),
    ),
  );
}

class _ContextNoteSheet extends StatefulWidget {
  const _ContextNoteSheet({
    required this.childId,
    required this.scope,
    this.targetId,
    this.title,
    this.subtitle,
  });

  final String childId;
  final NoteScope scope;
  final String? targetId;
  final String? title;
  final String? subtitle;

  @override
  State<_ContextNoteSheet> createState() => _ContextNoteSheetState();
}

class _ContextNoteSheetState extends State<_ContextNoteSheet> {
  final _controller = TextEditingController();
  NoteTag _tag = NoteTag.other;
  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final canSave = _controller.text.trim().isNotEmpty;
    if (canSave != _canSave) setState(() => _canSave = canSave);
  }

  void _save() {
    final state = AppScope.read(context);
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final note = ContextNote(
      id: 'note-${AppClock.now().microsecondsSinceEpoch}',
      childId: widget.childId,
      createdAt: AppClock.now(),
      author: state.role ?? UserRole.child,
      tag: _tag,
      text: text,
      scope: widget.scope,
      targetId: widget.targetId,
    );
    state.addContextNote(note);
    Navigator.of(context).pop(note);
  }

  @override
  Widget build(BuildContext context) {
    final fallbackTitle = switch (widget.scope) {
      NoteScope.day => context.strings.addContextToToday,
      NoteScope.session => context.strings.whatWasThisStretch,
      NoteScope.app => context.strings.addContextToThisApp,
    };

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBubble(
                icon: Icons.chat_bubble_outline_rounded,
                color: AppColors.mint,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title ?? fallbackTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle ?? context.strings.noteSubtitleFallback,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: Icons.close_rounded,
                onPressed: () => Navigator.of(context).pop(),
                size: 34,
                background: AppColors.cream,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            context.strings.whatWasIt,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppColors.subtle,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final tag in NoteTag.values)
                NoteTagChip(
                  tag: tag,
                  selected: _tag == tag,
                  onTap: () => setState(() => _tag = tag),
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 140,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(hintText: context.strings.noteHint),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: AppColors.subtle,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  context.strings.notesStayOnDevice,
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
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _canSave ? _save : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(context.strings.saveNote),
          ),
        ],
      ),
    );
  }
}
