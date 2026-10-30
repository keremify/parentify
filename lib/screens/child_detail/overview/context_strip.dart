part of '../overview.dart';

/// The day's notes, shown under the Today card in both roles.
class _ContextStrip extends StatelessWidget {
  const _ContextStrip({required this.child});

  final Child child;

  void _addNote(BuildContext context) {
    showContextNoteSheet(
      context,
      childId: child.id,
      scope: NoteScope.day,
      title: context.strings.addContextToToday,
      subtitle: context.strings.contextExplainsMore,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = AppScope.of(context).dayNotesFor(child.id);

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      radius: 20,
      color: AppColors.cream,
      border: Border.all(color: AppColors.line),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 14,
                color: AppColors.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  notes.isEmpty
                      ? context.strings.storyBehindToday
                      : context.strings.todaysContext,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _addNote(context),
                icon: const Icon(Icons.add_rounded, size: 14),
                label: Text(
                  notes.isEmpty
                      ? context.strings.addContext
                      : context.strings.add,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.violet,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 48),
                  textStyle: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (notes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                context.strings.numbersSayWhy,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 10,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            )
          else
            for (var index = 0; index < notes.length; index++) ...[
              if (index > 0) const SizedBox(height: 6),
              ContextNoteChip(note: notes[index], dense: true),
            ],
        ],
      ),
    );
  }
}
