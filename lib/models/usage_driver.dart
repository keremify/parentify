/// A single reason today's screen time moved.
///
/// App drivers are the attribution rows: together they add up to the day's
/// delta. Other kinds (late night, unlocks, baseline, a new app) are context
/// signals and are not counted twice.
enum DriverKind { app, lateNight, unlocks, baseline, newApp }

enum DriverTone { positive, attention, neutral }

class UsageDriver {
  const UsageDriver({
    required this.label,
    required this.detail,
    required this.minutes,
    required this.evidence,
    required this.kind,
    required this.tone,
    this.share = 0,
  });

  final String label;
  final String detail;

  /// Signed change in minutes.
  final int minutes;

  /// Share of the day's positive app attribution, 0..1. Zero for context rows.
  final double share;

  final String evidence;
  final DriverKind kind;
  final DriverTone tone;

  bool get isAttribution => kind == DriverKind.app;
  bool get isHigher => minutes > 0;
}
