/// One family check-in that was marked as talked about.
class CheckInRecord {
  const CheckInRecord({
    required this.childId,
    required this.weekStart,
    required this.topic,
    required this.question,
    required this.completedAt,
  });

  final String childId;
  final DateTime weekStart;
  final String topic;
  final String question;
  final DateTime completedAt;

  factory CheckInRecord.fromJson(Map<String, dynamic> json) => CheckInRecord(
    childId: json['childId'] as String,
    weekStart: DateTime.parse(json['weekStart'] as String),
    topic: json['topic'] as String,
    question: json['question'] as String,
    completedAt: DateTime.parse(json['completedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'childId': childId,
    'weekStart': weekStart.toIso8601String(),
    'topic': topic,
    'question': question,
    'completedAt': completedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CheckInRecord &&
        other.childId == childId &&
        other.weekStart == weekStart &&
        other.topic == topic &&
        other.question == question &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode =>
      Object.hash(childId, weekStart, topic, question, completedAt);
}
