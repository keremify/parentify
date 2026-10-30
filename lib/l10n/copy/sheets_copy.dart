part of '../app_strings.dart';

mixin SheetsCopy {
  // ---------------------------------------------------------------------------
  // Sheets
  // ---------------------------------------------------------------------------

  String get aiKeyRemoved => 'AI key removed.';
  String get geminiKeySaved => 'Gemini key saved for this session.';
  String whatGeminiSeesForChild(String name) => 'What Gemini sees · $name';
  String get systemPromptLabel => 'SYSTEM PROMPT';
  String get familyBriefLabel => 'FAMILY BRIEF';
  String get resetDemoDataQuestion => 'Reset demo data?';
  String get resetDemoDataBody =>
      'Notes, requests, sharing levels and the saved API key will return to '
      'their starting state. You will be signed out.';
  String get keepData => 'Keep data';
  String get reset => 'Reset';
  String privacyLine(String name, String level, int notes) =>
      '$name: $level · $notes ${notes == 1 ? 'note' : 'notes'} shared';
  String get whatIsShared => 'What is shared';
  String privacyBody(String lines) =>
      'Activity is processed on this device. No account, backend or '
      'analytics receive it.\n\n$lines\n\n'
      'If you add a Gemini key and refresh an analysis, the brief shown in '
      '"What Gemini sees" is sent to Google\'s Gemini API. Without a key, '
      'nothing leaves this device.\n\n'
      'Notes, requests and agreements are visible to both sides of the '
      'family.';
  String get gotIt => 'Got it';
  String get aboutDemoBody =>
      'Parentify is a local concept demo for a calmer family screen-time '
      'app.\n\n'
      'Every profile, app and minute of activity is generated on this '
      'device. There is no account, no backend and no analytics. Built with '
      'Flutter for iOS and Android.\n\n'
      'The AI analyzer runs transparent on-device rules by default. Add a '
      'Gemini key in Settings or pass it at build time and refresh to send '
      'the previewed brief to Gemini; failures fall back to the local report.';
  String get childProfileSharedDemo => 'Child profile · shared demo';
  String parentAccount(String family) => 'Parent account · $family';
  String get childFallback => 'Child';
  String get aiAnalyzerSection => 'AI ANALYZER';
  String get manageGeminiApiKey => 'Manage Gemini API key';
  String get connectGeminiApiKey => 'Connect Gemini API key';
  String get geminiKeySavedTitle => 'Gemini key saved';
  String get connectYourGeminiKey => 'Connect your Gemini key';
  String get geminiCallsOnlyRefresh =>
      'Calls Gemini only when you refresh an analysis.';
  String get geminiKeyOptionalHint =>
      'Optional. Set it here or with --dart-define at build time.';
  String get whatGeminiSees => 'What Gemini sees';
  String get whatGeminiSeesSubtitle =>
      'Preview the system prompt plus activity, notes, agreement and '
      'check-in.';
  String get privacyReceipt => 'Privacy receipt';
  String get privacyReceiptSubtitle =>
      'A plain-language ledger of what each child shares.';
  String get preferencesSection => 'PREFERENCES';
  String get weeklyCheckInReminder => 'Weekly check-in reminder';
  String get weeklyCheckInReminderSubtitle =>
      'A gentle Sunday nudge for the family ritual.';
  String get includeMyScreenTime => 'Include my screen time';
  String get includeMyScreenTimeSubtitle =>
      'Family balance, not child-only surveillance (demo toggle).';
  String get childModeSafety =>
      'This is a parent-managed demo profile. Activity is simulated and '
      'lives only on this device.';
  String get parentModeSafety =>
      'Local demo: every profile and activity is simulated. Data leaves '
      'this device only when you refresh with a Gemini key.';
  String get aboutThisDemo => 'About this demo';
  String get resetDemoData => 'Reset demo data';
  String get resetDemoDataSubtitle =>
      'Return notes, requests and sharing to the starting state.';
  String get exportFamilyData => 'Export family data';
  String get exportFamilyDataSubtitle =>
      'Copy a JSON export of agreements, notes, and check-ins.';
  String get exportDialogTitle => 'Export family data';
  String get exportDialogBody =>
      'This JSON document includes your family agreements, qualitative '
      'context notes, check-in history, and app usage records.';
  String get copyJson => 'Copy JSON';
  String get copiedToClipboard => 'Copied family data to clipboard';
  String get addDemoSibling => 'Add demo sibling (Ada, 14)';
  String get addDemoSiblingSubtitle =>
      'Adds a second child to SQLite to test multi-child family views.';
  String get addedSibling => 'Added Ada (14) to your family';
  String get exitChildView => 'Exit child view';
  String get signOut => 'Sign out';
  String get geminiApiKey => 'Gemini API key';
  String get apiKeySessionBody =>
      'The key is kept in memory for this session and used only when you '
      'refresh an analysis. Leave it empty to keep the on-device report.';
  String get apiKeyLabel => 'API key';
  String get showApiKey => 'Show API key';
  String get hideApiKey => 'Hide API key';
  String get apiKeyEnvHint =>
      'To keep the key between launches, pass '
      '--dart-define=GEMINI_API_KEY at build time.';
  String get removeKey => 'Remove key';
  String get saveKey => 'Save key';

  // --- Agreement ------------------------------------------------------------

  String get saturday => 'Saturday';
  String get sunday => 'Sunday';
  String get dayPhraseToday => 'today';
  String get dayPhraseTomorrow => 'tomorrow';
  String dayPhraseOn(String day) => 'on $day';
  String moreMinutesTitle(int minutes, String dayPhrase) =>
      '$minutes more minutes $dayPhrase';
  String get askForMoreTime => 'Ask for more time';
  String get askForMoreTimeSubtitle =>
      'A request is a conversation starter, not a demand. '
      'Your parent can reply with a note.';
  String get fieldWhen => 'WHEN';
  String get fieldHowMuchMore => 'HOW MUCH MORE';
  String minutesCount(int minutes) => '$minutes minutes';
  String get fieldWhy => 'WHY';
  String get reasonHint =>
      'A tournament with classmates, finishing a project, a group call…';
  String get shareAsContext => 'Share this as context for today';
  String get shareAsContextSubtitle =>
      "Your parent sees the reason next to today's numbers.";
  String get sendRequest => 'Send request';
  String get requestSeenOnHome =>
      'Your parent will see this request on their home screen.';
  String childAsked(String name) => '$name asked';
  String agreementSummary(String title, String detail) => '$title · $detail';
  String get replyOptionalLabel => 'A SHORT REPLY (OPTIONAL)';
  String get replyHint => "Let's try Saturday morning instead…";
  String get notThisTime => 'Not this time';
  String get approve => 'Approve';
  String get eitherAnswerOpen =>
      'Either answer keeps the conversation open. A reply is optional.';
  String sharingWith(String name) => 'Sharing with $name';
  String get familyPolicy => 'A family policy, visible to you both.';
  String visibilityOptionSemantics(String label, String description) =>
      '$label. $description';
  String get childAlwaysSees =>
      'The child always sees their own full picture and can see which level '
      'is active. No data is deleted when you change this.';
  String get saveSharingLevel => 'Save sharing level';

  // --- Weekly check-in ------------------------------------------------------

  String checkInSaved(String topic) =>
      'Check-in saved. Next week will follow up on $topic.';
  String get screenTimeFallback => 'screen time';
  String steadyWeek(String name) => 'A steady week for $name';
  String biggestChange(String driver) => '$driver is the biggest change';
  String get rhythmHeld => 'No single app moved much. The rhythm held.';
  String driverToday(String detail) =>
      '$detail today. Worth naming before asking why.';
  String get weekRhythmTopic => "the week's rhythm";
  String get weekRhythmQuestion => 'What stood out to you about this week?';
  String get noticedBadge => 'NOTICED';
  String get askBadge => 'ASK';
  String get tryBadge => 'TRY';
  String topAppWorthQuestion(String app) =>
      'What made $app feel worth the time?';
  String questionOpensMore(String name) =>
      'A question opens more than a report. Let $name describe the good part.';
  String lastWeekTalked(String topic) =>
      'Last week you talked about $topic. Keep the thread going with a '
      'curious question.';
  String topAppWorthQuestionThisWeek(String app) =>
      'What made $app feel worth the time this week?';
  String get windDownTopic => 'wind-down';
  String get windDownQuestion =>
      'What would make the last 30 minutes of the day feel calmer?';
  String get weeklyCheckInTitle => 'Weekly check-in';
  String checkInSubtitle(String name) =>
      'Ten minutes with $name. No scoreboard, just one conversation.';
  String streakWeeks(int weeks) =>
      '$weeks ${weeks == 1 ? 'week' : 'weeks'} in a row';
  String get checkInDone =>
      "This week's check-in is done. You can update the focus below.";
  String get pickOneFocus => 'PICK ONE FOCUS';
  String savedFocus(String topic) =>
      "Saved for this week. Next week's report will start with $topic.";
  String get savingFocusReminder =>
      "Saving remembers this focus for next week's report. Nothing leaves "
      'this device.';
  String get talkedAboutThis => 'We talked about this';

  // --- Context note ---------------------------------------------------------

  String get addContextToThisApp => 'Add context to this app';
  String get noteSubtitleFallback =>
      'A few words now make the numbers easier to read later.';
  String get whatWasIt => 'WHAT WAS IT?';
  String get noteHint =>
      'Group chat after practice, a tournament, a read-along…';
  String get notesStayOnDevice =>
      'Notes stay on this device and are shared with the family.';
  String get saveNote => 'Save note';
}
