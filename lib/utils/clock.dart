/// The app's single source of "now".
///
/// Production code reads the current time through [AppClock.now]. Tests can
/// point it at a fixed instant so the UI and the seeded demo data render
/// identically on every machine and every run.
abstract final class AppClock {
  static DateTime Function() now = DateTime.now;

  /// Restores the real system clock. Intended for test teardown.
  static void reset() {
    now = DateTime.now;
  }
}
