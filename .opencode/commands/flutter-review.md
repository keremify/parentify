---
description: Review Flutter/Dart changes using the ECC Flutter review checklist
agent: code-reviewer
subagent: true
---

# Flutter Review

Load and follow the `flutter-dart-code-review` skill.

Review: $ARGUMENTS

If no target is given, review the current uncommitted diff (`git diff` and `git diff --cached`).

## Focus

- widget composition and `const` usage
- state management correctness and lifecycle safety
- `BuildContext` use across async gaps
- null safety and error handling
- navigation and auth guards
- performance (unnecessary rebuilds, list virtualization)
- accessibility semantics
- secrets and unsafe storage

## Output

Report findings by severity (critical, high, medium, low) with file and line references. Do not modify code unless explicitly asked.
