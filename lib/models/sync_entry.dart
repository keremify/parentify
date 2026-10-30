import 'dart:convert' show jsonDecode, jsonEncode;

/// The type of mutation operation performed locally.
enum SyncOperation { create, update, delete }

/// The state of an outbox sync queue entry.
enum SyncStatus { pending, syncing, synced, failed }

/// Represents an offline mutation queued for background synchronization.
class SyncEntry {
  const SyncEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.status,
    this.retryCount = 0,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final SyncStatus status;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == SyncStatus.pending;
  bool get isSyncing => status == SyncStatus.syncing;
  bool get isSynced => status == SyncStatus.synced;
  bool get isFailed => status == SyncStatus.failed;

  SyncEntry copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncOperation? operation,
    Map<String, dynamic>? payload,
    SyncStatus? status,
    int? retryCount,
    String? lastError,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyncEntry(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation.name,
      'payload_json': jsonEncode(payload),
      'status': status.name,
      'retry_count': retryCount,
      'last_error': lastError,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SyncEntry.fromMap(Map<String, Object?> map) {
    return SyncEntry(
      id: map['id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      operation: SyncOperation.values.firstWhere(
        (o) => o.name == map['operation'],
        orElse: () => SyncOperation.update,
      ),
      payload:
          (jsonDecode(map['payload_json'] as String) as Map<String, dynamic>),
      status: SyncStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SyncStatus.pending,
      ),
      retryCount: map['retry_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncEntry &&
          other.id == id &&
          other.entityType == entityType &&
          other.entityId == entityId &&
          other.operation == operation &&
          other.status == status &&
          other.retryCount == retryCount &&
          other.lastError == lastError &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operation,
    status,
    retryCount,
    lastError,
    createdAt,
    updatedAt,
  );
}
