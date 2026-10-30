---
description: Verify the Parentify Flutter app (format, analyze, test, build)
agent: build
---

# Verify Parentify

Run the verification loop for: $ARGUMENTS

## Steps

1. **Format check**
   ```bash
   dart format --output=none --set-exit-if-changed lib test
   ```
   If files are unformatted, report them; only run `dart format lib test` when the user asked for fixes.

2. **Static analysis**
   ```bash
   flutter analyze
   ```

3. **Tests**
   ```bash
   flutter test
   ```

4. **Coverage** (run when coverage was requested)
   ```bash
   flutter test --coverage
   ```
   Summarize `coverage/lcov.info` (overall line coverage and the weakest files).

5. **Build**
   ```bash
   flutter build apk --debug
   ```
   Skip this step if the user asked for a fast check, and say so in the report.

6. **Diff review**
   Run `git diff --stat` and inspect the changed Dart files for debug prints, hardcoded secrets, and accidental edits.

## Report

### Summary
- Status: PASS / FAIL
- Score: X/Y checks passed

### Details
| Check | Status | Notes |
|-------|--------|-------|
| Format | PASS/FAIL/SKIP | |
| Analyze | PASS/FAIL | |
| Tests | PASS/FAIL | N passed / N failed |
| Coverage | PASS/FAIL/SKIP | XX% |
| Build | PASS/FAIL/SKIP | |

### Action Items
List exact files and fixes required when anything fails.

Do not claim a check passed unless the command actually ran and succeeded.
