part of '../app_strings.dart';

mixin ChildDetailCopy {
  // ---------------------------------------------------------------------------
  // Child detail
  // ---------------------------------------------------------------------------

  String get overviewTab => 'Overview';
  String get appsTab => 'Apps';
  String get insightsTab => 'Insights';
  String get backToFamily => 'Back to family';
  String childGreeting(String name) => 'Hi, $name';
  String deviceSyncLine(String device, String synced) => '$device · $synced';
  String analysisNotice(String notice) =>
      '$notice Showing the on-device analysis instead.';
  String get analysisRefreshedGemini => 'Analysis refreshed with Gemini.';
  String get analysisRefreshedDemo =>
      'Analysis refreshed with the latest demo data.';
  String get analysisRefreshFailed =>
      'Could not refresh the analysis. The last report is still here.';

  // --- Overview -------------------------------------------------------------

  String get thisWeek => 'This week';
  String get seeAll => 'See all';
  String get appUsage => 'App usage';
  String get whereWeekWent => 'Where the week went, by app.';
  String get allApps => 'All apps';
  String get longestStretches => 'Longest stretches';
  String get mostAbsorbedMoments => 'The most absorbed moments this week.';
  String get sessionAppDetailPrivate =>
      'Session and app detail stay private at this sharing level.';
  String todayDateSimulated(String date) =>
      'Today · $date · simulated activity';
  String sharingTrendsBody(String name) =>
      'Daily totals and the weekly rhythm are shared. App, hourly and '
      'session detail stay with $name.';
  String sharingGuidedBody(String name) =>
      'App totals and shared notes are visible. Hourly and session detail '
      'stay with $name.';
  String agreedWithFamily(String level) => '$level · agreed with the family';
  String get addContextToToday => 'Add context to today';
  String get contextExplainsMore =>
      'A sentence now explains more than a chart later.';
  String get storyBehindToday => 'The story behind today';
  String get todaysContext => "Today's context";
  String get addContext => 'Add context';
  String get add => 'Add';
  String get numbersSayWhy =>
      'Numbers say what happened. A small note can say why — a game, '
      'a group chat, a quiet day.';
  String todayUpperDate(String date) => 'TODAY · $date';
  String get dailyTotalShared =>
      'Daily total shared. App and hourly detail stay private.';
  String get unlocks => 'Unlocks';
  String get topApp => 'Top app';
  String get peakWindow => 'Peak window';
  String get screenTimeLast7Days => 'Screen time, last 7 days';
  String get dailyAverage => 'Daily average';
  String get weekTotal => 'Week total';
  String get patternsWithoutNoise => 'Patterns without the noise';
  String aiTeaserBody(String name) =>
      "Compare today with yesterday, see the week's rhythm and "
      "find $name's longest stretches.";
  String get demoAnalysisOnDevice => 'Demo analysis · on-device';
  String get requestSentToParent =>
      'Request sent. Your parent will see it on their home screen.';
  String planNowActive(String name) => 'The plan is now active for $name.';
  String get replySavedHistory =>
      'Reply saved. The history stays visible to you both.';
  String get sharingLevelUpdated => 'Sharing level updated for the family.';

  // --- Apps -----------------------------------------------------------------

  String get appDetailPrivate => 'App detail is private';
  String appDetailPrivateBody(String name) =>
      '$name shares weekly trends only right now. App totals '
      'and drill-down stay on their device until you both agree '
      'to share more.';
  String get reviewSharingLevel => 'Review sharing level';
  String tracked(String minutes) => '$minutes tracked';
  String appsSorted(int count) => '$count apps, sorted by weekly time.';
  String get tapAppToSeeRhythm => 'Tap an app to see its daily rhythm';
  String appTotalsSharedDrillDown(String name) =>
      'App totals are shared; drill-down stays with $name';
  String get timeByCategory => 'Time by category';

  // --- App detail sheet -----------------------------------------------------

  String contextForApp(String app) => 'Context for $app';
  String sharedWithFamily(String name) => 'Shared with $name and the family.';
  String categoryDevice(String category, String device) =>
      '$category · $device';
  String get appContext => 'APP CONTEXT';
  String get addNote => 'Add note';
  String get noAppNote =>
      'No note on this app yet. A sentence about why it matters makes '
      'the minutes easier to read.';
  String get opensToday => 'Opens today';
  String get shareOfAppTime => 'Share of app time';
  String get simulatedUsage => 'Simulated usage for this demo';

  // --- Why changed / evidence ----------------------------------------------

  String get todayLevelWithYesterday => 'Today is level with yesterday.';
  String todayDiffThanYesterday(String diff) =>
      'Today is $diff than yesterday.';
  String get whyItChanged => 'Why it changed';
  String get biggestPieces => 'The biggest pieces, in order';
  String get noSingleAppMoved =>
      'No single app moved much. The day held its shape.';
  String get showTheMath => 'Show the math';
  String get contextOnlyNotAddedTwice => 'Context only · not added twice';
  String get everyAppLineIsDelta => 'Every app line is a signed delta.';
  String mathSummary(String today, String yesterday, String diff) =>
      '$today today − $yesterday yesterday = $diff.';
  String get appByApp => 'APP BY APP';
  String get noAppChangedMeasurably => 'No app changed by a measurable amount.';
  String get contextSignals => 'CONTEXT SIGNALS';
  String get contextSignalsBody =>
      'These explain the shape of the day. They are not added on top of '
      'the app rows.';
  String sourceSimulatedActivity(String device) =>
      'Source: $device · 14 days of simulated activity.';
  String vsLastWeek(String minutes) => 'vs $minutes last week';
  String get fourteenDayShape => '14-day shape';
  String get previous => 'Previous';
  String get whyBadge => 'WHY';
  String get bedtime => 'Bedtime';

  // --- Insights -------------------------------------------------------------

  String get whatWasThisStretch => 'What was this stretch?';
  String sessionSubtitle(String day, String minutes, String label) =>
      '$day · $minutes · $label';
  String get whatChanged => 'What changed';
  String get whatChangedSubtitle =>
      'Today against yesterday, and week against week.';
  String get whatAnalysisNoticed => 'What the analysis noticed';
  String get smallSignals => 'Small signals, stated plainly.';
  String get whenDeviceBusiest => 'When the device is busiest';
  String get todayHourByHour => 'Today, hour by hour.';
  String get continuousSessions =>
      'Continuous sessions this week, ranked by length.';
  String sessionCount(int count) => '$count sessions';
  String get ideasForFamily => 'Ideas for the family';
  String get ideasToTry => 'Ideas to try';
  String get gentleNotRigid => 'Gentle, not rigid.';
  String get aboutThisAnalysis => 'About this analysis';
  String get aboutAnalysisWithKey =>
      'Refresh sends the brief below to Gemini with your key. If the call '
      'fails or times out, the on-device analysis stays in place.';
  String get aboutAnalysisDemo =>
      'Insights are generated on-device from 14 days of simulated activity. '
      'Add a key in Settings, or pass --dart-define=GEMINI_API_KEY, to use '
      'Gemini.';
  String get manageAiKey => 'Manage AI key';
  String get connectGeminiOptional => 'Connect Gemini (optional)';
  String get connectGemini => 'Connect Gemini';
  String get aiCheckIn => 'AI CHECK-IN';
  String get dayOverDayWeekOverWeek => 'Day-over-day & week-over-week';
  String get geminiSendsOnRefresh => 'Gemini · sends only when you refresh';
  String get demoRunsOnDevice => 'Demo analysis · runs on this device';
  String get refresh => 'Refresh';
  String get refreshAnalysis => 'Refresh analysis';
  String updated(String time) => 'Updated $time';
  String get reading14Days => 'Reading 14 days of activity…';
  String get askAboutToday => 'ASK ABOUT TODAY';
  String get localAnswers => 'Local answers';
  String get onDevice => 'On-device';
  String get geminiBadge => 'GEMINI';

  // --- Patterns -------------------------------------------------------------

  String busiestWindow(int percent) => 'Busiest window · $percent% of today';
  String get todayBadge => 'TODAY';
  String get eveningUse => 'Evening use';
  String get sixToTen => '6–10 PM';
  String get after10Pm => 'After 10 PM';
  String get worthACheckIn => 'worth a check-in';
  String get settled => 'settled';
}
