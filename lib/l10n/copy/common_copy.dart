part of '../app_strings.dart';

mixin CommonCopy {
  // ---------------------------------------------------------------------------
  // Common
  // ---------------------------------------------------------------------------

  String get appName => 'Parentify';
  String get close => 'Close';
  String get cancel => 'Cancel';
  String get done => 'Done';
  String get somethingWentWrong => 'Something went wrong';
  String get appErrorBody =>
      'Parentify hit an unexpected problem while drawing this screen. '
      'Nothing was uploaded: all demo data stays on this device. '
      'Restart the app to return to the family view.';
  String get today => 'Today';
  String get yesterday => 'Yesterday';
  String get tomorrow => 'Tomorrow';
  String get demo => 'DEMO';
  String get active => 'ACTIVE';
  String ageDevice(int age, String device) => '$age · $device';

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  String get localDemo => 'LOCAL DEMO';
  String get loginTagline => 'A CALMER WAY TO STAY CLOSE';
  String get loginHeadlineStart => 'Their digital world,\n';
  String get loginHeadlineAccent => 'kindly';
  String get loginHeadlineEnd => ' understood.';
  String get loginSubtitle =>
      'See how your kids spend time on their devices — '
      'with context, not hovering.';
  String get signingIn => 'Signing in…';
  String get enterFamilySpace => 'Enter the family space';
  String get openMyActivity => 'Open my activity';
  String get parentDemoHint =>
      'Demo build — use the demo password from the README, or jump straight in.';
  String get childDemoHint =>
      'Demo build — enter the demo PIN, or jump straight in.';
  String get useDemoAccount => 'Use demo account';
  String get useDemoPin => 'Use demo PIN';
  String get featureScreenTime => 'Screen time';
  String get featureAppInsights => 'App insights';
  String get featureAiCheckIns => 'AI check-ins';
  String get loginFooter => 'For iOS & Android · Parentify demo v1.0';
  String get parentEmailLabel => 'Parent email';
  String get passwordLabel => 'Password';
  String get showPassword => 'Show password';
  String get hidePassword => 'Hide password';
  String get whoIsCheckingIn => 'WHO IS CHECKING IN?';
  String get noChildProfiles => 'No child profiles are available in this demo.';
  String get pinLabel => '4-digit PIN';
  String get parentRole => 'Parent';
  String get childRole => 'Child';
  String roleLabel(UserRole role) =>
      role == UserRole.parent ? parentRole : childRole;
  String get signInAsParent => 'Sign in as parent';
  String get signInAsChild => 'Sign in as child';
  String signInAsChildName(String name) => 'Sign in as $name';
  String get missingChildProfile => 'No child profile is available to open.';
  String get enterParentCredentials => 'Enter the parent email and password.';
  String get signInFailed => 'Sign-in failed. Please try again.';
  String get pinMismatch => 'That PIN does not match this child profile.';
  String get signInNotConfigured => 'Sign-in is not configured for this build.';
  String get signInWrongDemoParent =>
      'That email and password do not match the demo parent account.';
  String get signInWrongChildPin =>
      'That PIN does not match this child profile.';
  String get childProfileUnavailable =>
      'That child profile is no longer available.';
}
