import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/agreement.dart';
import '../models/child.dart';
import '../models/context_note.dart';
import '../models/user_role.dart';
import '../models/visibility.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../utils/clock.dart';
import '../widgets/common.dart';

/// Child-side request composer. Returns the created request when submitted.
Future<Agreement?> showAgreementRequestSheet(
  BuildContext context, {
  required Child child,
}) {
  return showModalBottomSheet<Agreement>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _AgreementRequestSheet(child: child),
    ),
  );
}

/// Parent-side review. Returns the resulting status when answered.
Future<AgreementStatus?> showAgreementReviewSheet(
  BuildContext context, {
  required Child child,
  required Agreement agreement,
}) {
  return showModalBottomSheet<AgreementStatus>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _AgreementReviewSheet(child: child, agreement: agreement),
    ),
  );
}

/// Parent-side sharing level picker. Returns true when saved.
Future<bool?> showVisibilitySheet(
  BuildContext context, {
  required Child child,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    builder: (sheetContext) => _VisibilitySheet(child: child),
  );
}

/// Locale-independent state key for the request's day chips.
enum _RequestDay { today, tomorrow, saturday, sunday }

class _AgreementRequestSheet extends StatefulWidget {
  const _AgreementRequestSheet({required this.child});

  final Child child;

  @override
  State<_AgreementRequestSheet> createState() => _AgreementRequestSheetState();
}

class _AgreementRequestSheetState extends State<_AgreementRequestSheet> {
  static const _minuteOptions = [15, 30, 45, 60];

  final _reason = TextEditingController();
  _RequestDay _day = _RequestDay.saturday;
  int _minutes = 30;
  bool _addNote = true;
  bool _canAsk = false;

  @override
  void initState() {
    super.initState();
    _reason.addListener(_onReasonChanged);
  }

  @override
  void dispose() {
    _reason
      ..removeListener(_onReasonChanged)
      ..dispose();
    super.dispose();
  }

  void _onReasonChanged() {
    final canAsk = _reason.text.trim().isNotEmpty;
    if (canAsk != _canAsk) setState(() => _canAsk = canAsk);
  }

  void _submit() {
    final state = AppScope.read(context);
    final strings = context.strings;
    final reason = _reason.text.trim();
    if (reason.isEmpty) return;

    final dayPhrase = switch (_day) {
      _RequestDay.today => strings.dayPhraseToday,
      _RequestDay.tomorrow => strings.dayPhraseTomorrow,
      _RequestDay.saturday => strings.dayPhraseOn(strings.saturday),
      _RequestDay.sunday => strings.dayPhraseOn(strings.sunday),
    };
    final agreement = Agreement(
      id: 'agreement-${AppClock.now().microsecondsSinceEpoch}',
      childId: widget.child.id,
      kind: AgreementKind.flexDay,
      title: strings.moreMinutesTitle(_minutes, dayPhrase),
      detail: reason,
      status: AgreementStatus.proposed,
      proposedBy: UserRole.child,
      createdAt: AppClock.now(),
    );

    if (!state.proposeAgreement(agreement)) return;

    if (_addNote) {
      state.addContextNote(
        ContextNote(
          id: 'note-${AppClock.now().microsecondsSinceEpoch}',
          childId: widget.child.id,
          createdAt: AppClock.now(),
          author: UserRole.child,
          tag: NoteTag.other,
          text: reason,
          scope: NoteScope.day,
        ),
      );
    }

    Navigator.of(context).pop(agreement);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    String dayLabel(_RequestDay day) => switch (day) {
      _RequestDay.today => strings.today,
      _RequestDay.tomorrow => strings.tomorrow,
      _RequestDay.saturday => strings.saturday,
      _RequestDay.sunday => strings.sunday,
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
                icon: Icons.waving_hand_outlined,
                color: AppColors.violet,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.askForMoreTime,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      strings.askForMoreTimeSubtitle,
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
          _FieldLabel(strings.fieldWhen),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final day in _RequestDay.values)
                _ChoiceChip(
                  label: dayLabel(day),
                  selected: _day == day,
                  onTap: () => setState(() => _day = day),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _FieldLabel(strings.fieldHowMuchMore),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final minutes in _minuteOptions)
                _ChoiceChip(
                  label: strings.minutesCount(minutes),
                  selected: _minutes == minutes,
                  onTap: () => setState(() => _minutes = minutes),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _FieldLabel(strings.fieldWhy),
          const SizedBox(height: 8),
          TextField(
            controller: _reason,
            maxLength: 140,
            minLines: 3,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(hintText: strings.reasonHint),
          ),
          SwitchListTile.adaptive(
            value: _addNote,
            onChanged: (value) => setState(() => _addNote = value),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.violet,
            title: Text(
              strings.shareAsContext,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            subtitle: Text(
              strings.shareAsContextSubtitle,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _canAsk ? _submit : null,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(strings.sendRequest),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              strings.requestSeenOnHome,
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
    );
  }
}

class _AgreementReviewSheet extends StatefulWidget {
  const _AgreementReviewSheet({required this.child, required this.agreement});

  final Child child;
  final Agreement agreement;

  @override
  State<_AgreementReviewSheet> createState() => _AgreementReviewSheetState();
}

class _AgreementReviewSheetState extends State<_AgreementReviewSheet> {
  final _reply = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _respond(AgreementStatus status) {
    if (_saving) return;
    final state = AppScope.read(context);
    final note = _reply.text.trim();
    final saved = state.respondToAgreement(
      widget.agreement.id,
      status,
      note: note.isEmpty ? null : note,
    );
    if (!saved) return;
    setState(() => _saving = true);
    Navigator.of(context).pop(status);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final agreement = widget.agreement;

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
              IconBubble(
                icon: Icons.forward_to_inbox_rounded,
                color: widget.child.accent,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.childAsked(widget.child.name),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      strings.agreementSummary(
                        agreement.title,
                        agreement.detail,
                      ),
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
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.violetSoft.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.violet.withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agreement.title,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  agreement.detail,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _FieldLabel(strings.replyOptionalLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _reply,
            maxLength: 140,
            minLines: 2,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(hintText: strings.replyHint),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => _respond(AgreementStatus.declined),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: AppColors.lineStrong),
                    foregroundColor: AppColors.muted,
                  ),
                  child: Text(strings.notThisTime),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _saving
                      ? null
                      : () => _respond(AgreementStatus.active),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(strings.approve),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              strings.eitherAnswerOpen,
              textAlign: TextAlign.center,
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
    );
  }
}

class _VisibilitySheet extends StatefulWidget {
  const _VisibilitySheet({required this.child});

  final Child child;

  @override
  State<_VisibilitySheet> createState() => _VisibilitySheetState();
}

class _VisibilitySheetState extends State<_VisibilitySheet> {
  late VisibilityLevel _level = AppScope.read(context)
      .visibilityFor(widget.child.id);

  void _save() {
    final state = AppScope.read(context);
    if (!state.setVisibility(widget.child.id, _level)) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
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
                icon: Icons.visibility_outlined,
                color: AppColors.sky,
                size: 42,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.sharingWith(widget.child.name),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.familyPolicy,
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
          for (final level in VisibilityLevel.values) ...[
            Semantics(
              button: true,
              selected: _level == level,
              label: strings.visibilityOptionSemantics(
                strings.visibilityLabel(level),
                strings.visibilityDescription(level),
              ),
              onTap: () => setState(() => _level = level),
              excludeSemantics: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _level = level),
                  excludeFromSemantics: true,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 9),
                    decoration: BoxDecoration(
                      color: _level == level
                          ? AppColors.violetSoft
                          : AppColors.cream,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _level == level
                            ? AppColors.violet.withValues(alpha: 0.45)
                            : AppColors.line,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _level == level
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: _level == level
                              ? AppColors.violet
                              : AppColors.subtle,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.visibilityLabel(level),
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                strings.visibilityDescription(level),
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 10.5,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: AppColors.subtle,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  strings.childAlwaysSees,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 9.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subtle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(strings.saveSharingLevel),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

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

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
          decoration: BoxDecoration(
            color: selected ? AppColors.violetSoft : AppColors.cream,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected
                  ? AppColors.violet.withValues(alpha: 0.45)
                  : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.violet : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
