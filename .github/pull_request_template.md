## Description
Provide a concise explanation of what this pull request changes and why.

## Changes Made
- 

## Verification & Quality Gates
Before submitting, please ensure you have completed the following:
- [ ] `dart format --output=none --set-exit-if-changed .` passes with 0 changes
- [ ] `flutter analyze --fatal-infos` passes with 0 issues
- [ ] `flutter test test/sqlite_backend_test.dart test/models_and_repositories_test.dart test/accessibility_test.dart` passes (all tests green)
- [ ] Architecture layering is maintained (no direct database calls in widgets; mutations route through repositories/services)
- [ ] No hardcoded secrets or API keys included
