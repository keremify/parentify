import '../config/env.dart';

/// Sandbox credentials for the demo authentication service.
///
/// The defaults live in code so widget tests can construct [AppState] without a
/// binding. At runtime [instance] reads `assets/env.defaults`, so changing
/// `DEMO_PARENT_PASSWORD` or `DEMO_CHILD_PIN` there is enough to change the
/// demo login after a restart. `--dart-define` values still win.
///
/// These are deliberately not real secrets: the demo runs entirely on-device
/// against generated data. They exist so the demo can exercise a credential
/// check instead of trusting a role toggle.
class DemoCredentials {
  const DemoCredentials({
    required this.parentEmail,
    required this.parentPassword,
    required this.childPin,
  });

  static DemoCredentials get instance => DemoCredentials(
    parentEmail: AppEnv.demoParentEmail,
    parentPassword: AppEnv.demoParentPassword,
    childPin: AppEnv.demoChildPin,
  );

  final String parentEmail;
  final String parentPassword;
  final String childPin;
}
