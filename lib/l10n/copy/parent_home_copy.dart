part of '../app_strings.dart';

mixin ParentHomeCopy {
  // ---------------------------------------------------------------------------
  // Parent home
  // ---------------------------------------------------------------------------

  String get waitingForYou => 'Waiting for you';
  String get waitingForYouSubtitle => 'A small request from one of the kids.';
  String requestCount(int count) =>
      '$count ${count == 1 ? 'request' : 'requests'}';
  String get chooseChild => 'Choose a child';
  String get chooseChildSubtitle => 'Tap a profile for the full picture.';
  String profileCount(int count) => '$count profiles';
  String get worthALook => 'Worth a look';
  String get worthALookSubtitle => 'One gentle flag from today.';
  String get localDemoNoDataLeaves => 'Local demo · no data leaves this device';
  String get alerts => 'Alerts';
  String get settings => 'Settings';
  String get alertsSubtitle => 'A few gentle nudges from the last sync.';
  String get alertsDone => 'That is everything for now.';
  String get homeGreetingSubtitle =>
      "Here is how the family's digital day is shaping up.";
  String get familyTodayLabel => 'TODAY, FAMILY-WIDE';
  String deviceCount(int count) =>
      '$count ${count == 1 ? 'device' : 'devices'}';
  String versusYesterday(String minutes) => 'vs $minutes yesterday';
  String get last7Days => 'LAST 7 DAYS';
  String agreementActivated(String name) =>
      'Agreement active. $name can see the update.';
  String get requestReplied =>
      'Reply sent. The request stays in the family history.';
  String attentionAbove(String name, String percent) =>
      '$name is $percent vs yesterday';
  String attentionQuieter(String name) => 'A quieter day for $name';
  String attentionSteady(String name) => '$name is steady today';
  String attentionDriver(String label, String detail) => '$label: $detail.';
  String get attentionAppUsageLeading =>
      'App usage is leading the day. See where the extra minutes went.';
  String attentionAppLeading(String app) =>
      '$app is leading the day. See where the extra minutes went.';
  String attentionDown(String percent) =>
      'Down $percent from yesterday. A nice rhythm to notice.';
  String get attentionSame =>
      'About the same as yesterday. No spikes worth flagging.';
  String get weekSoFar => 'The week so far';
  String get dailyAveragePerChild => 'Daily average per child';
  String get familyAveragePerDay => 'Family average / day';
  String get weeklyCheckIn => 'Weekly check-in';
  String get weeklyCheckInSubtitle => 'A conversation, not a report card.';
  String checkInStreak(int weeks) => '$weeks WEEK${weeks == 1 ? '' : 'S'}';
  String get checkInEmpty =>
      'Pick one thing to notice, one question to ask and one small '
      'thing to try together.';
  String checkInLast(String topic, String question) =>
      'Last time you talked about $topic. $question';
  String get startCheckIn => "Start this week's check-in";
  String get openCheckIn => 'Open check-in';
  String get familyBalance => 'Family balance';
  String get familyBalanceSubtitle =>
      "Everyone's time counts, including yours.";
  String get kidsToday => 'Kids today';
  String get youToday => 'You today';
  String get allTogether => 'All together';
  String familyWeekLogged(String total) =>
      'This week the family has logged $total. '
      'A shared number reads differently from a child-only one.';
  String get familyBalanceOff =>
      'Optional: add your own screen time so the family picture is not '
      'one-sided. It stays on this device and is never shared with the kids '
      'as a score.';
  String alertAbove(String name, String percent) =>
      '$name is $percent above yesterday';
  String alertWindingDown(String name) => '$name is winding down';
  String alertEvenKeel(String name) => '$name is on an even keel';
  String alertDetailAbove(String minutes, String app) =>
      '$minutes today, mostly in $app.';
  String alertDetailQuieter(String minutes, String less) =>
      '$minutes today — $less less than yesterday.';
  String alertDetailSteady(String minutes) =>
      '$minutes today. A steady rhythm.';
  String get theirApps => 'their apps';
}
