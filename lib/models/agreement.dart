import 'user_role.dart';

/// The kinds of plans a family can agree on. These are intentionally framed as
/// shared agreements rather than limits.
enum AgreementKind { bedtime, dailyCap, appWindow, flexDay }

enum AgreementStatus { proposed, active, declined }

class Agreement {
  const Agreement({
    required this.id,
    required this.childId,
    required this.kind,
    required this.title,
    required this.detail,
    required this.status,
    required this.proposedBy,
    required this.createdAt,
    this.responseNote,
  });

  final String id;
  final String childId;
  final AgreementKind kind;
  final String title;
  final String detail;
  final AgreementStatus status;
  final UserRole proposedBy;
  final DateTime createdAt;
  final String? responseNote;

  bool get isPending => status == AgreementStatus.proposed;
  bool get isActive => status == AgreementStatus.active;
  bool get isDeclined => status == AgreementStatus.declined;

  Agreement copyWith({AgreementStatus? status, String? responseNote}) {
    return Agreement(
      id: id,
      childId: childId,
      kind: kind,
      title: title,
      detail: detail,
      status: status ?? this.status,
      proposedBy: proposedBy,
      createdAt: createdAt,
      responseNote: responseNote ?? this.responseNote,
    );
  }

  factory Agreement.fromJson(Map<String, dynamic> json) => Agreement(
    id: json['id'] as String,
    childId: json['childId'] as String,
    kind: AgreementKind.values.firstWhere(
      (k) => k.name == json['kind'],
      orElse: () => AgreementKind.dailyCap,
    ),
    title: json['title'] as String,
    detail: json['detail'] as String,
    status: AgreementStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => AgreementStatus.proposed,
    ),
    proposedBy: UserRole.values.firstWhere(
      (r) => r.name == json['proposedBy'],
      orElse: () => UserRole.parent,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    responseNote: json['responseNote'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'kind': kind.name,
    'title': title,
    'detail': detail,
    'status': status.name,
    'proposedBy': proposedBy.name,
    'createdAt': createdAt.toIso8601String(),
    'responseNote': responseNote,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Agreement &&
        other.id == id &&
        other.childId == childId &&
        other.kind == kind &&
        other.title == title &&
        other.detail == detail &&
        other.status == status &&
        other.proposedBy == proposedBy &&
        other.createdAt == createdAt &&
        other.responseNote == responseNote;
  }

  @override
  int get hashCode => Object.hash(
    id,
    childId,
    kind,
    title,
    detail,
    status,
    proposedBy,
    createdAt,
    responseNote,
  );
}
