---
description: Fix Flutter/Dart analyzer and build errors with minimal changes
agent: build-error-resolver
subagent: true
---

# Flutter Build Fix

Fix analyzer or build errors with minimal changes: $ARGUMENTS

## Steps

1. Run `flutter analyze` and collect every error.
2. If the failure is a dependency or generated-code problem, run:
   ```bash
   flutter pub get
   ```
   Regenerate code only when the project uses a generator (for example `dart run build_runner build --delete-conflicting-outputs`).
3. Fix errors one at a time with the smallest correct change.
4. Re-run `flutter analyze` after each fix.
5. Finish with `flutter test` to confirm nothing regressed.

## Rules

- Do not refactor, rename, or reorganize code.
- Do not add `// ignore:` comments unless there is no correct fix; explain why if you do.
- Do not change business logic or widget structure beyond what the error requires.
- Preserve existing behavior and public APIs.
- If a fix requires a dependency change, state it and ask before editing `pubspec.yaml`.

## Common Flutter fixes

| Error | Fix |
|---|---|
| `The argument type ... can't be assigned` | Correct the value or the parameter type |
| `Undefined name` / `Undefined class` | Fix the import or the symbol |
| `Non-nullable value must have a value` | Initialize it or make the type nullable |
| `BuildContext` used across async gap | Add a `mounted` check or capture dependencies before the `await` |
| `setState() called after dispose()` | Guard with `if (!mounted) return;` |
| Missing generated file | Run the project's code generator |

## Report

List each error, the fix applied, and the final `flutter analyze` / `flutter test` result.
