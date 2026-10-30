import 'user_role.dart';

/// A short, human note attached to a day, a session or an app.
///
/// Notes are authored by the child or the parent and stay on the device. They
/// are deliberately qualitative: the numbers say *what* happened, the note can
/// say *why*.
enum NoteTag { school, friends, family, sleep, bored, other }

enum NoteScope { day, session, app }

class ContextNote {
  const ContextNote({
    required this.id,
    required this.childId,
    required this.createdAt,
    required this.author,
    required this.tag,
    required this.text,
    required this.scope,
    this.targetId,
  });

  final String id;
  final String childId;
  final DateTime createdAt;
  final UserRole author;
  final NoteTag tag;
  final String text;

  /// Day notes have no target. Session and app notes point at an id.
  final NoteScope scope;
  final String? targetId;

  factory ContextNote.fromJson(Map<String, dynamic> json) => ContextNote(
    id: json['id'] as String,
    childId: json['childId'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    author: UserRole.values.firstWhere(
      (r) => r.name == json['author'],
      orElse: () => UserRole.parent,
    ),
    tag: NoteTag.values.firstWhere(
      (t) => t.name == json['tag'],
      orElse: () => NoteTag.other,
    ),
    text: json['text'] as String,
    scope: NoteScope.values.firstWhere(
      (s) => s.name == json['scope'],
      orElse: () => NoteScope.day,
    ),
    targetId: json['targetId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'createdAt': createdAt.toIso8601String(),
    'author': author.name,
    'tag': tag.name,
    'text': text,
    'scope': scope.name,
    'targetId': targetId,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContextNote &&
        other.id == id &&
        other.childId == childId &&
        other.createdAt == createdAt &&
        other.author == author &&
        other.tag == tag &&
        other.text == text &&
        other.scope == scope &&
        other.targetId == targetId;
  }

  @override
  int get hashCode =>
      Object.hash(id, childId, createdAt, author, tag, text, scope, targetId);
}
