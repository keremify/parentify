part of '../app_strings.dart';

mixin ServicesCopy {
  // ---------------------------------------------------------------------------
  // Services
  // ---------------------------------------------------------------------------

  String get aiKeyParentOnly => 'Only a parent can change the AI key.';
  String get apiKeyHasSpaces =>
      'That key contains spaces. Paste it as one continuous value.';
  String get apiKeyTooShort => 'That key looks too short for a Gemini API key.';
  String get apiKeyLooksInvalid =>
      'That does not look like a Gemini API key. Paste the value exactly as '
      'shown in Google AI Studio.';
  String get geminiTookTooLong => 'Gemini took too long to answer.';
  String get aiRequestFailed => 'The AI request failed unexpectedly.';
  String get geminiNoKey => 'No Gemini API key is configured.';
  String get geminiUnreachable =>
      'Could not reach Gemini. Check the connection and try again.';
  String get geminiNoSecureConnection =>
      'Could not establish a secure connection to Gemini.';
  String get geminiRequestIncomplete =>
      'The Gemini request could not be completed.';
  String geminiKeyRejected(String detail) =>
      'Gemini rejected the API key. Check GEMINI_API_KEY in .env.$detail';
  String geminiBusy(String detail) =>
      'Gemini is busy right now. Try again in a moment.$detail';
  String geminiRequestRejected(String detail) =>
      'Gemini rejected the request. Check GEMINI_MODEL and GEMINI_API_URL '
      'in .env.$detail';
  String geminiUnavailable(String detail) =>
      'Gemini is unavailable right now.$detail';
  String geminiUnexpectedStatus(int statusCode, String detail) =>
      'Gemini returned an unexpected response ($statusCode).$detail';
  String get geminiUnreadable =>
      'Gemini returned a response that could not be read.';
  String get geminiDeclined => 'Gemini declined to analyse this brief.';
  String get geminiNoAnalysis => 'Gemini returned no analysis.';
  String get geminiEmptyAnalysis => 'Gemini returned an empty analysis.';
  String get geminiUnexpectedShape =>
      'Gemini returned an analysis in an unexpected shape.';
  String get geminiIncompleteAnalysis =>
      'Gemini returned an incomplete analysis.';
  String get signInMissingConfig => 'Sign-in is not configured for this build.';
  String get signInWrongCredentials =>
      'That email or password does not match this demo.';
  String get childSignInNotAllowed =>
      'Child sign-in is not available for this profile.';
  String headlineSteadyWeek(String name) => 'A steady week for $name';
  String headlineAboveWeek(String name, int percent) =>
      "$name's week is $percent% above last week";
  String headlineBelowWeek(String name, int percent) =>
      "$name's week is $percent% below last week";
  String get observationTodayVsYesterday => 'Today vs yesterday';
  String get observationDayFlat =>
      'Screen time is level with yesterday. A steady day.';
  String observationDayDetail(
    String today,
    String difference,
    String yesterday,
  ) => '$today today, $difference than yesterday\'s $yesterday.';
  String get observationBusiestWindow => 'Busiest window';
  String observationPeak(String window, String category) =>
      '$window is the busiest stretch today. $category is usually the '
      'backdrop.';
  String get observationNoAppTitle => 'No app detail yet';
  String get observationNoAppDetail =>
      'There is not enough app activity to rank a weekly leader. '
      'The daily rhythm above is still available.';
  String observationWeeklyLeader(String app) => '$app is the weekly leader';
  String observationWeeklyLeaderDetail(
    String weekMinutes,
    int share,
    String average,
  ) =>
      '$weekMinutes this week — about $share% of app time. '
      'Daily average: $average.';
  String get observationLateTitle => 'Late-night use showed up';
  String observationLateDetail(String minutes) =>
      '$minutes landed after 10 PM in the last 24 hours, and one recent '
      'session ran past bedtime. Worth a gentle check-in.';
  String get observationEveningTitle => 'Evenings wind down well';
  String observationEveningDetail(String minutes) =>
      'Only $minutes after 10 PM today. The current evening rhythm is '
      'working.';
  String get observationFollowingUp => 'Following up from last week';
  String observationFollowUpDetail(String topic, String question) =>
      'You talked about $topic. $question The numbers below are a way back '
      'into that conversation, not a scorecard.';
  String get tagToday => 'Today';
  String get tagPattern => 'Pattern';
  String get tagApps => 'Apps';
  String get tagBedtime => 'Bedtime';
  String get tagRitual => 'Ritual';
  String summaryBase(
    String today,
    String dayPhrase,
    String name,
    String average,
    String weekDirection,
  ) =>
      'Today stands at $today — $dayPhrase. Over seven days $name averaged '
      '$average a day, $weekDirection the week before.';
  String get summaryRhythmSignal =>
      'The weekly rhythm is the clearest signal right now.';
  String summaryCategory(
    String base,
    String category,
    String app,
    String week,
  ) =>
      '$base $category makes up the biggest share, led by $app at $week '
      'this week.';
  String get weekAboutSame => 'about the same as';
  String get weekBelow => 'below';
  String get weekAbove => 'above';
  String get dayAboutSame => 'about the same as yesterday';
  String dayCompared(String percent) => '$percent compared with yesterday';
  String get starterDifferent => 'What felt different about today?';
  String starterLongerShorter(bool longer) =>
      'What made today ${longer ? 'longer' : 'shorter'}?';
  String get starterLastHour => 'How did the last hour before bed feel?';
  String get starterEvening => 'What helped the evening wind down?';
  String get starterSteady => "Is this week's rhythm feeling steady?";
  String get starterBalanced => 'What would make next week feel balanced?';
  String get suggestionWindDownTitle => 'Try a wind-down warning';
  String get suggestionWindDownDetail =>
      'Agree on a 10-minute heads-up before gaming ends. Transitions land '
      'better than sudden stops.';
  String get suggestionChargerTitle => 'Give the charger a bedtime';
  String suggestionChargerDetail(String name) =>
      'Keeping $name\'s phone in the kitchen after 9:30 PM gently trims '
      'late-night sessions.';
  String get suggestionPlayTogetherTitle => 'Play one round together';
  String get suggestionPlayTogetherDetail =>
      'Ask about a favorite game or map. Shared curiosity often opens more '
      'conversation than limits do.';
  String get suggestionTeamRuleTitle => 'Make bedtime a team rule';
  String suggestionTeamRuleDetail(String name) =>
      'A family charging spot for the last 30 minutes of the day benefits '
      'everyone, not just $name.';
  String get suggestionFeedTitle => 'Ask about the feed';
  String suggestionFeedDetail(String name) =>
      'A simple “what are you watching?” at dinner can surface what $name '
      'enjoys — and what feels heavy.';
  String get suggestionOfflineTitle => 'Plan one offline swap';
  String get suggestionOfflineDetail =>
      'Offer a small alternative for the 8 PM slot: a show together, a '
      'walk, or a game. Novelty beats restriction.';
  String get suggestionStreakTitle => 'Celebrate the streak';
  String suggestionStreakDetail(String name) =>
      'Notice the learning habit out loud. Positive attention keeps $name '
      'coming back to it.';
  String get suggestionQuietHourTitle => 'Protect the quiet hour';
  String get suggestionQuietHourDetail =>
      'The current after-school window is calm and focused. Try keeping it '
      'free of notifications.';
  String get suggestionMovementTitle => 'Balance with movement';
  String get suggestionMovementDetail =>
      'Pair a learning session with a short stretch or a walk. A little '
      'contrast keeps attention fresh.';
  String get suggestionDisplayTitle => 'Display the good stuff';
  String get suggestionDisplayDetail =>
      'Put one recent creation somewhere visible. Pride is a stronger '
      'motivator than screen-time rules.';
  String get suggestionCornerTitle => 'Keep a making corner';
  String suggestionCornerDetail(String name) =>
      'Paper, pencils and a charged tablet near the table invite $name to '
      'keep creating offline too.';
  String get suggestionShowTellTitle => 'Share a weekly show-and-tell';
  String get suggestionShowTellDetail =>
      'Five minutes at dinner to share what they made can turn a solo '
      'habit into a family ritual.';
  String get suggestionResponseTitle => 'Talk about response times';
  String suggestionResponseDetail(String name) =>
      'Agree that replies can wait. Fewer instant responses often means '
      'fewer pickups for $name.';
  String get suggestionGroupChatsTitle => 'Keep group chats visible';
  String get suggestionGroupChatsDetail =>
      'A shared family rule about which group chats are okay makes hard '
      'conversations feel less like policing.';
  String get suggestionNotificationsTitle => 'Wind down notifications';
  String get suggestionNotificationsDetail =>
      'Silencing non-essential chats after dinner can make evenings feel '
      'noticeably calmer.';
  String get suggestionNameMattersTitle => 'Name what matters';
  String suggestionNameMattersDetail(String name) =>
      'Ask $name which apps genuinely help their day. The answer often '
      'makes pruning easy.';
  String get suggestionHomeScreenTitle => 'Make the home screen intentional';
  String get suggestionHomeScreenDetail =>
      'Keep tools and learning up front; move the endless feeds one swipe '
      'away.';
  String get suggestionCheckInTitle => 'Check in, not up';
  String get suggestionCheckInDetail =>
      'A quick “how was your day?” beats a screen-time report. The numbers '
      'are a conversation starter, not a verdict.';
  String get suggestionSharedRuleTitle => 'Agree on one shared rule';
  String suggestionSharedRuleDetail(String name) =>
      'Choose one small device boundary the whole family follows. Shared '
      'rules feel fairer to $name than one-off limits.';
  String get driverMoreThanYesterday => 'more than yesterday';
  String get driverLessThanYesterday => 'less than yesterday';
  String driverEvidence(String today, String yesterday) =>
      'Today $today · yesterday $yesterday';
  String get driverLateNight => 'Late-night use';
  String get driverMoreAfter10 => 'more after 10 PM';
  String get driverLessAfter10 => 'less after 10 PM';
  String get driverUnlocks => 'Unlocks';
  String driverMoreOpens(int count) => '$count more opens than yesterday';
  String driverFewerOpens(int count) => '$count fewer opens than yesterday';
  String driverUnlockEvidence(String today, String yesterday) =>
      'Today $today · yesterday $yesterday';
  String get driverSameWeekday => 'Same weekday last week';
  String driverSameWeekdayDetail(String difference, String weekday) =>
      '$difference than $weekday last week';
  String driverLastWeekEvidence(String today, String lastWeek) =>
      'Today $today · last week $lastWeek';
  String driverAppShowedUp(String app) => '$app showed up';
  String get driverFirstMeaningfulTime => 'First meaningful time this week';
  String whyAnswerLevel(String today) =>
      'Today is level with yesterday at $today. No single app is driving a '
      'change, which is why the day looks steady.';
  String whyAnswerChanged(
    String delta,
    bool more,
    String label,
    String evidence,
    String extra,
  ) =>
      'Today is $delta ${more ? 'more' : 'less'} than yesterday. '
      'The biggest piece is $label: $evidence.$extra';
  String whyAnswerExtra(List<String> context) =>
      ' ${context.join(' and ')} also moved.';
  String get bedtimeNothingLate => 'Nothing landed after 10 PM today.';
  String bedtimeLandedLate(String minutes) =>
      '$minutes landed after 10 PM today.';
  String get bedtimeLevel => ' That is level with yesterday.';
  String bedtimeMore(String minutes) =>
      ' That is $minutes more than yesterday.';
  String bedtimeLess(String minutes) =>
      ' That is $minutes less than yesterday.';
  String bedtimeClosing(String name) =>
      ' The latest wind-down $name had this week is worth asking about, '
      'not fixing.';
  String get weekNoTopApp => 'No single app is leading the week.';
  String weekLedBy(String app, String minutes) => 'led by $app at $minutes.';
  String weekCategoryPhrase(String category) =>
      '$category is the largest share, ';
  String weekAnswer(
    String week,
    String difference,
    String percent,
    String categoryPhrase,
    String appPhrase,
  ) =>
      'This week is $week, $difference than last week ($percent). '
      '$categoryPhrase$appPhrase';
}
